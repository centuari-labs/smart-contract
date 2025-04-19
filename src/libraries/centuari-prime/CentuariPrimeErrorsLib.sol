// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library CentuariPrimeErrorsLib {
    error InvalidVaultConfig();
    error VaultAlreadyExists();
    error VaultDoesNotExist();
    error RemoveMarketNotAllowed(address loanToken, address collateralToken, uint256 maturity, uint256 rate);
    error InvalidAmount();
    error InvalidMarket(address loanToken, address collateralToken, uint256 maturity, uint256 rate);
    error InvalidCap();
    error DuplicateVaultMarketConfig(address loanToken, address collateralToken, uint256 maturity, uint256 rate);
    error InsufficientShares();
    error InsufficientLiquidity();
    error InvalidReallocateConfig();
    error VaultInactive();
    error OnlyVaultOwner();
}
