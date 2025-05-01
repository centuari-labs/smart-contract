// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {BaseDeployData} from "./BaseDeployData.s.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IMockOracle} from "../../src/interfaces/IMockOracle.sol";
import {CentuariCLOB} from "../../src/core/CentuariCLOB.sol";
import {MockToken} from "../../src/mocks/MockToken.sol";
import {MarketConfig, Side} from "../../src/types/CommonTypes.sol";
import {MarketConfigLib} from "../../src/libraries/MarketConfigLib.sol";

contract DeployDataOrder is BaseDeployData {
    using MarketConfigLib for MarketConfig;

    function _deployImplementation() internal override {
        vm.stopBroadcast();
        console2.log(unicode"\n📊 Starting Order Placement");
        // Process each collateral
        for (uint256 i = 0; i < collaterals.length; i++) {
            string memory collateralSymbol = IERC20Metadata(address(collaterals[i])).symbol();
            console2.log(unicode"\n🔄 Processing Collateral: %s", collateralSymbol);

            // Calculate max loan amount for this collateral
            uint256 collateralValue = (collateralAmounts[i] * collateralPrices[i]) / 10 ** IERC20Metadata(address(collaterals[i])).decimals();
            uint256 maxLoanAmount = (collateralValue * 40) / 100;
            
            // Process each maturity for this collateral
            for (uint256 j = 0; j < maturities.length; j++) {
                // Calculate base rate with maturity premium
                uint256 maturityPremium = j * 0.5e16; // 0.5% increase per maturity
                uint256 baseRate = baseRates[i] + maturityPremium;

                // Generate random seed and rate increment
                (uint256 seed, uint256 rateIncrement, uint256 musdcAmount) = generateRandomParameters(i, j, maxLoanAmount);
                
                // Generate rates for this maturity
                (uint256[] memory lendRates, uint256[] memory borrowRates) = generateRates(baseRate, rateIncrement);
                
                // Place orders
                MarketConfig memory marketConfig = MarketConfig({
                    loanToken: address(musdc),
                    collateralToken: address(collaterals[i]),
                    maturity: maturities[j]
                });
                placeLendOrders(marketConfig, lendRates, musdcAmount, seed);
                placeBorrowOrders(marketConfig, borrowRates, musdcAmount, collateralAmounts[i], seed);
            }
        }
        console2.log(unicode"\n✅ Mock Market Data Generation Complete!");
        vm.startBroadcast(deployerKey);
    }
    
    function generateRandomParameters(
        uint256 collateralIndex, 
        uint256 maturityIndex, 
        uint256 maxLoanAmount
    ) private view returns (uint256 seed, uint256 rateIncrement, uint256 musdcAmount) {
        // Random seed based on timestamp and indices
        seed = uint256(keccak256(abi.encodePacked(block.timestamp, collateralIndex, maturityIndex)));
        
        // Randomize RATE_INCREMENT between 0.01% ~ 0.05% (0.01e16 ~ 0.05e16)
        rateIncrement = 0.01e16 + (seed % 5) * 0.01e16;
        
        // Randomize USDC_AMOUNT between 1000 USDC and 40% of collateral value
        uint256 minAmount = 1000e6; // 1,000 USDC
        musdcAmount = minAmount + (uint256(keccak256(abi.encodePacked(seed, collateralIndex, maturityIndex))) % 
            (maxLoanAmount > minAmount ? maxLoanAmount - minAmount : 0));
            
        return (seed, rateIncrement, musdcAmount);
    }
    
    function generateRates(uint256 baseRate, uint256 rateIncrement) private pure returns (
        uint256[] memory lendRates, 
        uint256[] memory borrowRates
    ) {
        // Generate lending rates (6 rates, increasing by randomized increment)
        lendRates = new uint256[](6);
        for (uint256 k = 0; k < 6; k++) {
            lendRates[k] = baseRate + (k * rateIncrement);
        }

        // Generate borrowing rates (5 rates, increasing by randomized increment)
        borrowRates = new uint256[](5);
        for (uint256 k = 0; k < 5; k++) {
            borrowRates[k] = baseRate - (rateIncrement + (k * rateIncrement));
        }
        
        return (lendRates, borrowRates);
    }
    
    function placeLendOrders(
        MarketConfig memory marketConfig, 
        uint256[] memory lendRates, 
        uint256 baseAmount,
        uint256 seed
    ) private {
        console2.log(
            unicode"\n📈 Placing Lend Orders on LoanToken: %s, CollateralToken: %s, Maturity: %s", 
            marketConfig.loanToken, 
            marketConfig.collateralToken, 
            marketConfig.maturity
        );
        console2.log("loan token: %s", marketConfig.loanToken);
        console2.log("amount: %s", baseAmount);
        console2.log("owned amount: %s", MockToken(marketConfig.loanToken).balanceOf(vm.addr(lenderKey)));
        vm.startBroadcast(lenderKey);
        
        for (uint256 k = 0; k < lendRates.length; k++) {
            // Randomize amount per order slightly
            uint256 orderAmount = baseAmount + (uint256(keccak256(abi.encodePacked(seed, marketConfig.id(), k))) % (baseAmount / 10));
            
            musdc.approve(address(centuariCLOB), orderAmount);
            centuariCLOB.placeOrder(
                marketConfig,
                lendRates[k],
                Side.LEND,
                orderAmount,
                0 // no collateral for lending
            );
            
            console2.log(
                "  Rate: %s%%, Amount: %s USDC",
                lendRates[k] / 1e14,
                orderAmount / 1e6
            );
        }
        
        vm.stopBroadcast();
    }
    
    function placeBorrowOrders(
        MarketConfig memory marketConfig, 
        uint256[] memory borrowRates, 
        uint256 baseAmount,
        uint256 collateralAmount,
        uint256 seed
    ) private {
        console2.log(
            unicode"\n📉 Placing Borrow Orders on LoanToken: %s, CollateralToken: %s, Maturity: %s", 
            marketConfig.loanToken, 
            marketConfig.collateralToken, 
            marketConfig.maturity
        );
        console2.log("collateral token: %s", marketConfig.collateralToken);
        console2.log("collateral amount: %s", collateralAmount);
        console2.log("owned collateral amount: %s", MockToken(marketConfig.collateralToken).balanceOf(vm.addr(borrowerKey)));
        vm.startBroadcast(borrowerKey);
        
        for (uint256 k = 0; k < borrowRates.length; k++) {
            // Randomize amount per order slightly
            uint256 orderAmount = baseAmount + (uint256(keccak256(abi.encodePacked(seed, marketConfig.id(), k))) % (baseAmount / 10));
            
            MockToken(marketConfig.collateralToken).approve(address(centuariCLOB), collateralAmount);
            centuariCLOB.placeOrder(
                marketConfig,
                borrowRates[k],
                Side.BORROW,
                orderAmount,
                collateralAmount
            );
            
            console2.log(
                "  Rate: %s%%, Amount: %s USDC",
                borrowRates[k] / 1e14,
                orderAmount / 1e6
            );
        }
        
        vm.stopBroadcast();
    }
}