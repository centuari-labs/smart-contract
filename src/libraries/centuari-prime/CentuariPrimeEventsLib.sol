//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library CentuariPrimeEventsLib {
    event CreateVault(address indexed vault, address curator, address token, string name);
    event Deposit(address indexed vault, address indexed user, uint256 amount);
    event Withdraw(address indexed vault, address indexed user, uint256 shares, uint256 assets);
}