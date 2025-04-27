// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/Script.sol";
import {CentuariPrime} from "../../src/core/CentuariPrime.sol";
import {DataStore} from "../../src/core/DataStore.sol";
import {BaseDeployData} from "../DeployData/BaseDeployData.s.sol";
import {MockToken} from "../../src/mocks/MockToken.sol";
import {VaultConfig, VaultMarketSupplyConfig, VaultMarketWithdrawConfig, MarketConfig} from "../../src/types/CommonTypes.sol";

contract DeployDataCentuariPrime is BaseDeployData {
    function _deployImplementation() internal override {
        console2.log(unicode"\n📊 Starting Centuari Prime Data Generation");

        //Create Vault for Centuari Prime
        for (uint256 i = 0; i < 5; i++) {
            centuariPrime.createVault(VaultConfig({
                curator: deployer,
                token: address(musdc),
                name: string.concat("Vault ", musdc.symbol(), " ", vm.toString(i+1))
            }));
        }

        // Set the supply queue for each vault
        for (uint256 i = 0; i < 5; i++) {
            VaultMarketSupplyConfig[] memory supplyQueue = new VaultMarketSupplyConfig[](5);
            VaultMarketWithdrawConfig[] memory withdrawQueue = new VaultMarketWithdrawConfig[](5);
            for (uint256 j = 0; j < 5; j++) {
                uint256 rate_ = (j+1) * 1e16;
                supplyQueue[j] = VaultMarketSupplyConfig({
                    marketConfig: MarketConfig({
                        loanToken: address(musdc),
                        collateralToken: address(collaterals[j]),
                        maturity: maturities[0]
                    }),
                    rate: rate_,
                    cap: 1000000e6
                });

                withdrawQueue[j] = VaultMarketWithdrawConfig({
                    marketConfig: MarketConfig({
                        loanToken: address(musdc),
                        collateralToken: address(collaterals[j]),
                        maturity: maturities[0]
                    }),
                    rate: rate_
                });
            }

            centuariPrime.setSupplyQueue(VaultConfig({
                curator: deployer,
                token: address(musdc),
                name: string.concat("Vault ", musdc.symbol(), " ", vm.toString(i+1))
            }), supplyQueue);

            centuariPrime.setWithdrawQueue(VaultConfig({
                curator: deployer,
                token: address(musdc),
                name: string.concat("Vault ", musdc.symbol(), " ", vm.toString(i+1))
            }), withdrawQueue);
        }
        vm.stopBroadcast(); //Stop broadcast for deployer

        vm.startBroadcast(lenderKey); //Start broadcast for lender
        // Deposit to each vault
        for (uint256 i = 0; i < 5; i++) {
            musdc.approve(address(centuariPrime), 2000e6);
            centuariPrime.deposit(VaultConfig({
                curator: deployer,
                token: address(musdc),
                name: string.concat("Vault ", musdc.symbol(), " ", vm.toString(i+1))
            }), 2000e6); 
        }
        console2.log(unicode"\n✅ Centuari Prime Data Generation Complete!");
    }
}