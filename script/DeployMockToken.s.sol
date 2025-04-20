//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseScript} from "./BaseScript.s.sol";
import {MockToken} from "../src/mocks/MockToken.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {console2} from "forge-std/Script.sol";

contract DeployMockToken is BaseScript {
    function _deployImplementation() internal override {
        MockToken[6] memory mockTokens = [
            new MockToken("Mock USDC", "MUSDC", 6), //USDC
            new MockToken("Mock WETH", "MWETH", 18), // WETH
            new MockToken("Mock WBTC", "MWBTC", 8), // WBTC
            new MockToken("Mock WSOL", "MWSOL", 18), // SOL
            new MockToken("Mock WLINK", "MWLINK", 18), // LINK
            new MockToken("Mock WAAVE", "MWAAVE", 18) // AAVE
        ];

        for (uint256 i = 0; i < mockTokens.length; i++) {
            console2.log("%s deployed at: %s", IERC20Metadata(address(mockTokens[i])).symbol(), address(mockTokens[i]));
        }

        string memory deployedMockTokens = string.concat(
            "\n# Deployed Mock Token contract addresses\n",
            "USDC=",
            vm.toString(address(mockTokens[0])),
            "\n",
            "METH=",
            vm.toString(address(mockTokens[1])),
            "\n",
            "MBTC=",
            vm.toString(address(mockTokens[2])),
            "\n",
            "MSOL=",
            vm.toString(address(mockTokens[3])),
            "\n",
            "MLINK=",
            vm.toString(address(mockTokens[4])),
            "\n",
            "MAAVE=",
            vm.toString(address(mockTokens[5])),
            "\n"
        );

        vm.writeFile(".env", string.concat(vm.readFile(".env"), deployedMockTokens));
    }
}
