// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BaseTest} from "./BaseTest.sol";
import {Side} from "../src/types/CommonTypes.sol";
import {MockToken} from "./mocks/MockToken.sol";

contract WillTest is BaseTest {

    address public lender = makeAddr("lender");
    address public borrower = makeAddr("borrower");

    function test_Will() public {
        MockToken(usdc).mint(lender, 1000e6);
        MockToken(weth).mint(borrower, 1000e18);

        vm.startPrank(lender);
        usdc.approve(address(centuariCLOB), 100e6);
        centuariCLOB.placeOrder(usdcWethMarketConfig, RATE, Side.LEND, 100e6, 0);
        vm.stopPrank();

        vm.assertEq(usdc.balanceOf(lender), 900e6);
        vm.assertEq(usdc.balanceOf(address(centuari)), 100e6);

        vm.startPrank(borrower);
        weth.approve(address(centuariCLOB), 1e18);
        centuariCLOB.placeOrder(usdcWethMarketConfig, RATE, Side.BORROW, 100e6, 1e18);
        vm.stopPrank();
        
        vm.assertEq(usdc.balanceOf(borrower), 100e6);
        vm.assertEq(weth.balanceOf(borrower), 999e18);
        vm.assertEq(usdc.balanceOf(address(centuari)), 0);
        vm.assertEq(weth.balanceOf(address(centuari)), 1e18);
    }
}
