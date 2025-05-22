// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Common types used across multiple contracts
type Id is bytes32;

struct MarketConfig {
    address loanToken;
    address collateralToken;
    address oracle;
}

struct VaultMarketSupplyConfig {
    MarketConfig marketConfig;
    uint256 rate;
    uint256 cap;
}

struct VaultMarketWithdrawConfig {
    MarketConfig marketConfig;
    uint256 rate;
}

struct VaultConfig {
    address curator;
    address token;
    string name;
}

struct Order {
    uint256 id;
    address trader;
    uint256 rate;
    Side side;
    uint256 groupId;
}

struct MatchedOrder {
    uint256 id;
    address trader;
    uint256 amount;
    uint256 collateralAmount;
}

enum Side {
    LEND,
    BORROW
}

enum OrderStatus {
    OPEN, // Order is active and available for matching
    PARTIALLY_FILLED, // Order is partially matched but still active
    FILLED, // Order is completely matched
    CANCELLED, // Order was cancelled by the trader
    EXPIRED // Order has expired (reserved for future use)

}
