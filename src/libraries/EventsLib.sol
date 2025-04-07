// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library EventsLib {
    event FlashLoan(address indexed caller, address indexed token, uint256 assets);
}