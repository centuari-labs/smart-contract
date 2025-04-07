// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICentuari {
    function deposit(address token, uint256 amount) external;
    function withdraw(address token, uint256 amount) external;
    function flashLoan(address token, uint256 assets, bytes calldata data) external;
}