// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BaseTest} from "./BaseTest.sol";
import {Side} from "../src/types/CommonTypes.sol";
import {MockToken} from "./mocks/MockToken.sol";
import {MarketConfig} from "../src/types/CommonTypes.sol";

contract WillTest is BaseTest {

    address public lender = makeAddr("lender");
    address public borrower = makeAddr("borrower");

    function test_Will() public {
        MarketConfig memory marketConfig = MarketConfig({
            loanToken: address(mockUsdc),
            collateralToken: address(mockTokens[0]),
            maturity: maturities[0]
        });

        MockToken(mockUsdc).mint(lender, 1000e6);
        MockToken(mockTokens[0]).mint(borrower, 1000e18);

        vm.startPrank(lender);
        mockUsdc.approve(address(centuariCLOB), 100e6);
        centuariCLOB.placeOrder(marketConfig, RATE, Side.LEND, 100e6, 0);
        vm.stopPrank();

        vm.assertEq(mockUsdc.balanceOf(lender), 900e6);
        vm.assertEq(mockUsdc.balanceOf(address(centuari)), 100e6);

        vm.startPrank(borrower);
        mockTokens[0].approve(address(centuariCLOB), 1e18);
        centuariCLOB.placeOrder(marketConfig, RATE, Side.BORROW, 100e6, 1e18);
        vm.stopPrank();
        
        vm.assertEq(mockUsdc.balanceOf(borrower), 100e6);
        vm.assertEq(mockTokens[0].balanceOf(borrower), 999e18);
        vm.assertEq(mockTokens[0].balanceOf(address(centuari)), 1e18);
    }
}
