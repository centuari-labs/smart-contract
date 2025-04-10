// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MarketConfig} from "../types/CommonTypes.sol";

interface ICentuari {
    function supply(MarketConfig memory config, int256 borrowRate, address user, uint256 amount) external;
    function withdraw(MarketConfig memory config, address user, uint256 amount) external;
    function flashLoan(MarketConfig memory config, address token, uint256 assets, bytes calldata data) external;
}
