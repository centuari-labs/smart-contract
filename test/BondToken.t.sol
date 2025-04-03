// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {BondToken} from "../src/BondToken.sol";
import {MockToken} from "../src/mocks/MockToken.sol";

contract BondTokenTest_Base is Test {
    address public debtToken;
    address public collateralToken;
    BondToken public bondToken;
    address public address1;

    function setUp() public {
        debtToken = address(new MockToken("Mock USDC", "MUSDC", 6));
        collateralToken = address(new MockToken("Mock ETH", "METH", 18));

        BondToken.BondTokenInfo memory info = BondToken.BondTokenInfo({
            debtToken: debtToken,
            collateralToken: collateralToken,
            rate: 45e16,
            maturity: 1715280000,
            maturityMonth: "MAY",
            maturityYear: 2025,
            decimals: 6
        });

        bondToken = new BondToken(
            address(this), // lending pool address
            info
        );
        address1 = makeAddr("address1");
    }
}

contract BondTokenTest_Constructor is BondTokenTest_Base {
    function test_BondToken_Constructor() public view {
        console.log("Token Symbol:", IERC20Metadata(bondToken).symbol());
        console.log("Token Name:", IERC20Metadata(bondToken).name());

        (
            address debtToken_,
            address collateralToken_,
            uint256 rate_,
            uint256 maturity_,
            string memory maturityMonth_,
            uint256 maturityYear_,
            uint256 decimals_
        ) = bondToken.info();

        assertEq(debtToken_, debtToken, "Incorrect debt token address");
        assertEq(collateralToken_, collateralToken, "Incorrect collateral token address");
        assertEq(rate_, 45e16, "Incorrect borrow rate");
        assertEq(maturity_, 1715280000, "Incorrect maturity timestamp");
        assertEq(maturityMonth_, "MAY", "Incorrect maturity month");
        assertEq(maturityYear_, 2025, "Incorrect maturity year");
        assertEq(decimals_, 6, "Incorrect decimals");
    }
}

contract BondTokenTest_Mint is BondTokenTest_Base {
    function test_Mint() public {
        bondToken.mint(address(this), 1000);
        assertEq(bondToken.balanceOf(address(this)), 1000, "Incorrect balance after mint");
    }

    function test_Mint_RevertIf_NotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address1));
        vm.prank(address1);
        bondToken.mint(address(this), 1000);
    }
}
