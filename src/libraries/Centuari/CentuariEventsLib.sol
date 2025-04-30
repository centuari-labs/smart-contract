// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Id} from "../../types/CommonTypes.sol";

library CentuariEventsLib {
    event CreateDataStore(Id indexed marketId, address indexed dataStore, address loanToken, address collateralToken, uint256 maturity);
    event SetDataStore(Id indexed marketId, address indexed newDataStore, address loanToken, address collateralToken, uint256 maturity);
    event FlashLoan(address indexed caller, address indexed token, uint256 amount);
    event LltvUpdated(Id indexed marketId, uint256 lltv);
    event OracleUpdated(Id indexed marketId, address oracle);
    event Supply(Id indexed marketId, address indexed user, uint256 rate, uint256 shares, uint256 assets);
    event Borrow(Id indexed marketId, address indexed user, uint256 rate, uint256 shares, uint256 assets);
    event Withdraw(Id indexed marketId, address indexed user, uint256 rate, uint256 shares, uint256 assets);
    event SupplyCollateral(Id indexed marketId, address indexed user, uint256 rate, uint256 amount);
    event WithdrawCollateral(Id indexed marketId, address indexed user, uint256 rate, uint256 amount);
    event Repay(Id indexed marketId, address indexed user, uint256 rate, uint256 amount);
    event Liquidate(
        Id indexed marketId, address indexed liquidator, uint256 rate, address indexed user, uint256 borrowShares, uint256 collateral
    );
    event RateAdded(Id indexed marketId, uint256 rate);
    event CentuariTokenCreated(Id indexed marketId, address indexed centuariToken, uint256 rate);
    event TransferFrom(Id indexed marketId, address indexed token, address from, address to, uint256 amount);
}
