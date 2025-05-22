// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
// import {MockToken} from "../src/mocks/MockToken.sol";
// import {CentuariToken} from "../src/core/CentuariToken.sol";
// import {MockOracle} from "../src/mocks/MockOracle.sol";
// import {Centuari} from "../src/core/Centuari.sol";
// import {CentuariCLOB} from "../src/core/CentuariCLOB.sol";
// import {MarketConfig} from "../src/types/CommonTypes.sol";
// import {CentuariPrime} from "../src/core/CentuariPrime.sol";

/// @title Centuari Base Test
/// @notice Provides shared setup for unit tests across the protocol
contract BaseTest is Test {
    /// --- Common Addresses ---
    // address internal address1;
    // address internal owner;

    // /// --- CentuariToken ---
    // CentuariToken internal centuariToken;

    // /// --- Oracle ---
    // MockOracle internal mockOracle;

    // /// --- Centuari ---
    // Centuari internal centuari;

    // /// --- CentuariCLOB ---
    // CentuariCLOB internal centuariCLOB;

    // /// --- CentuariPrime ---
    // // CentuariPrime internal centuariPrime;

    // /// --- Shared Constants ---
    // uint256 internal constant RATE = 45e16;
    // uint256 internal constant MATURITY = 1715280000;
    // string internal constant MATURITY_MONTH = "MAY";
    // uint256 internal constant MATURITY_YEAR = 2025;
    // uint8 internal constant DECIMALS = 6;
    // uint256 internal constant MOCK_TIMESTAMP = 1000000;
    // uint256 internal constant LLTV = 80e16;

    // uint256[5] internal maturities;
    // MockToken[5] internal mockTokens;
    // MockToken internal mockUsdc;

    function setUp() public virtual {
        // address1 = makeAddr("address1");
        // owner = address(this);

        // mockUsdc = new MockToken("Mock USDC", "MUSDC", 6); //USDC
        // // Deploy mock tokens
        // mockTokens = [
        //     new MockToken("Mock WETH", "METH", 18), // WETH
        //     new MockToken("Mock WBTC", "MBTC", 8), // WBTC
        //     new MockToken("Mock WSOL", "MSOL", 18), // SOL
        //     new MockToken("Mock WLINK", "MLINK", 18), // LINK
        //     new MockToken("Mock WAAVE", "MAAVE", 18) // AAVE
        // ];

        // // Deploy mock oracles
        // uint40[5] memory prices = [2500e6, 90000e6, 200e6, 15e6, 200e6];
        // MockOracle[5] memory oracles;
        // for (uint256 i = 0; i < 5; i++) {
        //     oracles[i] = new MockOracle(address(mockTokens[i]), address(mockUsdc));
        //     oracles[i].setPrice(prices[i]);
        // }

        // maturities = [
        //     uint256(1751302800), // 2025-07-01 00:00:00
        //     uint256(1753981200), // 2025-08-01 00:00:00
        //     uint256(1756659600), // 2025-09-01 00:00:00
        //     uint256(1759251600), // 2025-10-01 00:00:00
        //     uint256(1761930000)  // 2025-11-01 00:00:00
        // ];  
    }
}
