//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {VaultMarketSupplyConfig, VaultMarketWithdrawConfig, Id} from "../../types/CommonTypes.sol";

library CentuariPrimeEventsLib {
    event CreateVault(address indexed curator, address indexed vault, address token, string name);
    event Deposit(address indexed vault, address indexed curator, address indexed user, uint256 amount);
    event Withdraw(address indexed vault, address indexed curator, address indexed user, uint256 assets);
    event SetSupplyQueue(
        address indexed curator, 
        address indexed vault, 
        uint256 index,
        Id marketId,
        address loanToken,
        address collateralToken,
        uint256 maturity,
        uint256 rate,
        uint256 cap
    );
    event SetWithdrawQueue(
        address indexed curator, 
        address indexed vault, 
        uint256 index, 
        Id marketId,
        address loanToken,
        address collateralToken,
        uint256 maturity, 
        uint256 rate
    );
}
