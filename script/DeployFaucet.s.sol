//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseScript} from "./BaseScript.s.sol";
import {FaucetMockToken} from "../src/mocks/FaucetMockToken.sol";
import {MockToken} from "../src/mocks/MockToken.sol";
import {console2} from "forge-std/Script.sol";

contract DeployFaucet is BaseScript {
    function _deployImplementation() internal override {
        MockToken[6] memory mockTokens = [
            MockToken(vm.envAddress("USDC")),
            MockToken(vm.envAddress("WETH")),
            MockToken(vm.envAddress("WBTC")),
            MockToken(vm.envAddress("WSOL")),
            MockToken(vm.envAddress("WLINK")),
            MockToken(vm.envAddress("WAAVE"))
        ];
        
        FaucetMockToken faucetMockToken = new FaucetMockToken(mockTokens);
        console2.log("Faucet deployed at: %s", address(faucetMockToken));

        string memory deployedFaucet = string.concat(
            "\n# Deployed Faucet Mock Token contract addresses\n",
            "FAUCET=", vm.toString(address(faucetMockToken)), "\n"
        );

        vm.writeFile(".env", string.concat(vm.readFile(".env"), deployedFaucet));
    }
}
