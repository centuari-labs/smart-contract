// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MockToken} from "../src/mocks/MockToken.sol";
import {BondToken} from "../src/core/BondToken.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";
import {Centuari} from "../src/core/Centuari.sol";
import {LendingCLOB} from "../src/core/LendingCLOB.sol";
import {MarketConfig} from "../src/types/CommonTypes.sol";

/// @title Centuari Base Test
/// @notice Provides shared setup for unit tests across the protocol
contract BaseTest is Test {
    /// --- Common Addresses ---
    address internal address1;
    address internal owner;

    /// --- Tokens ---
    MockToken internal usdc;
    MockToken internal wbtc;
    MockToken internal weth;

    /// --- BondToken ---
    BondToken internal bondToken;

    /// --- Oracle ---
    MockOracle internal mockOracle;

    /// --- Centuari ---
    Centuari internal centuari;
    MarketConfig internal usdcWethMarketConfig;

    /// --- LendingCLOB ---
    LendingCLOB internal lendingCLOB;

    /// --- Shared Constants ---
    uint256 internal constant RATE = 45e16;
    uint256 internal constant MATURITY = 1715280000;
    string internal constant MATURITY_MONTH = "MAY";
    uint256 internal constant MATURITY_YEAR = 2025;
    uint8 internal constant DECIMALS = 6;
    uint256 internal constant MOCK_TIMESTAMP = 1000000;

    function setUp() public virtual {
        address1 = makeAddr("address1");
        owner = address(this);

        // Deploy mock tokens
        usdc = new MockToken("Mock USDC", "MUSDC", DECIMALS);
        wbtc = new MockToken("Mock WBTC", "MWBTC", 8);
        weth = new MockToken("Mock ETH", "METH", 18);

        // Deploy mock oracle
        mockOracle = new MockOracle(address(usdc), address(weth));

        // Deploy BondToken
        BondToken.BondTokenConfig memory config = BondToken.BondTokenConfig({
            loanToken: address(usdc),
            collateralToken: address(weth),
            rate: RATE,
            maturity: MATURITY,
            maturityMonth: MATURITY_MONTH,
            maturityYear: MATURITY_YEAR,
            decimals:usdc.decimals()
        });

        bondToken = new BondToken(address(this), config);

        //Deploy Centuari
        centuari = new Centuari(address(this));
        usdcWethMarketConfig = MarketConfig({
            loanToken: address(usdc),
            collateralToken: address(weth),
            maturity: MATURITY
        });
        vm.prank(address(lendingCLOB));
        centuari.createDataStore(usdcWethMarketConfig);

        //Deploy LendingCLOB
        lendingCLOB = new LendingCLOB(address(this), address(centuari));

        //Set LendingCLOB address for Centuari
        centuari.setLendingCLOB(address(lendingCLOB));
    }
}
