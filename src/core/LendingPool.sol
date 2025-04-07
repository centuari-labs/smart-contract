// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LendingPoolConfig,ILendingPool } from "../interfaces/ILendingPool.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
contract LendingPool is ILendingPool, Ownable {
    address public router;
    /// @notice The lending pool's configuration information
    LendingPoolConfig public config;

    constructor(
        address owner_,
        address router_,
        LendingPoolConfig memory config_
    ) Ownable(owner_) {
        if (router_ == address(0)) revert InvalidRouter();
        if (
            config_.loanToken == address(0) ||
            config_.collateralToken == address(0) ||
            config_.oracle == address(0) ||
            config_.maturity <= block.timestamp ||
            bytes(config_.maturityMonth).length == 0 ||
            config_.maturityYear == 0 ||
            config_.lltv == 0
        ) revert InvalidLendingPoolInfo();
        router = router_;
        config = config_;
    }

    function setRouter(address router_) external override {
        //TODO: Add Logic
    }

    function setLltv(uint256 lltv_) external override {
        //TODO: Add Logic
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
    
    function supplyCollateral(
        uint256 borrowRate,
        address user,
        uint256 amount
    ) external override {
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
    
    function getUserCollateral(
        uint256 borrowRate,
        address user
    ) external view override returns (uint256) {
        //TODO: Add Logic
        return 0;
    }
    
    function getUserBorrowShares(
        uint256 borrowRate,
        address user
    ) external view override returns (uint256) {
        //TODO: Add Logic
        return 0;
    }
    
    function liquidate(uint256 borrowRate, address user) external override {
        //TODO: Add Logic
    }
}