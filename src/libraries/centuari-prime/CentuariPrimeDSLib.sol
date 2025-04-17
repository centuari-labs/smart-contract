// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library CentuariPrimeDSLib {
    //VAULT CONFIG
    bytes32 public constant CURATOR_ADDRESS = keccak256("CURATOR");
    bytes32 public constant TOKEN_ADDRESS = keccak256("TOKEN");
    bytes32 public constant NAME_STRING = keccak256("NAME");
    bytes32 public constant SUPPLY_QUEUE_BYTES = keccak256("SUPPLY_QUEUE");
    bytes32 public constant WITHDRAW_QUEUE_BYTES = keccak256("WITHDRAW_QUEUE");
    bytes32 public constant TOTAL_SHARES_UINT256 = keccak256("TOTAL_SHARES");
    bytes32 public constant TOTAL_ASSETS_UINT256 = keccak256("TOTAL_ASSETS");
    bytes32 public constant LAST_ACCRUE_UINT256 = keccak256("LAST_ACCRUE");
    bytes32 public constant CENTUARI_PRIME_TOKEN_ADDRESS = keccak256("CENTUARI_PRIME_TOKEN");
    bytes32 public constant IS_ACTIVE_BOOL = keccak256("IS_ACTIVE");
}
