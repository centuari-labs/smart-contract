// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library ErrorsLib {
    string internal constant ZERO_ASSETS = "zero assets";
    string internal constant TRANSFER_REVERTED = "transfer reverted";
    string internal constant NO_CODE = "no code";
    string internal constant TRANSFER_RETURNED_FALSE = "transfer returned false";
    string internal constant TRANSFER_FROM_REVERTED = "transferFrom reverted";
    string internal constant TRANSFER_FROM_RETURNED_FALSE = "transfer from returned false";
    string internal constant ONLY_ROUTER = "Only router can call this function";
}
