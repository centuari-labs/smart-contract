// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library CentuariPrimeErrorsLib {
    error InvalidVaultConfig();
    error VaultAlreadyExists();
    error VaultDoesNotExist();
    error InsufficientShares();
    error InvalidAmount();
    error OnlyCurator();
    error MarketNotActive();
}
