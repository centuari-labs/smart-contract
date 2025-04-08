// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MockToken} from "../src/mocks/MockToken.sol";
import {BondToken} from "../src/core/BondToken.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";

/// @title Centuari Base Test
/// @notice Provides shared setup for unit tests across the protocol
contract BaseTest is Test {
    /// --- Common Addresses ---
    address internal address1;

    /// --- Tokens ---
    MockToken internal usdc;
    MockToken internal weth;

    /// --- BondToken ---
    BondToken internal bondToken;

    /// --- Oracle ---
    MockOracle internal mockOracle;

    /// --- Shared Constants ---
    uint256 internal constant BORROW_RATE = 45e16;
    uint256 internal constant MATURITY = 1715280000;
    string internal constant MATURITY_MONTH = "MAY";
    uint256 internal constant MATURITY_YEAR = 2025;
    uint8 internal constant DECIMALS = 6;

    function setUp() public virtual {
        address1 = makeAddr("address1");

        // Deploy mock tokens
        usdc = new MockToken("Mock USDC", "MUSDC", DECIMALS);
        weth = new MockToken("Mock ETH", "METH", 18);

        // Deploy mock oracle
        mockOracle = new MockOracle(address(usdc), address(weth));

        // Deploy BondToken
        BondToken.BondTokenInfo memory info = BondToken.BondTokenInfo({
            debtToken: address(usdc),
            collateralToken: address(weth),
            rate: BORROW_RATE,
            maturity: MATURITY,
            maturityMonth: MATURITY_MONTH,
            maturityYear: MATURITY_YEAR,
            decimals: DECIMALS
        });

        bondToken = new BondToken(address(this), info);
    }
}
