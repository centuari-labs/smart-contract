// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Id, VaultConfig} from "../types/CommonTypes.sol";

library VaultConfigLib {
    function id(VaultConfig memory vaultConfig) internal pure returns (Id vaultConfigId) {
        vaultConfigId = Id.wrap(
            keccak256(abi.encodePacked(vaultConfig.curator, vaultConfig.token, vaultConfig.name))
        );
    }
}
