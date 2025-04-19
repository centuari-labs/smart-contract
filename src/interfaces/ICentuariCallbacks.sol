// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ICentuariFlashLoanCallback {
    function onCentuariFlashLoan(address token, uint256 amount, bytes calldata data) external;
}
