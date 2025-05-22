// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {RedBlackTreeLib} from "@solady/utils/RedBlackTreeLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DataStore} from "./DataStore.sol";
import {MarketConfigLib} from "../libraries/MarketConfigLib.sol";
import {Id, Side, MarketConfig, Order, OrderStatus} from "../types/CommonTypes.sol";
import {CentuariCLOBDSLib} from "../libraries/centuari-clob/CentuariCLOBDSLib.sol";
import {CentuariDSLib} from "../libraries/centuari/CentuariDSLib.sol";
import {OrderQueueLib} from "../libraries/centuari-clob/OrderQueueLib.sol";

contract CentuariCLOBMarket is Ownable {
    using MarketConfigLib for MarketConfig;
    using RedBlackTreeLib for RedBlackTreeLib.Tree;

    RedBlackTreeLib.Tree private rateTree;

    DataStore public dataStore;

    constructor(address owner_, MarketConfig memory config, uint256 maturity) Ownable(owner_) {
        dataStore = new DataStore(owner_, address(this));
        dataStore.setAddress(CentuariDSLib.LOAN_TOKEN_ADDRESS, config.loanToken);
        dataStore.setAddress(CentuariDSLib.COLLATERAL_TOKEN_ADDRESS, config.collateralToken);
        dataStore.setUint(CentuariDSLib.MATURITY_UINT256, maturity);
        dataStore.setBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL, true);
    }

    /**
     * @dev Returns a view of the rate tree, for read-only operations
     */
    function getMarketRateTree() external view returns (RedBlackTreeLib.Tree memory) {
        return rateTree;
    }

    /**
     * @dev Returns the market datastore address
     */
    function getMarketDataStore() external view returns (address) {
        return address(dataStore);
    }
    
    /**
     * @dev Adds a rate to the rate tree
     * @param rate The rate to add
     * @return success Whether the rate was added successfully
     */
    function addRateToTree(uint256 rate) external onlyOwner returns (bool success) {
        if (!rateTree.exists(rate)) {
            rateTree.insert(rate);
            return true;
        }
        return false;
    }
    
    /**
     * @dev Removes a rate from the rate tree
     * @param rate The rate to remove
     * @return success Whether the rate was removed successfully
     */
    function removeRateFromTree(uint256 rate) external onlyOwner returns (bool success) {
        if (rateTree.exists(rate)) {
            rateTree.remove(rate);
            return true;
        }
        return false;
    }
    
    /**
     * @dev Checks if a rate exists in the tree
     * @param rate The rate to check
     * @return exists Whether the rate exists
     */
    function rateExists(uint256 rate) external view returns (bool) {
        return rateTree.exists(rate);
    }
}