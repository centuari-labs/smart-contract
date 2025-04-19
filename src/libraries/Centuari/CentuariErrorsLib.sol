// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library CentuariErrorsLib {
    error InvalidMarketConfig();
    error InvalidUser();
    error InvalidAmount();
    error MarketExpired();
    error MarketNotActive();
    error InvalidLltv();
    error InvalidOracle();
    error RateNotActive();
    error RateAlreadyExists();
    error InvalidRate();
    error InsufficientCollateral();
    error OnlyLendingCLOB();
    error InsufficientLiquidity();
    error LiquidationNotAllowed();
    error MarketNotMature();
    error InsufficientShares();
    error InsufficientBorrowShares();
}
