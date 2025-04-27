// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {Centuari} from "../../src/core/Centuari.sol";
import {CentuariCLOB} from "../../src/core/CentuariCLOB.sol";
import {CentuariPrime} from "../../src/core/CentuariPrime.sol";
import {MockToken} from "../../src/mocks/MockToken.sol";
import {MockOracle} from "../../src/mocks/MockOracle.sol";

abstract contract BaseDeployData is Script {
    // Common configuration variables
    uint256 deployerKey;
    address deployer;
    string rpcUrl;
    
    // Contract addresses
    uint256 lenderKey;
    uint256 borrowerKey;
    address lender;
    address borrower;
    Centuari centuari;
    CentuariCLOB centuariCLOB;
    CentuariPrime centuariPrime;
    MockToken musdc;
    
    // Collateral and market data
    MockToken[5] collaterals;
    uint256[5] baseRates;
    uint256[5] collateralAmounts;
    MockOracle[5] oracles;
    uint256[5] collateralPrices;
    uint256[5] maturities;

    // Setup method to run before each deployment
    function setUp() public virtual {
        // Load private key from environment
        deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployer = vm.addr(deployerKey);

        //RPC URL
        rpcUrl = vm.envString("RPC_URL");
        vm.createSelectFork(rpcUrl);

        // Contract addresses
        lenderKey = vm.envUint("LENDER_PRIVATE_KEY");
        borrowerKey = vm.envUint("BORROWER_PRIVATE_KEY");
        lender = vm.addr(lenderKey);
        borrower = vm.addr(borrowerKey);
        centuari = Centuari(vm.envAddress("CENTUARI"));
        centuariCLOB = CentuariCLOB(vm.envAddress("CENTUARI_CLOB"));
        centuariPrime = CentuariPrime(vm.envAddress("CENTUARI_PRIME"));
        musdc = MockToken(vm.envAddress("MUSDC"));

        // Collateral and market data
        collaterals = [
            MockToken(vm.envAddress("METH")),  // WETH - lowest rate
            MockToken(vm.envAddress("MBTC")),  // WBTC - second lowest
            MockToken(vm.envAddress("MSOL")),  // SOL - medium rate
            MockToken(vm.envAddress("MLINK")), // LINK - second highest
            MockToken(vm.envAddress("MAAVE"))  // AAVE - highest rate
        ];
        baseRates = [
            uint256(3e16),   // 3% for ETH
            uint256(3.5e16), // 3.5% for BTC
            uint256(5e16),   // 5% for SOL
            uint256(5.5e16), // 5.5% for LINK
            uint256(6e16)    // 6% for AAVE
        ];
        collateralAmounts = [
            uint256(100e18),    // WETH (1 ETH = 2500 USDC)
            uint256(100e8),     // WBTC (1 BTC = 90000 USDC)
            uint256(1000e18),   // SOL (1 SOL = 200 USDC)
            uint256(10_000e18), // LINK (1 LINK = 15 USDC)
            uint256(1000e18)    // AAVE (1 AAVE = 200 USDC)
        ];
        oracles = [
            MockOracle(vm.envAddress("METH_ORACLE")),
            MockOracle(vm.envAddress("MBTC_ORACLE")),
            MockOracle(vm.envAddress("MSOL_ORACLE")),
            MockOracle(vm.envAddress("MLINK_ORACLE")),
            MockOracle(vm.envAddress("MAAVE_ORACLE"))
        ];
        collateralPrices = [
            oracles[0].price(),  // ETH price in USDC
            oracles[1].price(),  // BTC price in USDC
            oracles[2].price(),  // SOL price in USDC
            oracles[3].price(), // LINK price in USDC
            oracles[4].price()  // AAVE price in USDC
        ];
        maturities = [
            uint256(1751302800), // 2025-07-01 00:00:00
            uint256(1753981200), // 2025-08-01 00:00:00
            uint256(1756659600), // 2025-09-01 00:00:00
            uint256(1759251600), // 2025-10-01 00:00:00
            uint256(1761930000)  // 2025-11-01 00:00:00
        ];

        // Log deployment info
        console2.log("Deploying from:", deployer);
    }

    // Main entry point that child scripts will inherit
    function run() public virtual {
        setUp();
        _deploy();
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
}
