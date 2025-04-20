// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Id, MarketConfig, Order, MatchedOrder, Side, Status} from "../types/CommonTypes.sol";
import {MarketConfigLib} from "../libraries/MarketConfigLib.sol";
import {OrderQueueLib} from "../libraries/centuari-clob/OrderQueueLib.sol";
import {CentuariDSLib} from "../libraries/Centuari/CentuariDSLib.sol";
import {CentuariCLOBDSLib} from "../libraries/centuari-clob/CentuariCLOBDSLib.sol";
import {CentuariErrorsLib} from "../libraries/Centuari/CentuariErrorsLib.sol";
import {CentuariCLOBErrorsLib} from "../libraries/centuari-clob/CentuariCLOBErrorsLib.sol";
import {CentuariEventsLib} from "../libraries/Centuari/CentuariEventsLib.sol";
import {CentuariCLOBEventsLib} from "../libraries/centuari-clob/CentuariCLOBEventsLib.sol";
import {DataStore} from "./DataStore.sol";
import {ICentuari} from "../interfaces/ICentuari.sol";
import {ICentuariCLOB} from "../interfaces/ICentuariCLOB.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CentuariCLOB is ICentuariCLOB, Ownable, ReentrancyGuard {
    using MarketConfigLib for MarketConfig;

    mapping(Id => address) public dataStores;
    mapping(address => Order[]) public traderOrders;
    ICentuari public CENTUARI;
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

    constructor(address owner_, address centuari_) Ownable(owner_) {
        CENTUARI = ICentuari(centuari_);
    }

    function setCentuari(address centuari_) external onlyOwner {
        CENTUARI = ICentuari(centuari_);
    }

    function setCentuariAlpha(address centuariAlpha_) external onlyOwner {
        centuariAlpha = centuariAlpha_;
    }

    function createDataStore(MarketConfig memory config) external onlyOwner {
        // Validate market config
        if (
            config.loanToken == address(0) || config.collateralToken == address(0)
        ) revert CentuariErrorsLib.InvalidMarketConfig();

        Id marketConfigId = config.id();
        DataStore dataStore = new DataStore(owner(), address(this));
        dataStores[marketConfigId] = address(dataStore);

        // Set data store data
        dataStore.setAddress(CentuariDSLib.LOAN_TOKEN_ADDRESS, config.loanToken);
        dataStore.setAddress(CentuariDSLib.COLLATERAL_TOKEN_ADDRESS, config.collateralToken);
        dataStore.setUint(CentuariDSLib.MATURITY_UINT256, config.maturity);
        dataStore.setBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL, true);

        CENTUARI.createDataStore(config);

        emit CentuariEventsLib.CreateDataStore(
            address(dataStore), config.loanToken, config.collateralToken, config.maturity
        );
    }

    function setDataStore(MarketConfig memory config, address dataStore) external onlyOwner {
        //Validate market config
        if (
            config.loanToken == address(0) || config.collateralToken == address(0)
        ) revert CentuariErrorsLib.InvalidMarketConfig();

        dataStores[config.id()] = dataStore;

        emit CentuariEventsLib.SetDataStore(dataStore, config.loanToken, config.collateralToken, config.maturity);
    }

    function placeOrder(MarketConfig calldata config, uint256 rate, Side side, uint256 amount, uint256 collateralAmount)
        external
        onlyActiveMarket(config.id())
        nonReentrant
    {
        if (amount == 0) {
            revert CentuariCLOBErrorsLib.InvalidAmount();
        }

        if (side == Side.BORROW && collateralAmount == 0) {
            revert CentuariCLOBErrorsLib.InvalidCollateralAmount();
        }

        DataStore dataStore = DataStore(dataStores[config.id()]);
        // ---------------------------
        // 1. Transfer tokens to Centuari
        // ---------------------------
        if (side == Side.LEND) {
            // LEND => deposit debtToken
            IERC20(config.loanToken).transferFrom(msg.sender, address(CENTUARI), amount);
        } else if (side == Side.BORROW) {
            // BORROW => deposit collateralToken
            IERC20(config.collateralToken).transferFrom(msg.sender, address(CENTUARI), collateralAmount);
        }

        // ---------------------------
        // 2. Build the new order
        // ---------------------------
        uint256 orderId = CentuariCLOBDSLib.getNextOrderId(dataStore);

        Order memory newOrder = Order({
            id: orderId,
            trader: msg.sender,
            amount: amount,
            collateralAmount: collateralAmount,
            rate: rate,
            side: side,
            status: Status.OPEN
        });

        emit CentuariCLOBEventsLib.OrderPlaced(
            config.id(), orderId, msg.sender, amount, collateralAmount, rate, side, Status.OPEN
        );

        // ---------------------------
        // 3. Match loop
        // ---------------------------
        Side oppositeSide = (side == Side.LEND) ? Side.BORROW : Side.LEND;
        uint256 oppositeOrderId = dataStore.getUint(OrderQueueLib.getLinkedHeadKey(rate, oppositeSide));

        while (oppositeOrderId != 0 && newOrder.status != Status.FILLED) {
            uint256 nextoppositeOrderId = dataStore.getUint(OrderQueueLib.getLinkedNextKey(oppositeOrderId));
            address oppositeOrderTrader = dataStore.getAddress(CentuariCLOBDSLib.getOrderTraderKey(oppositeOrderId));

            // Skip if FILLED, CANCELLED, or same trader
            if (oppositeOrderTrader == msg.sender) {
                oppositeOrderId = nextoppositeOrderId;
                continue;
            }

            uint256 oppositeOrderAmount = dataStore.getUint(CentuariCLOBDSLib.getOrderAmountKey(oppositeOrderId));
            uint256 oppositeOrdercollateralAmount =
                dataStore.getUint(CentuariCLOBDSLib.getOrderCollateralAmountKey(oppositeOrderId));

            uint256 matchedAmount = (oppositeOrderAmount < newOrder.amount) ? oppositeOrderAmount : newOrder.amount;
            _matchOrder(
                config,
                rate,
                side,
                MatchedOrder({
                    id: newOrder.id,
                    trader: newOrder.trader,
                    amount: newOrder.amount,
                    collateralAmount: newOrder.collateralAmount
                }),
                MatchedOrder({
                    id: oppositeOrderId,
                    trader: oppositeOrderTrader,
                    amount: oppositeOrderAmount,
                    collateralAmount: oppositeOrdercollateralAmount
                }),
                matchedAmount
            );

            // Update amount and collateral amount for new order
            newOrder.amount -= matchedAmount;
            newOrder.collateralAmount -= (newOrder.collateralAmount * matchedAmount) / newOrder.amount;
            newOrder.status = (newOrder.amount == 0) ? Status.FILLED : Status.PARTIALLY_FILLED;

            // Get next match order
            oppositeOrderId = nextoppositeOrderId;
        }

        // ----------------------------------
        // 4. If newOrder is STILL OPEN OR PARTIALLY FILLED
        // ----------------------------------
        if (newOrder.status == Status.OPEN || newOrder.status == Status.PARTIALLY_FILLED) {
            // Add new order to linked list
            dataStore.setAddress(CentuariCLOBDSLib.getOrderTraderKey(newOrder.id), msg.sender);
            dataStore.setUint(CentuariCLOBDSLib.getOrderAmountKey(newOrder.id), newOrder.amount);
            dataStore.setUint(CentuariCLOBDSLib.getOrderCollateralAmountKey(newOrder.id), newOrder.collateralAmount);
            dataStore.setUint(CentuariCLOBDSLib.getOrderRateKey(newOrder.id), newOrder.rate);
            dataStore.setUint(CentuariCLOBDSLib.getOrderSideKey(newOrder.id), uint256(newOrder.side));
            dataStore.setUint(CentuariCLOBDSLib.getOrderStatusKey(newOrder.id), uint256(Status.OPEN));
            OrderQueueLib.appendOrder(dataStore, newOrder.rate, newOrder.side, newOrder.id);
        }
    }

    function _matchOrder(
        MarketConfig calldata config,
        uint256 rate,
        Side side,
        MatchedOrder memory newOrder,
        MatchedOrder memory oppositeOrder,
        uint256 matchedAmount
    ) internal onlyActiveMarket(config.id()) nonReentrant {
        DataStore dataStore = DataStore(dataStores[config.id()]);

        CENTUARI.addRate(config, rate);

        // Update match order state on centuari
        uint256 remainingOppositeOrderAmount = oppositeOrder.amount - matchedAmount;
        Status oppositeOrderStatus = (remainingOppositeOrderAmount == 0) ? Status.FILLED : Status.PARTIALLY_FILLED;
        dataStore.setUint(CentuariCLOBDSLib.getOrderAmountKey(oppositeOrder.id), remainingOppositeOrderAmount);
        dataStore.setUint(CentuariCLOBDSLib.getOrderStatusKey(oppositeOrder.id), uint256(oppositeOrderStatus));

        // Call centuari borrow and lend function
        if (side == Side.LEND) {
            // Update collateral amount on oppositeOrder
            uint256 collateralAmount = (oppositeOrder.collateralAmount * matchedAmount) / oppositeOrder.amount;
            uint256 remainingCollateralAmount = oppositeOrder.collateralAmount - collateralAmount;
            dataStore.setUint(CentuariCLOBDSLib.getOrderCollateralAmountKey(oppositeOrder.id), remainingCollateralAmount);

            // Call centuari necessary functions to update state
            CENTUARI.supply(config, rate, newOrder.trader, matchedAmount);
            CENTUARI.supplyCollateral(config, rate, oppositeOrder.trader, collateralAmount);
            CENTUARI.borrow(config, rate, oppositeOrder.trader, matchedAmount);

            // Transfer loanToken from newOrder.trader to oppositeOrder.trader
            CENTUARI.transferFrom(
                config, config.loanToken, newOrder.trader, oppositeOrder.trader, matchedAmount
            );
        } else if (side == Side.BORROW) {
            // Call centuari necessary functions to update state
            CENTUARI.supply(config, rate, oppositeOrder.trader, matchedAmount);
            CENTUARI.supplyCollateral(
                config, rate, newOrder.trader, ((newOrder.collateralAmount * matchedAmount) / newOrder.amount)
            );
            CENTUARI.borrow(config, rate, newOrder.trader, matchedAmount);

            // Transfer loanToken from oppositeOrder.trader to newOrder.trader
            CENTUARI.transferFrom(
                config, config.loanToken, oppositeOrder.trader, newOrder.trader, matchedAmount
            );
        }

        // Remove oppositeOrder from linked list if match order fully filled
        if (oppositeOrder.amount == matchedAmount) {
            Side oppositeSide = (side == Side.LEND) ? Side.BORROW : Side.LEND;
            OrderQueueLib.unlinkOrder(dataStore, rate, oppositeSide, oppositeOrder.id);
        }

        emit CentuariCLOBEventsLib.OrderMatched(config.id(), newOrder.id, oppositeOrder.id, matchedAmount);
    }

    function cancelOrder(MarketConfig calldata config, uint256 orderId) external nonReentrant {
        // Validate market config
        if (dataStores[config.id()] == address(0)) {
            revert CentuariCLOBErrorsLib.InvalidMarketConfig();
        }
        DataStore dataStore = DataStore(dataStores[config.id()]);

        // Deactivate market if expired
        if (block.timestamp >= dataStore.getUint(CentuariDSLib.MATURITY_UINT256)) {
            dataStore.setBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL, false);
        }

        // Validate order belongs to trader
        address trader = dataStore.getAddress(CentuariCLOBDSLib.getOrderTraderKey(orderId));
        if (trader != msg.sender) {
            revert CentuariCLOBErrorsLib.InvalidOrder();
        }

        // Get order state from data store
        uint256 amount = dataStore.getUint(CentuariCLOBDSLib.getOrderAmountKey(orderId));
        uint256 collateralAmount = dataStore.getUint(CentuariCLOBDSLib.getOrderCollateralAmountKey(orderId));
        uint256 rate = dataStore.getUint(CentuariCLOBDSLib.getOrderRateKey(orderId));
        Side side = Side(dataStore.getUint(CentuariCLOBDSLib.getOrderSideKey(orderId)));

        // Reset order state in data store
        dataStore.setAddress(CentuariCLOBDSLib.getOrderTraderKey(orderId), address(0));
        dataStore.setUint(CentuariCLOBDSLib.getOrderAmountKey(orderId), 0);
        dataStore.setUint(CentuariCLOBDSLib.getOrderCollateralAmountKey(orderId), 0);
        dataStore.setUint(CentuariCLOBDSLib.getOrderRateKey(orderId), 0);
        dataStore.setUint(CentuariCLOBDSLib.getOrderSideKey(orderId), 0);
        dataStore.setUint(CentuariCLOBDSLib.getOrderStatusKey(orderId), 0);

        // Remove order from linked list
        OrderQueueLib.unlinkOrder(dataStore, rate, side, orderId);

        // Transfer tokens from centuari to trader
        if (side == Side.LEND) {
            CENTUARI.transferFrom(config, config.loanToken, address(this), msg.sender, amount);
        } else if (side == Side.BORROW) {
            CENTUARI.transferFrom(
                config, config.collateralToken, address(this), msg.sender, collateralAmount
            );
        }

        emit CentuariCLOBEventsLib.OrderCancelled(config.id(), orderId);
    }
}