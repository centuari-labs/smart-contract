// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library CentuariPrimeErrorsLib {
    error InvalidVaultConfig();
    error VaultAlreadyExists();
    error VaultDoesNotExist();
    error RemoveMarketNotAllowed(address loanToken, address collateralToken, uint256 maturity, uint256 rate);
    error InvalidAmount();
    error OnlyCurator();
    error MarketNotActive(address loanToken, address collateralToken, uint256 maturity, uint256 rate);
    error InvalidCap();
}
