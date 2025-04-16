// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Id} from "../../types/CommonTypes.sol";

library CentuariEventsLib {
    event CreateDataStore(address indexed dataStore, address loanToken, address collateralToken, uint256 maturity);
    event SetDataStore(address indexed newDataStore, address loanToken, address collateralToken, uint256 maturity);
    event FlashLoan(address indexed caller, address indexed token, uint256 amount);
    event LltvUpdated(Id indexed id, uint256 lltv);
    event OracleUpdated(Id indexed id, address oracle);
    event Supply(address indexed user, uint256 rate, uint256 shares, uint256 assets);
    event Borrow(address indexed user, uint256 rate, uint256 shares, uint256 assets);
    event Withdraw(address indexed user, uint256 rate, uint256 shares, uint256 assets);
    event SupplyCollateral(address indexed user, uint256 rate, uint256 amount);
    event WithdrawCollateral(address indexed user, uint256 rate, uint256 amount);
    event Repay(address indexed user, uint256 rate, uint256 amount);
    event Liquidate(
        address indexed liquidator, uint256 rate, address indexed user, uint256 borrowShares, uint256 collateral
    );
    event RateAdded(uint256 rate);
    event BondTokenCreated(address indexed bondToken, uint256 rate);
}
