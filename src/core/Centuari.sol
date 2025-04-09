// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ErrorsLib} from "../libraries/ErrorsLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Centuari is Ownable {
    mapping(MarketConfig => address) public dataStore;

    constructor(address owner_) Ownable(owner_) {}

    function createDataStore(MarketConfig config) external onlyOwner {
        //TODO: Add Logic
    }

    function setDataStore(MarketConfig config, address dataStore) external onlyOwner {
        //TODO: Add Logic
    }

    function setLltv(uint256 lltv_) external override {
        //TODO: Add Logic
    }

    function isHealthy(address user) external view returns (bool) {
        //TODO: Add Logic
        return true;
    }

    function addBorrowRate(uint256 borrowRate_) external override {
        //TODO: Add Logic
    }

    function supply(uint256 borrowRate, address user, uint256 amount) external override {
        //TODO: Add Logic
    }

    function borrow(uint256 borrowRate, address user, uint256 amount) external override {
        //TODO: Add Logic
    }

    function withdraw(uint256 borrowRate, uint256 shares) external override {
        //TODO: Add Logic
    }

    function supplyCollateral(uint256 borrowRate, address user, uint256 amount) external override {
        //TODO: Add Logic
    }

    function withdrawCollateral(uint256 borrowRate, uint256 amount) external override {
        //TODO: Add Logic
    }

    function repay(uint256 borrowRate, uint256 amount) external override {
        //TODO: Add Logic
    }

    function accrueInterest(uint256 borrowRate) external override {
        //TODO: Add Logic
    }

    function getUserCollateral(uint256 borrowRate, address user) external view override returns (uint256) {
        //TODO: Add Logic
        return 0;
    }

    function getUserBorrowShares(uint256 borrowRate, address user) external view override returns (uint256) {
        //TODO: Add Logic
        return 0;
    }

    function liquidate(uint256 borrowRate, address user) external override {
        //TODO: Add Logic
    }

    function flashLoan(address token, uint256 assets, bytes calldata data) external {
        //TODO: Add Logic
    }
}
