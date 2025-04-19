// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title ICentuariCLOB - Interface for the CentuariCLOB contract
/// @notice Manages centuariCLOB and borrowing orders with rate-time priority matching
/// @dev Implements a two-sided order book where LEND and BORROW
interface ICentuariCLOB {
    /// @notice Represents the current state of an order
    /// @dev Used to track order lifecycle and matching status
    enum Status {
        OPEN, // Order is active and available for matching
        PARTIALLY_FILLED, // Order is partially matched but still active
        FILLED, // Order is completely matched
        CANCELLED, // Order was cancelled by the trader
        EXPIRED // Order has expired (reserved for future use)

    }

    /// @notice Represents the side of an order
    /// @dev LEND represents lenders, BORROW represents borrowers
    enum Side {
        LEND, // Lender providing debt token
        BORROW // Borrower providing collateral token and amount to borrow

    }

    /// @notice Detailed information about an order in the book
    /// @dev Stores all relevant information for order matching and management
    struct Order {
        uint256 id; // Unique identifier for the order
        address trader; // Address that placed the order
        uint256 amount; // Amount of tokens (loanToken for LEND, borrowed amount for BORROW)
        uint256 collateralAmount; // Amount of collateral (only for BORROW orders)
        uint256 rate; // Interest rate in basis points (e.g., 500 = 5%)
        Side side; // LEND or BORROW
        Status status; // Current state of the order
    }

    /// @notice Information about matched orders
    /// @dev Used to return matching results and track partial fills
    struct MatchedInfo {
        uint256 orderId; // ID of the matched order
        address trader; // Address of the trader
        uint256 matchAmount; // Matched order amount
        uint256 matchCollateralAmount; // Matched collateral amount
        Side side; // Order side
        Status status; // Final status after matching
    }

    /// @notice Thrown when a trader has insufficient balance
    error InsufficientBalance(address trader, address token, uint256 balance, uint256 amount);
    /// @notice Thrown when an order is not found
    error OrderNotFound();

    /// @notice Emitted when a new order is placed in the book
    event OrderPlaced(
        uint256 orderId,
        address indexed trader,
        uint256 amount,
        uint256 collateralAmount,
        uint256 rate,
        Side side,
        Status status
    );

    /// @notice Emitted when tokens are deposited into escrow
    event Deposit(address indexed trader, uint256 amount, Side side);

    /// @notice Emitted when orders are matched
    event OrderMatched(uint256 newOrderId, uint256 matchedOrderId, Status newOrderStatus, Status matchedOrderStatus);

    /// @notice Emitted when an order is removed from the queue
    event OrderRemovedFromQueue(uint256 orderId, uint256 rate, Side side);

    /// @notice Emitted when tokens are transferred between parties
    event Transfer(address indexed from, address indexed to, uint256 amount, Side side);

    /// @notice Emitted when a limit order is cancelled
    event LimitOrderCancelled(uint256 orderId, Status status);

    /// @notice Places a new order in the book
    /// @dev Handles both lending and borrowing orders
    /// @param trader Address of the trader placing the order
    /// @param amount Amount of tokens to lend/borrow
    /// @param collateralAmount Amount of collateral (for BORROW orders)
    /// @param rate Interest rate in basis points
    /// @param side LEND or BORROW
    /// @return matchedLendOrders Array of matched lending orders
    /// @return matchedBorrowOrders Array of matched borrowing orders
    function placeOrder(address trader, uint256 amount, uint256 collateralAmount, uint256 rate, Side side)
        external
        returns (MatchedInfo[] memory matchedLendOrders, MatchedInfo[] memory matchedBorrowOrders);

    /// @notice Cancels an open order
    /// @dev Refunds escrowed tokens and updates order status
    /// @param trader Address of the trader who placed the order
    /// @param orderId ID of the order to cancel
    function cancelOrder(address trader, uint256 orderId) external;

    /// @notice Gets all orders placed by a trader
    /// @param trader Address of the trader
    /// @return Array of orders placed by the trader
    function getUserOrders(address trader) external view returns (Order[] memory);
}
