// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Id } from "../types/CommonTypes.sol";
import { LendingCLOBConfig} from "../interfaces/ILendingCLOB.sol";

library LendingCLOBConfigLib {
    /// @notice The length of the data used to compute the id of a lending CLOB.
    /// @dev The length is 4 * 32 because `LendingCLOBConfig` has 4 variables of 32 bytes each.
    uint256 internal constant LENDING_CLOB_CONFIG_BYTES_LENGTH = 4 * 32;

    /// @notice Returns the id of the market `marketParams`.
    function id(LendingCLOBConfig memory lendingCLOBConfig) internal pure returns (Id lendingCLOBConfigId) {
        assembly ("memory-safe") {
            lendingCLOBConfigId := keccak256(lendingCLOBConfig, LENDING_CLOB_CONFIG_BYTES_LENGTH)
        }
    }
}