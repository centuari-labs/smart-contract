// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/Script.sol";
import {CentuariPrime} from "../../src/core/CentuariPrime.sol";
import {DataStore} from "../../src/core/DataStore.sol";
import {BaseScript} from "../BaseScript.s.sol";
import {MockToken} from "../../src/mocks/MockToken.sol";
import {VaultConfig, VaultMarketSupplyConfig, VaultMarketWithdrawConfig, MarketConfig} from "../../src/types/CommonTypes.sol";
contract MockCentuariPrimeScript is BaseScript {
    function _deployImplementation() internal override {
        uint256 CENTUARI_PRIME_USER_PRIVATE_KEY = vm.envUint("CENTUARI_PRIME_USER_PRIVATE_KEY");

        CentuariPrime centuariPrime = CentuariPrime(vm.envAddress("CENTUARI_PRIME"));

        MockToken musdc = MockToken(vm.envAddress("USDC"));
        MockToken[5] memory collaterals = [
            MockToken(vm.envAddress("METH")),
            MockToken(vm.envAddress("MBTC")),
            MockToken(vm.envAddress("MSOL")),
            MockToken(vm.envAddress("MLINK")),
            MockToken(vm.envAddress("MAAVE"))
        ];

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
                        maturity: 1776948836
                    }),
                    rate: rate_,
                    cap: 1000000e6
                });

                withdrawQueue[j] = VaultMarketWithdrawConfig({
                    marketConfig: MarketConfig({
                        loanToken: address(musdc),
                        collateralToken: address(collaterals[j]),
                        maturity: 1776948836
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
        vm.stopBroadcast();

        vm.startBroadcast(CENTUARI_PRIME_USER_PRIVATE_KEY);
        // Deposit to each vault
        for (uint256 i = 0; i < 5; i++) {
            musdc.approve(address(centuariPrime), 2000e6);
            centuariPrime.deposit(VaultConfig({
                curator: deployer,
                token: address(musdc),
                name: string.concat("Vault ", musdc.symbol(), " ", vm.toString(i+1))
            }), 2000e6); 
        }
    }
}