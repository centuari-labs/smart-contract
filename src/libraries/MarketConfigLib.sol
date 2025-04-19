// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Id, MarketConfig} from "../types/CommonTypes.sol";

library MarketConfigLib {
    function id(MarketConfig memory marketConfig) internal pure returns (Id marketConfigId) {
        marketConfigId = Id.wrap(
            keccak256(abi.encodePacked(marketConfig.loanToken, marketConfig.collateralToken, marketConfig.maturity))
        );
    }
}
