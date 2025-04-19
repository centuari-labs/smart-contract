// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MarketConfig} from "../types/CommonTypes.sol";

interface ICentuari {
    function createDataStore(MarketConfig memory config) external;
    function setDataStore(MarketConfig memory config, address dataStore) external;
    function getDataStore(MarketConfig memory config) external view returns (address);
    function setLltv(MarketConfig memory config, uint256 lltv) external;
    function setOracle(MarketConfig memory config, address oracle) external;
    function accrueInterest(MarketConfig memory config, uint256 rate) external;
    function addRate(MarketConfig memory config, uint256 rate) external;
    function supply(MarketConfig memory config, uint256 rate, address user, uint256 amount) external;
    function withdraw(MarketConfig memory config, uint256 rate, uint256 shares) external;
    function supplyCollateral(MarketConfig memory config, uint256 rate, address user, uint256 amount) external;
    function withdrawCollateral(MarketConfig memory config, uint256 rate, uint256 amount) external;
    function repay(MarketConfig memory config, uint256 rate, uint256 amount) external;
    function liquidate(MarketConfig memory config, uint256 rate, address user) external;
    function getUserCollateral(MarketConfig memory config, uint256 rate, address user) external view returns (uint256);
    function getUserBorrowShares(MarketConfig memory config, uint256 rate, address user) external view returns (uint256);
}
