// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library CentuariErrorsLib {
    error InvalidUser();    
    error InvalidAmount();
    error MarketExpired();
    error MarketNotActive();
    error InvalidLltv();
    error InvalidOracle();
    error RateAlreadyExists();
    error InvalidRate();
    error InsufficientCollateral();
    error OnlyLendingCLOB();
    error InsufficientLiquidity();
    error LiquidationNotAllowed();

    string internal constant INVALID_MARKET_CONFIG = "Invalid market configuration";
}
