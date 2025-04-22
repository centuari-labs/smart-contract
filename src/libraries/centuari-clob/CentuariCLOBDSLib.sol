// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {DataStore} from "../../core/DataStore.sol";

library CentuariCLOBDSLib {
    // Order struct data
    string public constant ORDER_ID_UINT256 = "ORDER_ID";
    string public constant ORDER_TRADER_ADDRESS = "ORDER_TRADER";
    string public constant ORDER_AMOUNT_UINT256 = "ORDER_AMOUNT";
    string public constant ORDER_COLLATERAL_AMOUNT_UINT256 = "ORDER_COLLATERAL_AMOUNT";
    string public constant ORDER_RATE_UINT256 = "ORDER_RATE";
    string public constant ORDER_SIDE_UINT256 = "ORDER_SIDE";
    string public constant ORDER_STATUS_UINT256 = "ORDER_STATUS";

    // Market data
    string public constant MARKET_LENDING_RATE_UINT256 = "MARKET_LENDING_RATE";
    string public constant MARKET_BORROWING_RATE_UINT256 = "MARKET_BORROWING_RATE";

    // Order struct key (order ID)
    function getOrderTraderKey(uint256 orderId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, ORDER_TRADER_ADDRESS));
    }

    function getOrderAmountKey(uint256 orderId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, ORDER_AMOUNT_UINT256));
    }

    function getOrderCollateralAmountKey(uint256 orderId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, ORDER_COLLATERAL_AMOUNT_UINT256));
    }

    function getOrderRateKey(uint256 orderId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, ORDER_RATE_UINT256));
    }

    function getOrderSideKey(uint256 orderId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, ORDER_SIDE_UINT256));
    }

    function getOrderStatusKey(uint256 orderId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, ORDER_STATUS_UINT256));
    }

    // Order function
    function getNextOrderId(DataStore dataStore) internal returns (uint256 id) {
        bytes32 orderIdKey = keccak256(abi.encodePacked(ORDER_ID_UINT256));
        id = dataStore.getUint(orderIdKey) + 1;
        dataStore.setUint(orderIdKey, id);
    }

    // Market function
    function getMarketLendingRate(DataStore dataStore) internal view returns (uint256) {
        bytes32 marketLendingRateKey = keccak256(abi.encodePacked(MARKET_LENDING_RATE_UINT256));
        return dataStore.getUint(marketLendingRateKey);
    }

    function getMarketBorrowingRate(DataStore dataStore) internal view returns (uint256) {
        bytes32 marketBorrowingRateKey = keccak256(abi.encodePacked(MARKET_BORROWING_RATE_UINT256));
        return dataStore.getUint(marketBorrowingRateKey);
    }

    function setMarketLendingRate(DataStore dataStore, uint256 rate) internal {
        bytes32 marketLendingRateKey = keccak256(abi.encodePacked(MARKET_LENDING_RATE_UINT256));
        dataStore.setUint(marketLendingRateKey, rate);
    }

    function setMarketBorrowingRate(DataStore dataStore, uint256 rate) internal {
        bytes32 marketBorrowingRateKey = keccak256(abi.encodePacked(MARKET_BORROWING_RATE_UINT256));
        dataStore.setUint(marketBorrowingRateKey, rate);
    }
}
