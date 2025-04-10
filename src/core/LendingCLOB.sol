// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Id, MarketConfig} from "../types/CommonTypes.sol";
import {MarketConfigLib} from "../libraries/MarketConfigLib.sol";

contract LendingCLOB is Ownable {
    using MarketConfigLib for MarketConfig;

    mapping(Id => address) public dataStores;
    address public centuari;

    constructor(address owner_, address centuari_) Ownable(owner_) {
        centuari = centuari_;
    }

    function createClob(MarketConfig config) external onlyOwner {
        //TODO: Add logic + Create Datastore
        //Add DataStore to mapping DataStoreConfig
        //Call Centuari.createDataStore
    }

    function setDataStore(MarketConfig config, address dataStore) external onlyOwner {
        //TODO: Add logic
    }

    function placeOrder(address trader, uint256 amount, uint256 collateralAmount, uint256 rate, Side side)
        external
        onlyOwner
        returns (MatchedInfo[] memory matchedLendOrders, MatchedInfo[] memory matchedBorrowOrders)
    {
        //TODO: Add logic
        return (matchedLendOrders, matchedBorrowOrders);
    }

    function cancelOrder(address trader, uint256 orderId) external {
        //TODO: Add logic
    }

    function getUserOrders(address trader) external view returns (Order[] memory) {
        //TODO: Add logic
        return traderOrders[trader];
    }

    function _removeFromQueueByIndex(Order[] storage queue, uint256 index, uint256 rate, Side side) internal {
        //TODO: Add logic
    }

    /// @notice Finds the index of an order in the queue
    /// @dev Helper function for order cancellation
    /// @param orders Array of orders to search
    /// @param orderId ID of the order to find
    /// @return Index of the order, or max uint256 if not found
    function _findOrderIndex(Order[] storage orders, uint256 orderId) internal view returns (uint256) {
        //TODO: Add logic
    }
}
