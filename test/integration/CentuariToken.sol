// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {CentuariToken} from "../../src/core/CentuariToken.sol";
import {MockToken} from "../../src/mocks/MockToken.sol";

/// @title Base test contract for CentuariToken
/// @notice Provides the common setup and utilities for all CentuariToken tests
/// @dev Inherits from Forge's Test contract for testing utilities
contract CentuariTokenTest_Base is Test {
    /// @notice Mock USDC token address
    address public loanToken;
    /// @notice Mock ETH token address
    address public collateralToken;
    /// @notice The CentuariToken instance being tested
    CentuariToken public centuariToken;
    /// @notice Test address for unauthorized operations
    address public address1;

    /// @notice Sets up the test environment before each test
    /// @dev Deploys mock tokens and CentuariToken with initial configuration
    function setUp() public {
        loanToken = address(new MockToken("Mock USDC", "MUSDC", 6));
        collateralToken = address(new MockToken("Mock ETH", "METH", 18));

        CentuariToken.CentuariTokenConfig memory config = CentuariToken.CentuariTokenConfig({
            loanToken: loanToken,
            collateralToken: collateralToken,
            rate: 45e16,
            maturity: 1715280000,
            maturityMonth: "MAY",
            maturityYear: 2025
        });

        centuariToken = new CentuariToken(
            address(this), // lending pool address
            config
        );
        address1 = makeAddr("address1");
    }
}

/// @title Constructor tests for CentuariToken
/// @notice Tests the initialization and configuration of CentuariToken
/// @dev Inherits from CentuariTokenTest_Base for common setup
contract CentuariTokenTest_Constructor is CentuariTokenTest_Base {
    /// @notice Tests that the constructor properly sets all state variables
    /// @dev Verifies token addresses, rate, maturity, and metadata
    function test_CentuariToken_Constructor() public view {
        console.log("Token Symbol:", IERC20Metadata(centuariToken).symbol());
        console.log("Token Name:", IERC20Metadata(centuariToken).name());

        (
            address loanToken_,
            address collateralToken_,
            uint256 rate_,
            uint256 maturity_,
            string memory maturityMonth_,
            uint256 maturityYear_
        ) = centuariToken.config();

        assertEq(loanToken_, loanToken, "Incorrect loan token address");
        assertEq(collateralToken_, collateralToken, "Incorrect collateral token address");
        assertEq(rate_, 45e16, "Incorrect borrow rate");
        assertEq(maturity_, 1715280000, "Incorrect maturity timestamp");
        assertEq(maturityMonth_, "MAY", "Incorrect maturity month");
        assertEq(maturityYear_, 2025, "Incorrect maturity year");
    }
}

/// @title Minting tests for CentuariToken
/// @notice Tests the minting functionality of CentuariToken
/// @dev Inherits from CentuariTokenTest_Base for common setup
contract CentuariTokenTest_Mint is CentuariTokenTest_Base {
    /// @notice Tests successful minting of tokens
    /// @dev Verifies that the owner can mint tokens and balance is updated correctly
    function test_Mint() public {
        centuariToken.mint(address(this), 1000);
        assertEq(centuariToken.balanceOf(address(this)), 1000, "Incorrect balance after mint");
    }

    /// @notice Tests that non-owners cannot mint tokens
    /// @dev Verifies that the transaction reverts with OwnableUnauthorizedAccount error
    function test_Mint_RevertIf_NotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address1));
        vm.prank(address1);
        centuariToken.mint(address(this), 1000);
    }
}
