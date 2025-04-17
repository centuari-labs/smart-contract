// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Id, VaultMarketConfig} from "../types/CommonTypes.sol";

library VaultMarketConfigLib {
    function id(VaultMarketConfig memory vaultMarketConfig) internal pure returns (Id vaultMarketConfigId) {
        vaultMarketConfigId = Id.wrap(
            keccak256(
                abi.encodePacked(
                    vaultMarketConfig.marketConfig.loanToken, 
                    vaultMarketConfig.marketConfig.collateralToken, 
                    vaultMarketConfig.marketConfig.maturity,
                    vaultMarketConfig.rate,
                    vaultMarketConfig.cap
                )
            )
        );
    }
}