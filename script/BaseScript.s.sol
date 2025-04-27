// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";

abstract contract BaseScript is Script {
    // Common configuration variables
    address deployer;
    uint256 deployerKey;
    string rpcUrl;

    // Setup method to run before each deployment
    function setUp() public virtual {
        // Load private key from environment
        deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployer = vm.addr(deployerKey);

        //RPC URL
        rpcUrl = vm.envString("RPC_URL");
        vm.createSelectFork(rpcUrl);

        // Log deployment info
        console2.log("Deploying from:", deployer);
    }

    // This is the function that child contracts will override to implement deployment logic
    function _deployImplementation() internal virtual;

    // Common deployment logic using the template method pattern
    function _deploy() internal {
        // Pre-deployment setup
        vm.startBroadcast(deployerKey);

        // Call the child's implementation
        _deployImplementation();

        // Post-deployment cleanup
        vm.stopBroadcast();
    }

    // Main entry point that child scripts will inherit
    function run() public virtual {
        setUp();
        _deploy();
    }
}
