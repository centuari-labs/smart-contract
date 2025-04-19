// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {DataStore} from "../../core/DataStore.sol";
import {Side} from "../../types/CommonTypes.sol";

/**
 * @dev All maths is library‑pure; storage access
 *      is done via the DataStore interface passed in.
 */
library OrderQueueLib {
    // Linked-list pointer
    string public constant LINKED_PREV_UINT256 = "LINKED_PREV";
    string public constant LINKED_NEXT_UINT256 = "LINKED_NEXT";
    string public constant LINKED_HEAD_UINT256 = "LINKED_HEAD";
    string public constant LINKED_TAIL_UINT256 = "LINKED_TAIL";

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

    // Linked-list function: append id at tail of (rate,side) list
    function appendOrder(DataStore dataStore, uint256 rate, Side side, uint256 id) internal {
        bytes32 tailKey = getLinkedTailKey(rate, side);
        uint256 tail = dataStore.getUint(tailKey);
        if (tail == 0) {
            dataStore.setUint(getLinkedHeadKey(rate, side), id);
        } else {
            dataStore.setUint(getLinkedNextKey(tail), id);
            dataStore.setUint(getLinkedPrevKey(id), tail);
        }
        dataStore.setUint(tailKey, id);
    }

    /// splice id out of its linked list
    function unlinkOrder(DataStore dataStore, uint256 rate, Side side, uint256 id) internal {
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
