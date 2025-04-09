// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Id, MarketConfig} from "../types/CommonTypes.sol";

library MarketConfigLib {
    /// @notice The length of the data used to compute the id of a lending CLOB.
    /// @dev The length is 4 * 32 because `LendingCLOBConfig` has 4 variables of 32 bytes each.
    uint256 internal constant MARKET_CONFIG_BYTES_LENGTH = 4 * 32;

    /// @notice Returns the id of the market `marketParams`.
    function id(MarketConfig memory marketConfig) internal pure returns (Id marketConfigId) {
        assembly ("memory-safe") {
            marketConfigId := keccak256(marketConfig, MARKET_CONFIG_BYTES_LENGTH)
        }
    }
}
