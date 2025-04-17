// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Common types used across multiple contracts
type Id is bytes32;

struct MarketConfig {
    address loanToken;
    address collateralToken;
    uint256 maturity;
}

struct VaultMarketSupplyConfig{
    MarketConfig marketConfig;
    uint256 rate;
    uint256 cap;
}

struct VaultMarketWithdrawConfig{
    MarketConfig marketConfig;
    uint256 rate;
}

struct VaultConfig{
    address curator;
    address token;
    string name;
}

enum Side {
    LEND,
    BORROW
}