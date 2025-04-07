// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Id } from "../types/CommonTypes.sol";
import { LendingPoolConfig} from "../interfaces/ILendingPool.sol";

library LendingPoolConfigLib {
    /// @notice The length of the data used to compute the id of a lending CLOB.
    /// @dev The length is 4 * 32 because `LendingPoolConfig` has 4 variables of 32 bytes each.
    uint256 internal constant LENDING_POOL_CONFIG_BYTES_LENGTH = 7 * 32;

    /// @notice Returns the id of the market `marketParams`.
    function id(LendingPoolConfig memory lendingPoolConfig) internal pure returns (Id lendingPoolConfigId) {
        assembly ("memory-safe") {
            lendingPoolConfigId := keccak256(lendingPoolConfig, LENDING_POOL_CONFIG_BYTES_LENGTH)
        }
    }
}