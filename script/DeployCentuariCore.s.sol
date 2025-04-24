//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseScript} from "./BaseScript.s.sol";
import {console2} from "forge-std/Script.sol";
import {Centuari} from "../src/core/Centuari.sol";
import {CentuariCLOB} from "../src/core/CentuariCLOB.sol";
import {CentuariPrime} from "../src/core/CentuariPrime.sol";
import {MockToken} from "../src/mocks/MockToken.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";
import {MarketConfig, VaultConfig} from "../src/types/CommonTypes.sol";

contract DeployCentuariCore is BaseScript {
    function _deployImplementation() internal override {
        //Deploy Centuari
        Centuari centuari = new Centuari(deployer);
        console2.log("Centuari deployed at: %s", address(centuari));

        //Deploy CentuariCLOB
        CentuariCLOB centuariCLOB = new CentuariCLOB(deployer, address(centuari));
        console2.log("CentuariCLOB deployed at: %s", address(centuariCLOB));

        //Set CentuariCLOB for Centuari
        centuari.setCentuariCLOB(address(centuariCLOB));
        console2.log("Centuari set CentuariCLOB");

        //Deploy CentuariPrime
        CentuariPrime centuariPrime = new CentuariPrime(deployer, address(centuariCLOB), address(centuari));
        console2.log("CentuariPrime deployed at: %s", address(centuariPrime));

        //Deploy Mock Oracles
        MockOracle[5] memory oracles;
        MockToken musdc = MockToken(vm.envAddress("USDC"));
        MockToken[5] memory collaterals = [
            MockToken(vm.envAddress("METH")),
            MockToken(vm.envAddress("MBTC")),
            MockToken(vm.envAddress("MSOL")),
            MockToken(vm.envAddress("MLINK")),
            MockToken(vm.envAddress("MAAVE"))
        ];
        uint40[5] memory prices = [2500e6, 90000e6, 200e6, 15e6, 200e6];

        for (uint256 i = 0; i < collaterals.length; i++) {
            oracles[i] = new MockOracle(address(collaterals[i]), address(musdc));
            oracles[i].setPrice(prices[i]);
            console2.log(
                "MockOracle for %s with price %s deployed at: %s",
                collaterals[i].symbol(),
                prices[i],
                address(oracles[i])
            );
        }

        string memory deployedOracles = string.concat(
            "\n# Deployed Mock Oracles\n",
            "METH=",
            vm.toString(address(oracles[0])),
            "\n",
            "MBTC=",
            vm.toString(address(oracles[1])),
            "\n",
            "MSOL=",
            vm.toString(address(oracles[2])),
            "\n",
            "MLINK=",
            vm.toString(address(oracles[3])),
            "\n",
            "MAAVE=",
            vm.toString(address(oracles[4])),
            "\n"
        );
        vm.writeFile(".env", string.concat(vm.readFile(".env"), deployedOracles));

        //Create Market for CLOB and Centuari
        for (uint256 i = 0; i < collaterals.length; i++) {
            MarketConfig memory marketConfig = MarketConfig({
                loanToken: address(musdc),
                collateralToken: address(collaterals[i]),
                maturity: 1776948836
            });
            centuariCLOB.createDataStore(marketConfig);
            centuari.setLltv(marketConfig, 90e16);
            centuari.setOracle(marketConfig, address(oracles[i]));
        }

        //Create Vault for Centuari Prime
        for (uint256 i = 0; i < collaterals.length; i++) {
            centuariPrime.createVault(VaultConfig({
                curator: deployer,
                token: address(collaterals[i]),
                name: string.concat("Vault ", collaterals[i].symbol())
            }));
        }

        string memory deployedCentuariCore = string.concat(
            "\n# Deployed Centuari Core contract addresses\n",
            "CENTUARI=",
            vm.toString(address(centuari)),
            "\n",
            "CENTUARI_CLOB=",
            vm.toString(address(centuariCLOB)),
            "\n",
            "CENTUARI_PRIME=",
            vm.toString(address(centuariPrime)),
            "\n"
        );
        vm.writeFile(".env", string.concat(vm.readFile(".env"), deployedCentuariCore));
    }
}
