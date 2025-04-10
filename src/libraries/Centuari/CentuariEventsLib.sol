// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library CentuariEventsLib {
    event FlashLoan(address indexed caller, address indexed token, uint256 assets);
    event Supply(uint256 borrowRate, address indexed user, uint256 shares, uint256 assets);
    event Borrow(uint256 borrowRate, address indexed user, uint256 shares, uint256 assets);
    event BorrowRateAdded(uint256 borrowRate);
    event BondTokenCreated(address indexed bondToken, uint256 borrowRate);
}
