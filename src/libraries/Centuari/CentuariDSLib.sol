// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IDataStore} from "../../interfaces/IDataStore.sol";

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

    function getTotalSupplyShares(IDataStore dataStore, uint256 rate) internal view returns (uint256) {
        return dataStore.getUint(keccak256(abi.encodePacked(rate, TOTAL_SUPPLY_SHARES_UINT256)));
    }

    function setTotalSupplyShares(IDataStore dataStore, uint256 rate, uint256 value) internal {
        dataStore.setUint(keccak256(abi.encodePacked(rate, TOTAL_SUPPLY_SHARES_UINT256)), value);
    }

    function getTotalSupplyAssets(IDataStore dataStore, uint256 rate) internal view returns (uint256) {
        return dataStore.getUint(keccak256(abi.encodePacked(rate, TOTAL_SUPPLY_ASSETS_UINT256)));
    }

    function setTotalSupplyAssets(IDataStore dataStore, uint256 rate, uint256 value) internal {
        dataStore.setUint(keccak256(abi.encodePacked(rate, TOTAL_SUPPLY_ASSETS_UINT256)), value);
    }

    function getTotalBorrowShares(IDataStore dataStore, uint256 rate) internal view returns (uint256) {
        return dataStore.getUint(keccak256(abi.encodePacked(rate, TOTAL_BORROW_SHARES_UINT256)));
    }

    function setTotalBorrowShares(IDataStore dataStore, uint256 rate, uint256 value) internal {
        dataStore.setUint(keccak256(abi.encodePacked(rate, TOTAL_BORROW_SHARES_UINT256)), value);
    }

    function getTotalBorrowAssets(IDataStore dataStore, uint256 rate) internal view returns (uint256) {
        return dataStore.getUint(keccak256(abi.encodePacked(rate, TOTAL_BORROW_ASSETS_UINT256)));
    }

    function setTotalBorrowAssets(IDataStore dataStore, uint256 rate, uint256 value) internal {
        dataStore.setUint(keccak256(abi.encodePacked(rate, TOTAL_BORROW_ASSETS_UINT256)), value);
    }

    function getUserBorrowShares(IDataStore dataStore, uint256 rate, address user) internal view returns (uint256) {
        return dataStore.getUint(keccak256(abi.encodePacked(rate, user, USER_BORROW_SHARES_UINT256)));
    }

    function setUserBorrowShares(IDataStore dataStore, uint256 rate, address user, uint256 value) internal {
        dataStore.setUint(keccak256(abi.encodePacked(rate, user, USER_BORROW_SHARES_UINT256)), value);
    }

    function getUserCollateral(IDataStore dataStore, uint256 rate, address user) internal view returns (uint256) {
        return dataStore.getUint(keccak256(abi.encodePacked(rate, user, USER_COLLATERAL_UINT256)));
    }

    function setUserCollateral(IDataStore dataStore, uint256 rate, address user, uint256 value) internal {
        dataStore.setUint(keccak256(abi.encodePacked(rate, user, USER_COLLATERAL_UINT256)), value);
    }

    function getUserBorrowAssets(IDataStore dataStore, uint256 rate, address user) internal view returns (uint256) {
        return dataStore.getUint(keccak256(abi.encodePacked(rate, user, USER_BORROW_ASSETS_UINT256)));
    }

    function setUserBorrowAssets(IDataStore dataStore, uint256 rate, address user, uint256 value) internal {
        dataStore.setUint(keccak256(abi.encodePacked(rate, user, USER_BORROW_ASSETS_UINT256)), value);
    }

    function getBondTokenAddress(IDataStore dataStore, uint256 rate) internal view returns (address) {
        return dataStore.getAddress(keccak256(abi.encodePacked(rate, BOND_TOKEN_ADDRESS)));
    }

    function setBondTokenAddress(IDataStore dataStore, uint256 rate, address value) internal {
        dataStore.setAddress(keccak256(abi.encodePacked(rate, BOND_TOKEN_ADDRESS)), value);
    }

    function getLastAccrue(IDataStore dataStore, uint256 rate) internal view returns (uint256) {
        return dataStore.getUint(keccak256(abi.encodePacked(rate, LAST_ACCRUE_UINT256)));
    }

    function setLastAccrue(IDataStore dataStore, uint256 rate, uint256 value) internal {
        dataStore.setUint(keccak256(abi.encodePacked(rate, LAST_ACCRUE_UINT256)), value);
    }
}
