// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { IERC20 } from "../interfaces/IERC20.sol";

import { LendingCLOBConfig,ILendingCLOB } from "../interfaces/ILendingCLOB.sol";
import { SafeTransferLib } from "../libraries/SafeTransferLibs.sol";

contract LendingCLOB is ILendingCLOB, Ownable {
    using SafeTransferLib for IERC20;
    
    LendingCLOBConfig public lendingCLOBConfig;

    /// @notice Counter for generating unique order IDs
    uint256 public orderCount;

    /// @notice Current best (lowest) lending rate available
    uint256 public bestLendRate; //TODO: Remove if not use

    /// @notice Tracks collateral balances for borrowers
    mapping(address => uint256) public collateralBalances;

    /// @notice Tracks loan token balances for lenders
    mapping(address => uint256) public loanBalances;

    /// @notice Maps traders to their orders
    mapping(address => Order[]) public traderOrders;

    /// @notice Main order book storage: rate => side => orders
    /// @dev Primary structure for order matching and rate discovery
    mapping(uint256 => mapping(Side => Order[])) public orderQueue;

    constructor(
        address _router,
        LendingCLOBConfig memory _lendingCLOBConfig
    ) Ownable(_router) {
        lendingCLOBConfig = _lendingCLOBConfig;
    }
    
    function placeOrder( 
        address trader,
        uint256 amount,
        uint256 collateralAmount,
        uint256 rate,
        Side side
    )
        external
        onlyOwner
        returns (
            MatchedInfo[] memory matchedLendOrders,
            MatchedInfo[] memory matchedBorrowOrders
        )
    {
        //TODO: Add logic
        return (matchedLendOrders, matchedBorrowOrders);
    }

    function cancelOrder(address trader, uint256 orderId) external {
        //TODO: Add logic
    }

    function transferFrom(address from, address to, uint256 amount, Side side) external {
        //TODO: Add logic
    }

    function getUserOrders(address trader) external view returns (Order[] memory) {
        //TODO: Add logic
        return traderOrders[trader];
    }

    function _removeFromQueueByIndex(
        Order[] storage queue,
        uint256 index,
        uint256 rate,
        Side side
    ) internal {
        //TODO: Add logic
    }

    /// @notice Finds the index of an order in the queue
    /// @dev Helper function for order cancellation
    /// @param orders Array of orders to search
    /// @param orderId ID of the order to find
    /// @return Index of the order, or max uint256 if not found
    function _findOrderIndex(
        Order[] storage orders,
        uint256 orderId
    ) internal view returns (uint256) {
        //TODO: Add logic
    }
}