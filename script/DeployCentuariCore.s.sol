//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseScript} from "./BaseScript.s.sol";
import {console2} from "forge-std/Script.sol";
import {Centuari} from "../src/core/Centuari.sol";
import {CentuariCLOB} from "../src/core/CentuariCLOB.sol";
import {CentuariPrime} from "../src/core/CentuariPrime.sol";
import {MockToken} from "../src/mocks/MockToken.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";

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
            MockToken(vm.envAddress("WETH")),
            MockToken(vm.envAddress("WBTC")),
            MockToken(vm.envAddress("WSOL")),
            MockToken(vm.envAddress("WLINK")),
            MockToken(vm.envAddress("WAAVE"))
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
            "WETH=",
            vm.toString(address(oracles[0])),
            "\n",
            "WBTC=",
            vm.toString(address(oracles[1])),
            "\n",
            "WSOL=",
            vm.toString(address(oracles[2])),
            "\n",
            "WLINK=",
            vm.toString(address(oracles[3])),
            "\n",
            "WAAVE=",
            vm.toString(address(oracles[4])),
            "\n"
        );
        vm.writeFile(".env", string.concat(vm.readFile(".env"), deployedOracles));

        //@todo Create Market for CLOB and Centuari

        //@todo Create Vault for Centuari Prime

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
