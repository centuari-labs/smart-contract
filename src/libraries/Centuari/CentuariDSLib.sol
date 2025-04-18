// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library CentuariDSLib {
    // Market Config
    bytes32 public constant LOAN_TOKEN_ADDRESS = keccak256("LOAN_TOKEN");
    bytes32 public constant COLLATERAL_TOKEN_ADDRESS = keccak256("COLLATERAL_TOKEN");
    bytes32 public constant MATURITY_UINT256 = keccak256("MATURITY");
    bytes32 public constant ORACLE_ADDRESS = keccak256("ORACLE");
    bytes32 public constant LLTV_UINT256 = keccak256("LLTV");
    bytes32 public constant IS_MARKET_ACTIVE_BOOL = keccak256("IS_MARKET_ACTIVE");

    //Lending Pool Data
    string public constant TOTAL_SUPPLY_SHARES_UINT256 = "TOTAL_SUPPLY_SHARES";
    string public constant TOTAL_SUPPLY_ASSETS_UINT256 = "TOTAL_SUPPLY_ASSETS";
    string public constant TOTAL_BORROW_SHARES_UINT256 = "TOTAL_BORROW_SHARES";
    string public constant TOTAL_BORROW_ASSETS_UINT256 = "TOTAL_BORROW_ASSETS";
    string public constant USER_BORROW_SHARES_UINT256 = "USER_BORROW_SHARES";
    string public constant USER_BORROW_ASSETS_UINT256 = "USER_BORROW_ASSETS";
    string public constant USER_COLLATERAL_UINT256 = "USER_COLLATERAL";
    string public constant BOND_TOKEN_ADDRESS = "BOND_TOKEN";
    string public constant LAST_ACCRUE_UINT256 = "LAST_ACCRUE";

    function getTotalSuppySharesKey(uint256 rate) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(rate, TOTAL_SUPPLY_SHARES_UINT256));
    }

    function getTotalSuppyAssetsKey(uint256 rate) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(rate, TOTAL_SUPPLY_ASSETS_UINT256));
    }

    function getTotalBorrowSharesKey(uint256 rate) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(rate, TOTAL_BORROW_SHARES_UINT256));
    }

    function getTotalBorrowAssetsKey(uint256 rate) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(rate, TOTAL_BORROW_ASSETS_UINT256));
    }

    function getUserBorrowSharesKey(uint256 rate, address user) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(rate, user, USER_BORROW_SHARES_UINT256));
    }

    function getUserCollateralKey(uint256 rate, address user) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(rate, user, USER_COLLATERAL_UINT256));
    }

    function getUserBorrowAssetsKey(uint256 rate, address user) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(rate, user, USER_BORROW_ASSETS_UINT256));
    }

    function getBondTokenAddressKey(uint256 rate) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(rate, BOND_TOKEN_ADDRESS));
    }

    function getLastAccrueKey(uint256 rate) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(rate, LAST_ACCRUE_UINT256));
    }
}
