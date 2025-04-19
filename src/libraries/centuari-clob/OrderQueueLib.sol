// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {DataStore} from "../../core/DataStore.sol";
import {Side} from "../../types/CommonTypes.sol";

/**
 * @dev All maths is library‑pure; storage access
 *      is done via the DataStore interface passed in.
 */
library OrderQueueLib {
    // Order struct data
    string public constant ORDER_ID_UINT256 = "ORDER_ID";
    string public constant ORDER_TRADER_ADDRESS = "ORDER_TRADER";
    string public constant ORDER_AMOUNT_UINT256 = "ORDER_AMOUNT";
    string public constant ORDER_COLLAT_AMOUNT_UINT256 = "ORDER_COLLAT_AMOUNT";
    string public constant ORDER_RATE_UINT256 = "ORDER_RATE";
    string public constant ORDER_SIDE_UINT256 = "ORDER_SIDE";
    string public constant ORDER_STATUS_UINT256 = "ORDER_STATUS";

    // Linked-list pointer
    string public constant LINKED_PREV_UINT256 = "LINKED_PREV";
    string public constant LINKED_NEXT_UINT256 = "LINKED_NEXT";
    string public constant LINKED_HEAD_UINT256 = "LINKED_HEAD";
    string public constant LINKED_TAIL_UINT256 = "LINKED_TAIL";

    // Order struct key (order ID)
    function getTraderKey(uint256 orderId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, ORDER_TRADER_ADDRESS));
    }
    function getAmountKey(uint256 orderId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, ORDER_AMOUNT_UINT256));
    }
    function getCollatAmountKey(uint256 orderId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, ORDER_COLLAT_AMOUNT_UINT256));
    }
    function getRateKey(uint256 orderId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, ORDER_RATE_UINT256));
    }
    function getSideKey(uint256 orderId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, ORDER_SIDE_UINT256));
    }
    function getStatusKey(uint256 orderId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, ORDER_STATUS_UINT256));
    }

    // Linked-list key (order ID)
    function getLinkedPrevKey(uint256 orderId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, LINKED_PREV_UINT256));
    }
    function getLinkedNextKey(uint256 orderId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderId, LINKED_NEXT_UINT256));
    }

    // Linked-list head and tail (rate + side)
    function getLinkedHeadKey(uint256 rate, Side side) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(rate, side, LINKED_HEAD_UINT256));
    }
    function getLinkedTailKey(uint256 rate, Side side) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(rate, side, LINKED_TAIL_UINT256));
    }

    // Order function

    function getNextOrderId(DataStore dataStore) internal returns (uint256 id) {
        bytes32 orderIdKey = keccak256(abi.encodePacked(ORDER_ID_UINT256));
        id = dataStore.getUint(orderIdKey) + 1;
        dataStore.setUint(orderIdKey, id);
    }

    // Linked-list function: append id at tail of (rate,side) list
    function appendOrder(DataStore dataStore, uint256 id, uint256 rate, Side side) internal {
        bytes32 tailKey = getLinkedTailKey(rate, side);
        uint256 tail = dataStore.getUint(tailKey);
        if (tail == 0) {
            dataStore.setUint(getLinkedHeadKey(rate, side), id);
            dataStore.setUint(tailKey, id);
        } else {
            dataStore.setUint(getLinkedNextKey(tail), id);
            dataStore.setUint(getLinkedPrevKey(id), tail);
            dataStore.setUint(tailKey, id);
        }
    }

    /// splice id out of its linked list
    function unlinkOrder(DataStore dataStore, uint256 id, uint256 rate, Side side) internal {
        uint256 linkedPrev = dataStore.getUint(getLinkedPrevKey(id));
        uint256 linkedNext = dataStore.getUint(getLinkedNextKey(id));

        if (linkedPrev == 0) dataStore.setUint(getLinkedHeadKey(rate, side), linkedNext);
        else dataStore.setUint(getLinkedNextKey(linkedPrev), linkedNext);

        if (linkedNext == 0) dataStore.setUint(getLinkedTailKey(rate, side), linkedPrev);
        else dataStore.setUint(getLinkedPrevKey(linkedNext), linkedPrev);

        deleteMapping(dataStore, getLinkedPrevKey(id));
        deleteMapping(dataStore, getLinkedNextKey(id));
    }

    /* small helper for optional refund */
    function deleteMapping(DataStore dataStore, bytes32 key) private {
        if (dataStore.getUint(key) != 0) dataStore.setUint(key, 0);
    }

    /* view */
    function getLinkedHead(DataStore dataStore, uint256 rate, Side side) internal view returns (uint256) {
        return dataStore.getUint(getLinkedHeadKey(rate, side));
    }
}
