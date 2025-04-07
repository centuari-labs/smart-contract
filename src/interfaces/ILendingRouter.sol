// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ILendingRouter - Interface for LendingRouter
/// @notice Provides an interface for other contracts to interact with Centuari through the router
interface ILendingRouter {  

    function depositCLOB(address token, uint256 amount) external;

    function withdrawCLOB(address token, uint256 amount) external;

    function depositPool(address token, uint256 amount) external;

    function withdrawPool(address token, uint256 amount) external;
}
