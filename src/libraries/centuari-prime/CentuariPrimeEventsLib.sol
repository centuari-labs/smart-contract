//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VaultMarketConfig} from "../../types/CommonTypes.sol";

library CentuariPrimeEventsLib {
    event CreateVault(address indexed curator, address indexed vault, address token, string name);
    event Deposit(address indexed vault, address indexed user, uint256 amount);
    event Withdraw(address indexed vault, address indexed user, uint256 shares, uint256 assets);
    event SetSupplyQueue(address indexed curator, address indexed vault, VaultMarketConfig[] supplyQueue);
}