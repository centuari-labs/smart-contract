// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Id, MarketConfig, Side, Order, OrderStatus} from "../types/CommonTypes.sol";
import {MarketConfigLib} from "../libraries/MarketConfigLib.sol";
import {CentuariCLOBMarket} from "./CentuariCLOBMarket.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {DataStore} from "./DataStore.sol";
import {CentuariCLOBDSLib} from "../libraries/centuari-clob/CentuariCLOBDSLib.sol";
import {RedBlackTreeLib} from "@solady/utils/RedBlackTreeLib.sol";
import {OrderQueueLib} from "../libraries/centuari-clob/OrderQueueLib.sol";
import {IDataStore} from "../interfaces/IDataStore.sol";

contract CentuariCLOB is Ownable, ReentrancyGuard {
    using MarketConfigLib for MarketConfig;

    mapping(Id => address) public markets;
    DataStore public orderGroup;

    constructor(address owner_) Ownable(owner_) {
        orderGroup = new DataStore(address(this), address(this));
    }

    function createMarket(MarketConfig calldata config) external onlyOwner {
        // Define maturity options in days
        uint256[4] memory maturities = [uint256(1), uint256(7), uint256(30), uint256(90)]; //@todo: need to add function in datastore to save uint8

        for (uint8 i = 0; i < maturities.length; i++) {
            Id marketId = config.id(maturities[i]);
            require(markets[marketId] == address(0), "Market already exists");
            markets[marketId] = address(new CentuariCLOBMarket(address(this), config, maturities[i]));
        }
    }

    function placeOrderGroup(MarketConfig[] calldata config, uint256 rate, Side side, uint256 amount, uint256 collateralAmount, uint256 maturity) external nonReentrant {
        // @note Check if the market is still active

        // Add group to order group
        uint256 groupId = CentuariCLOBDSLib.getNextOrderGroupId(orderGroup);
        orderGroup.setUint(CentuariCLOBDSLib.getOrderGroupAmountKey(groupId), amount);
        orderGroup.setUint(CentuariCLOBDSLib.getOrderGroupCollateralAmountKey(groupId), collateralAmount);
        orderGroup.setUint(CentuariCLOBDSLib.getOrderGroupStatusKey(groupId), uint256(OrderStatus.OPEN));

        for(uint256 i = 0; i < config.length; i++) {
            //Place Order to all selected markets
            _placeOrder(config[i], maturity, rate, side, amount, collateralAmount, groupId);
        }
    }

    function _placeOrder(MarketConfig calldata config, uint256 maturity, uint256 rate, Side side, uint256 amount, uint256 collateralAmount, uint256 groupId)
        internal
        nonReentrant
    {
        Id marketId = config.id(maturity);
        CentuariCLOBMarket market = CentuariCLOBMarket(markets[marketId]);
        DataStore marketDataStore = DataStore(market.getMarketDataStore()); //@todo: change to using IDataStore

        // Place Order to the market
        uint256 orderId = CentuariCLOBDSLib.getNextOrderId(marketDataStore);
        Order memory order = Order({
            id: orderId,
            trader: msg.sender,
            rate: rate,
            side: side,
            groupId: groupId
        });
        marketDataStore.setAddress(CentuariCLOBDSLib.getOrderTraderKey(orderId), msg.sender);
        marketDataStore.setUint(CentuariCLOBDSLib.getOrderRateKey(orderId), rate);
        marketDataStore.setUint(CentuariCLOBDSLib.getOrderSideKey(orderId), uint256(side));
        marketDataStore.setUint(CentuariCLOBDSLib.getOrderGroupIdKey(orderId), groupId);

        if(rate != 0) {
            bool isRateInTree = market.rateExists(rate);
            if(!isRateInTree) {
                // Insert into tree
                market.addRateToTree(rate);
                _addOrderToQueue(marketId, rate, order);
            }else{
                _matchOrder(marketId, rate, order, msg.sender, groupId);
            }
        }

        //Transfer amount or collateral to Centuari
    }

    function _addOrderToQueue(Id marketId, uint256 rate, Order memory order) internal {
        DataStore dataStore = DataStore(CentuariCLOBMarket(markets[marketId]).getMarketDataStore()); //@todo: change to using IDataStore

        // Add new order to queue
        dataStore.setAddress(CentuariCLOBDSLib.getOrderTraderKey(order.id), msg.sender);
        dataStore.setUint(CentuariCLOBDSLib.getOrderRateKey(order.id), order.rate);
        dataStore.setUint(CentuariCLOBDSLib.getOrderSideKey(order.id), uint256(order.side));
        OrderQueueLib.appendOrder(dataStore, order.rate, order.side, order.id);

        if (
            order.side == Side.LEND && 
            (order.rate < CentuariCLOBDSLib.getMarketLendingRate(dataStore) || CentuariCLOBDSLib.getMarketLendingRate(dataStore) == 0)
        ) {
            // Update market lending rate
            CentuariCLOBDSLib.setMarketLendingRate(dataStore, order.rate);

            // @todo emit event
        }
        else if (
            order.side == Side.BORROW && 
            order.rate > CentuariCLOBDSLib.getMarketBorrowingRate(dataStore)
        ) {
            // Update market borrowing rate
            CentuariCLOBDSLib.setMarketBorrowingRate(dataStore, order.rate);

            // @todo emit event
        }
    }

     function _matchOrder(Id marketId, uint256 rate, Order memory order, address trader, uint256 groupId) internal {
        IDataStore dataStore = IDataStore(CentuariCLOBMarket(markets[marketId]).getMarketDataStore());

        Side oppositeSide = (order.side == Side.LEND) ? Side.BORROW : Side.LEND;
        uint256 oppositeOrderId = dataStore.getUint(OrderQueueLib.getLinkedHeadKey(order.rate, oppositeSide));

        // Get Order Group Amount and Collateral Amount
        uint256 orderGroupId = dataStore.getUint(CentuariCLOBDSLib.getOrderGroupIdKey(order.groupId));
        uint256 orderGroupAmount = orderGroup.getUint(CentuariCLOBDSLib.getOrderGroupAmountKey(orderGroupId)); 
        uint256 orderGroupCollateralAmount = orderGroup.getUint(CentuariCLOBDSLib.getOrderGroupCollateralAmountKey(orderGroupId));
        OrderStatus orderGroupStatus = OrderStatus(orderGroup.getUint(CentuariCLOBDSLib.getOrderGroupStatusKey(orderGroupId)));
        
        while(oppositeOrderId != 0 && orderGroupStatus != OrderStatus.FILLED) {
            uint256 nextoppositeOrderId = dataStore.getUint(OrderQueueLib.getLinkedNextKey(oppositeOrderId));
            address oppositeTrader = dataStore.getAddress(CentuariCLOBDSLib.getOrderTraderKey(oppositeOrderId)); 

            //If the opposite order is from the same trader, skip
            if(oppositeTrader == trader) {
                oppositeOrderId = nextoppositeOrderId;
                continue;
            }

            // Get Opposite Order Group Amount and Collateral Amount
            uint256 oppositeOrderGroupId = dataStore.getUint(CentuariCLOBDSLib.getOrderGroupIdKey(oppositeOrderId));
            uint256 oppositeOrderGroupAmount = orderGroup.getUint(CentuariCLOBDSLib.getOrderGroupAmountKey(oppositeOrderGroupId)); 
            uint256 oppositeOrderGroupCollateralAmount = orderGroup.getUint(CentuariCLOBDSLib.getOrderGroupCollateralAmountKey(oppositeOrderGroupId));

            // If the opposite order group is fully filled, skip
            if(oppositeOrderGroupAmount == 0) {
                oppositeOrderId = nextoppositeOrderId;
                _removeOrderFromQueue(marketId, rate, oppositeSide, oppositeOrderId);
                continue;
            }
            
            uint256 matchedAmount = (oppositeOrderGroupAmount < orderGroupAmount) ? oppositeOrderGroupAmount : orderGroupAmount;

            //Update Opposite Order Amount and Status   
            uint256 remainingOppositeOrderGroupAmount = oppositeOrderGroupAmount - matchedAmount;
            OrderStatus oppositeOrderGroupStatus = (remainingOppositeOrderGroupAmount == 0) ? OrderStatus.FILLED : OrderStatus.PARTIALLY_FILLED;
            orderGroup.setUint(CentuariCLOBDSLib.getOrderGroupAmountKey(oppositeOrderGroupId), remainingOppositeOrderGroupAmount); 
            orderGroup.setUint(CentuariCLOBDSLib.getOrderGroupStatusKey(oppositeOrderGroupId), uint256(oppositeOrderGroupStatus)); 

            // Remove oppositeOrder from linked list if the order group is fully filled
            if (remainingOppositeOrderGroupAmount == 0) {
                _removeOrderFromQueue(marketId, rate, oppositeSide, oppositeOrderId);
            }

            // Update Order Group Status
            uint256 remainingOrderGroupAmount = orderGroupAmount - matchedAmount;
            orderGroupStatus = (remainingOrderGroupAmount == 0) ? OrderStatus.FILLED : OrderStatus.PARTIALLY_FILLED;
            orderGroup.setUint(CentuariCLOBDSLib.getOrderGroupAmountKey(orderGroupId), remainingOrderGroupAmount); 
            orderGroup.setUint(CentuariCLOBDSLib.getOrderGroupStatusKey(orderGroupId), uint256(orderGroupStatus)); 

            if(order.side == Side.LEND) {
                //@todo Call centuari for lend
            }else if(order.side == Side.BORROW) {
                //@note Call centuari for borrow
            }

            oppositeOrderId = nextoppositeOrderId;
        }

        if(orderGroupStatus == OrderStatus.OPEN || orderGroupStatus == OrderStatus.PARTIALLY_FILLED) {
            _addOrderToQueue(marketId, rate, order);
        }
    }

    function _removeOrderFromQueue(Id marketId, uint256 rate, Side side, uint256 orderId) internal {
        CentuariCLOBMarket market = CentuariCLOBMarket(markets[marketId]);
        DataStore dataStore = DataStore(market.getMarketDataStore()); //@todo: change to using IDataStore
        OrderQueueLib.unlinkOrder(dataStore, rate, side, orderId);

        // Check if current side is empty
        uint256 headLend = dataStore.getUint(OrderQueueLib.getLinkedHeadKey(rate, Side.LEND));
        uint256 tailLend = dataStore.getUint(OrderQueueLib.getLinkedTailKey(rate, Side.LEND));
        uint256 headBorrow = dataStore.getUint(OrderQueueLib.getLinkedHeadKey(rate, Side.BORROW));
        uint256 tailBorrow = dataStore.getUint(OrderQueueLib.getLinkedTailKey(rate, Side.BORROW));

        if(headLend != 0 || tailLend != 0 || headBorrow != 0 || tailBorrow != 0) { return; }

        market.removeRateFromTree(rate);
    }
}