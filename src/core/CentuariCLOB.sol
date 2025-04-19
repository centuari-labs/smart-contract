// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Id, MarketConfig, Order, Side} from "../types/CommonTypes.sol";
import {MarketConfigLib} from "../libraries/MarketConfigLib.sol";
import {CentuariDSLib} from "../libraries/Centuari/CentuariDSLib.sol";
import {CentuariErrorsLib} from "../libraries/Centuari/CentuariErrorsLib.sol";
import {DataStore} from "./DataStore.sol";
import {ICentuari} from "../interfaces/ICentuari.sol";

contract CentuariCLOB is Ownable, ReentrancyGuard {
    using MarketConfigLib for MarketConfig;

    mapping(Id => address) public dataStores;
    mapping(address => Order[]) public traderOrders;
    address public centuari;
    address public centuariAlpha;


    modifier onlyActiveMarket(Id id) {
        DataStore dataStore = DataStore(dataStores[id]);

        if (!dataStore.getBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL)) {
            revert CentuariErrorsLib.MarketNotActive();
        }

        if (block.timestamp >= dataStore.getUint(CentuariDSLib.MATURITY_UINT256)) {
            dataStore.setBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL, false);
            revert CentuariErrorsLib.MarketExpired();
        }
        _;
    }

    constructor(address owner_, address centuari_, address centuariAlpha_) Ownable(owner_) {
        centuari = centuari_;
        centuariAlpha = centuariAlpha_;
    }

    function setCentuari(address centuari_) external onlyOwner {
        centuari = centuari_;
    }

    function setCentuariAlpha(address centuariAlpha_) external onlyOwner {
        centuariAlpha = centuariAlpha_;
    }

    function createDataStore(MarketConfig calldata config) external onlyOwner returns (address) {
        if (
            config.loanToken == address(0) || config.collateralToken == address(0) || config.maturity <= block.timestamp
        ) revert CentuariErrorsLib.InvalidMarketConfig();

        Id marketConfigId = config.id();
        DataStore dataStore = new DataStore(owner(), address(this));
        dataStores[marketConfigId] = address(dataStore);

        // Set data store data
        dataStore.setAddress(CentuariDSLib.LOAN_TOKEN_ADDRESS, config.loanToken);
        dataStore.setAddress(CentuariDSLib.COLLATERAL_TOKEN_ADDRESS, config.collateralToken);
        dataStore.setUint(CentuariDSLib.MATURITY_UINT256, config.maturity);
        dataStore.setBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL, true);

        // Create Centuari
        ICentuari(centuari).createDataStore(config);

        return address(dataStore);
    }

    function setDataStore(MarketConfig calldata config, address dataStore) external onlyOwner {
        if (
            config.loanToken == address(0) || config.collateralToken == address(0) || config.maturity <= block.timestamp
        ) revert CentuariErrorsLib.InvalidMarketConfig();

        dataStores[config.id()] = address(dataStore);
    }

    function placeOrder(MarketConfig calldata config, uint256 amount, uint256 collateralAmount, uint256 rate, Side side)
        external
        onlyActiveMarket(config.id())
        nonReentrant
    {
        // ---------------------------
        // 1. Transfer tokens to escrow
        // ---------------------------
        // Remember owner is router!
        if (side == Side.LEND) {
            // LEND => deposit debtToken
            debtBalances[trader] += amount;
            debtToken.transferFrom(owner(), address(this), amount);
            emit Deposit(trader, amount, Side.LEND);
        } else {
            // BORROW => deposit collateralToken
            collateralBalances[trader] += collateralAmount;
            collateralToken.transferFrom(
                owner(),
                address(this),
                collateralAmount
            );
            emit Deposit(trader, collateralAmount, Side.BORROW);
        }

        // ---------------------------
        // 2. Build the new order
        // ---------------------------
        uint256 orderId = orderCount;
        orderCount++;

        Order memory newOrder = Order({
            id: orderId,
            trader: trader,
            amount: amount,
            collateralAmount: collateralAmount,
            rate: rate,
            side: side,
            status: Status.OPEN
        });

        emit OrderPlaced(
            orderId,
            trader,
            amount,
            collateralAmount,
            rate,
            side,
            Status.OPEN
        );

        // Arrays to store matched results, 50 is arbitrary max
        MatchedInfo[] memory tempLendMatches = new MatchedInfo[](50);
        MatchedInfo[] memory tempBorrowMatches = new MatchedInfo[](50);
        uint256 lendMatchCount = 0;
        uint256 borrowMatchCount = 0;

        // Opposite side
        Side oppositeSide = (side == Side.LEND) ? Side.BORROW : Side.LEND;
        Order[] storage oppQueue = orderQueue[rate][oppositeSide];

        // Keep track of total matched for the newOrder
        uint256 totalMatchedForNewOrder;
        uint256 originalNewAmount = newOrder.amount;
        uint256 originalNewCollateralAmount = newOrder.collateralAmount;

        // ---------------------------
        // 3. Match loop
        // ---------------------------
        uint256 i = 0;
        while (i < oppQueue.length && newOrder.amount > 0) {
            Order storage matchOrder = oppQueue[i];

            // Skip if FILLED, CANCELLED, or same trader
            if (
                matchOrder.status == Status.FILLED ||
                matchOrder.status == Status.CANCELLED ||
                matchOrder.trader == trader
            ) {
                i++;
                continue;
            }

            uint256 originalMatchAmount = matchOrder.amount;
            uint256 matchedAmount = 0;

            if (matchOrder.amount <= newOrder.amount) {
                // matchOrder fully filled
                matchedAmount = matchOrder.amount;
                newOrder.amount -= matchedAmount;
                matchOrder.amount = 0;
                matchOrder.status = Status.FILLED;

                // Calculate and update collateral amounts for new order
                if (newOrder.side == Side.BORROW) {
                    newOrder.collateralAmount -= (matchOrder.collateralAmount * matchedAmount) / originalMatchAmount;
                }

                if (newOrder.amount == 0) {
                    newOrder.status = Status.FILLED;
                } else {
                    newOrder.status = Status.PARTIALLY_FILLED;
                }

                emit OrderMatched(
                    newOrder.id,
                    matchOrder.id,
                    newOrder.status,
                    Status.FILLED
                );

                // Record how many tokens the newOrder matched
                totalMatchedForNewOrder += matchedAmount;

                // store matchOrder details
                _storeMatchInfo(
                    matchOrder,
                    matchedAmount,
                    originalMatchAmount,
                    tempLendMatches,
                    tempBorrowMatches,
                    lendMatchCount,
                    borrowMatchCount
                );
                if (matchOrder.side == Side.LEND) {
                    lendMatchCount++;
                } else {
                    borrowMatchCount++;
                }

                // Remove matchOrder from queue (swap + pop)
                _removeFromQueueByIndex(oppQueue, i, rate, matchOrder.side);
            } else {
                // newOrder is fully filled, matchOrder partial
                matchedAmount = newOrder.amount;
                matchOrder.amount -= matchedAmount;
                matchOrder.status = Status.PARTIALLY_FILLED;
                newOrder.amount = 0;
                newOrder.status = Status.FILLED;

                // Calculate and update collateral amounts for new order
                if (newOrder.side == Side.BORROW) {
                    newOrder.collateralAmount = 0;
                }

                emit OrderMatched(
                    newOrder.id,
                    matchOrder.id,
                    Status.FILLED,
                    Status.PARTIALLY_FILLED
                );

                totalMatchedForNewOrder += matchedAmount;

                // matchOrder
                _storeMatchInfo(
                    matchOrder,
                    matchedAmount,
                    originalMatchAmount,
                    tempLendMatches,
                    tempBorrowMatches,
                    lendMatchCount,
                    borrowMatchCount
                );
                if (matchOrder.side == Side.LEND) {
                    lendMatchCount++;
                } else {
                    borrowMatchCount++;
                }

                // newOrder is exhausted => break
                i++;
                break;
            }

            i++;
        }

        // ----------------------------------
        // 4. If newOrder is STILL OPEN
        // ----------------------------------
        if (newOrder.status == Status.OPEN) {
            // No fill happened; push entire order
            orderQueue[newOrder.rate][newOrder.side].push(newOrder);
            traderOrders[newOrder.trader].push(newOrder);
        } else {
            // (FILLED or PARTIALLY_FILLED)
            if (newOrder.status == Status.PARTIALLY_FILLED) {
                orderQueue[newOrder.rate][newOrder.side].push(newOrder);
            }
            traderOrders[newOrder.trader].push(newOrder);
        }

        // ----------------------------------
        // 5. *Now* store newOrder's matched info if it partially or fully filled
        //    (Because newOrder is only one, we do this exactly once).
        // ----------------------------------
        if (totalMatchedForNewOrder > 0) {
            // We'll store newOrder's final leftover
            // partial fill leftover = newOrder.amount
            // final status is newOrder.status
            // matched fraction = totalMatchedForNewOrder / originalNewAmount

            // Calculate matched collateral amount proportionally
            uint256 matchedCollateralAmount = 0;
            if (newOrder.side == Side.BORROW) {
                matchedCollateralAmount = (originalNewCollateralAmount * totalMatchedForNewOrder) / originalNewAmount;
            }

            MatchedInfo memory newOrderInfo = MatchedInfo({
                orderId: newOrder.id,
                trader: newOrder.trader,
                matchAmount: totalMatchedForNewOrder,
                matchCollateralAmount: matchedCollateralAmount,
                side: newOrder.side,
                status: newOrder.status
            });

            // If newOrder is LEND, add to lend array; else to borrow array
            if (newOrder.side == Side.LEND) {
                tempLendMatches[lendMatchCount] = newOrderInfo;
                lendMatchCount++;
            } else {
                tempBorrowMatches[borrowMatchCount] = newOrderInfo;
                borrowMatchCount++;
            }
        }

        // ----------------------------------
        // 6. Build final matched arrays
        // ----------------------------------
        matchedLendOrders = new MatchedInfo[](lendMatchCount);
        matchedBorrowOrders = new MatchedInfo[](borrowMatchCount);

        uint256 lendIdx = 0;
        uint256 borrowIdx = 0;

        // copy lend matches
        for (uint256 j = 0; j < 50; j++) {
            MatchedInfo memory infoL = tempLendMatches[j];
            if (infoL.trader != address(0)) {
                matchedLendOrders[lendIdx] = infoL;
                lendIdx++;
                if (lendIdx == lendMatchCount) break;
            }
        }

        // copy borrow matches
        for (uint256 k = 0; k < 50; k++) {
            MatchedInfo memory infoB = tempBorrowMatches[k];
            if (infoB.trader != address(0)) {
                matchedBorrowOrders[borrowIdx] = infoB;
                borrowIdx++;
                if (borrowIdx == borrowMatchCount) break;
            }
        }

        // After matching logic, update best rate if this is a lend order
        if (side == Side.LEND && newOrder.status == Status.OPEN) {
            if (rate < bestLendRate) {
                bestLendRate = rate;
                emit BestRateUpdated(rate, Side.LEND);
            }
        }

        // Return both arrays
        return (matchedLendOrders, matchedBorrowOrders);
    }

    function cancelOrder(MarketConfig calldata config, uint256 orderId) external {
        //TODO: Add logic
    }

    function _removeFromQueueByIndex(Order[] storage queue, uint256 index, uint256 rate, Side side) internal {
        //TODO: Add logic
    }

    /// @notice Finds the index of an order in the queue
    /// @dev Helper function for order cancellation
    /// @param orders Array of orders to search
    /// @param orderId ID of the order to find
    /// @return Index of the order, or max uint256 if not found
    function _findOrderIndex(Order[] storage orders, uint256 orderId) internal view returns (uint256) {
        //TODO: Add logic
    }
}