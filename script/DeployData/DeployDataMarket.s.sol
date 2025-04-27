// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {BaseDeployData} from "./BaseDeployData.s.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IMockOracle} from "../../src/interfaces/IMockOracle.sol";
import {CentuariCLOB} from "../../src/core/CentuariCLOB.sol";
import {MockToken} from "../../src/mocks/MockToken.sol";
import {MarketConfig, Side} from "../../src/types/CommonTypes.sol";
import {MarketConfigLib} from "../../src/libraries/MarketConfigLib.sol";

contract DeployDataMarket is BaseDeployData {
    using MarketConfigLib for MarketConfig;

    function _deployImplementation() internal override {
        console2.log(unicode"\n📊 Starting Market Data Generation");
        // Create Market for CLOB and Centuari
        for (uint256 i = 0; i < collaterals.length; i++) {
            for (uint256 j = 0; j < maturities.length; j++) {
                MarketConfig memory marketConfig = MarketConfig({
                    loanToken: address(musdc),
                    collateralToken: address(collaterals[i]),
                    maturity: maturities[j]
                });
                centuariCLOB.createDataStore(marketConfig);
                centuari.setLltv(marketConfig, 90e16);
                centuari.setOracle(marketConfig, address(oracles[i]));
            }
        }
        console2.log(unicode"\n✅ Mock Market Data Generation Complete!");
    }
}