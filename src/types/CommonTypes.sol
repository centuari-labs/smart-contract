// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Common types used across multiple contracts
type Id is bytes32;

struct MarketConfig {
    address loanToken;
    address collateralToken;
    uint256 maturity;
}

enum Side {
    LEND,
    BORROW
}