// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MarketConfig, Side} from "../types/CommonTypes.sol";

/// @title ICentuariCLOB - Interface for the CentuariCLOB contract
/// @notice Manages centuariCLOB and borrowing orders with rate-time priority matching
/// @dev Implements a two-sided order book where LEND and BORROW
interface ICentuariCLOB {
    function placeOrder(MarketConfig calldata config, uint256 amount, uint256 collateralAmount, uint256 rate, Side side)
        external;
    function cancelOrder(MarketConfig calldata config, uint256 orderId) external;
}
