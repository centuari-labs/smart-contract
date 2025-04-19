// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
    error OnlyCentuariCLOB();
    error InsufficientLiquidity();
    error LiquidationNotAllowed();
    error MarketNotMature();
    error InsufficientShares();
    error InsufficientBorrowShares();
}
