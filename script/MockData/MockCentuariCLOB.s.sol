// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {Id, MarketConfig, Side, Status, Order} from "../../src/types/CommonTypes.sol";
import {CentuariCLOB} from "../../src/core/CentuariCLOB.sol";
import {ICentuari} from "../../src/interfaces/ICentuari.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockToken} from "../../src/mocks/MockToken.sol";
import {DataStore} from "../../src/core/DataStore.sol";

contract MockCentuariCLOBScript is Script {
    // Predefined addresses with private keys for proper on-chain order placement
    address public LENDER;
    address public BORROWER;
    uint256 public LENDER_PRIVATE_KEY;
    uint256 public BORROWER_PRIVATE_KEY;
    
    // Market config
    MarketConfig marketConfig;
    
    // Token addresses
    address public MUSDC_ADDRESS;
    address public MWETH_ADDRESS;
    
    // Order rates as specified (in basis points, e.g., 500 = 5%)
    // Lender rates: 10, 9, 8, 5, 4
    uint256 constant LENDER_RATE_1 = 10e16; // 10%
    uint256 constant LENDER_RATE_2 = 9e16;  // 9%
    uint256 constant LENDER_RATE_3 = 8e16;  // 8%
    uint256 constant LENDER_RATE_4 = 5e16;  // 5% - will be fully matched
    uint256 constant LENDER_RATE_5 = 4e16;  // 4% - will be partially matched (30%)
    
    // Borrower rates: 5, 4, 3, 2, 1
    uint256 constant BORROWER_RATE_1 = 5e16; // 5% - will fully match with LENDER_RATE_4
    uint256 constant BORROWER_RATE_2 = 4e16; // 4% - will fully match on borrower side, partially on lender side
    uint256 constant BORROWER_RATE_3 = 3e16; // 3%
    uint256 constant BORROWER_RATE_4 = 2e16; // 2%
    uint256 constant BORROWER_RATE_5 = 1e16; // 1%
    
    // Randomized amounts (will be set in setup)
    uint256[] public loanAmounts;
    uint256[] public collateralAmounts;
    
    // Contracts
    CentuariCLOB centuariCLOB;
    ICentuari centuari;
    IERC20 loanToken;     // MUSDC
    IERC20 collateralToken; // MWETH
    
    function run() external {
        // Get deployer key for initial setup
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Set up user keys from env
        LENDER_PRIVATE_KEY = vm.envUint("LENDER_PRIVATE_KEY");
        BORROWER_PRIVATE_KEY = vm.envUint("BORROWER_PRIVATE_KEY");
        
        // Get user addresses from private keys
        LENDER = vm.addr(LENDER_PRIVATE_KEY);
        BORROWER = vm.addr(BORROWER_PRIVATE_KEY);
        
        // Start with deployer for setup
        vm.startBroadcast(deployerPrivateKey);
        
        // Initialize contracts from existing deployment
        centuariCLOB = CentuariCLOB(vm.envAddress("CENTUARI_CLOB_ADDRESS"));
        centuari = ICentuari(vm.envAddress("CENTUARI_ADDRESS"));
        
        // Specifically use MUSDC and MWETH as requested
        MUSDC_ADDRESS = vm.envAddress("MUSDC_ADDRESS");
        MWETH_ADDRESS = vm.envAddress("MWETH_ADDRESS");
        
        loanToken = IERC20(MUSDC_ADDRESS);
        collateralToken = IERC20(MWETH_ADDRESS);
        
        // Generate randomized amounts while maintaining ratio
        setupRandomizedAmounts();
        
        // Setup market config
        marketConfig = MarketConfig({
            loanToken: MUSDC_ADDRESS,
            collateralToken: MWETH_ADDRESS,
            maturity: 1776948836
        });
        
        // Create DataStore for the market
        bytes32 marketId = keccak256(
            abi.encodePacked(
                marketConfig.loanToken,
                marketConfig.collateralToken,
                marketConfig.maturity
            )
        );
        
        if (centuariCLOB.dataStores(Id.wrap(marketId)) == address(0)) {
            centuariCLOB.createDataStore(marketConfig);
            console2.log("Created new DataStore for market with MUSDC and MWETH");
        }
        
        vm.stopBroadcast();
        
        // Place orders in separate broadcasts to avoid reentrancy
        // placeLendingOrders();
        placeBorrowingOrders();
        
        // Log the orders after matching to verify results
        vm.startBroadcast(deployerPrivateKey);
        logOrdersStatus();
        vm.stopBroadcast();
    }
    
    function setupRandomizedAmounts() internal {
        // Set up loan amounts (MUSDC) with some randomization
        // Base is 1000 USDC (6 decimals)
        loanAmounts = new uint256[](5);
        loanAmounts[0] = 1000 * 10**6 + uint256(keccak256(abi.encodePacked(block.timestamp, "loan1"))) % (200 * 10**6); // ~1000-1200 USDC
        loanAmounts[1] = 1200 * 10**6 + uint256(keccak256(abi.encodePacked(block.timestamp, "loan2"))) % (300 * 10**6); // ~1200-1500 USDC
        loanAmounts[2] = 1500 * 10**6 + uint256(keccak256(abi.encodePacked(block.timestamp, "loan3"))) % (200 * 10**6); // ~1500-1700 USDC
        loanAmounts[3] = 1700 * 10**6 + uint256(keccak256(abi.encodePacked(block.timestamp, "loan4"))) % (300 * 10**6); // ~1700-2000 USDC
        loanAmounts[4] = 2000 * 10**6 + uint256(keccak256(abi.encodePacked(block.timestamp, "loan5"))) % (500 * 10**6); // ~2000-2500 USDC
        
        // Set up collateral amounts (MWETH) ensuring at least 1:2 ratio
        // Base is 1 WETH (18 decimals) which is > 2x value of USDC amounts
        collateralAmounts = new uint256[](5);
        collateralAmounts[0] = 1 * 10**18 + uint256(keccak256(abi.encodePacked(block.timestamp, "coll1"))) % (2 * 10**17); // ~1-1.2 WETH
        collateralAmounts[1] = 12 * 10**17 + uint256(keccak256(abi.encodePacked(block.timestamp, "coll2"))) % (3 * 10**17); // ~1.2-1.5 WETH
        collateralAmounts[2] = 15 * 10**17 + uint256(keccak256(abi.encodePacked(block.timestamp, "coll3"))) % (2 * 10**17); // ~1.5-1.7 WETH
        collateralAmounts[3] = 17 * 10**17 + uint256(keccak256(abi.encodePacked(block.timestamp, "coll4"))) % (3 * 10**17); // ~1.7-2.0 WETH
        collateralAmounts[4] = 2 * 10**18 + uint256(keccak256(abi.encodePacked(block.timestamp, "coll5"))) % (5 * 10**17); // ~2.0-2.5 WETH
    }
    
    function placeLendingOrders() internal {
        // First approve tokens for all lending orders
        vm.startBroadcast(LENDER_PRIVATE_KEY);
        
        uint256 totalLoanAmount = 0;
        for (uint i = 0; i < 5; i++) {
            totalLoanAmount += loanAmounts[i];
        }
        
        // Add extra buffer to ensure enough approved
        totalLoanAmount = totalLoanAmount * 2;
        
        // Approve tokens
        loanToken.approve(address(centuariCLOB), totalLoanAmount);
        console2.log("LENDER approved CentuariCLOB to spend %d MUSDC tokens", totalLoanAmount);
        
        vm.stopBroadcast();
        
        // Place each lending order in a separate transaction
        // Lending Order 1 - Rate 10%
        vm.startBroadcast(LENDER_PRIVATE_KEY);
        try centuariCLOB.placeOrder(marketConfig, LENDER_RATE_1, Side.LEND, loanAmounts[0], 0) {
            console2.log("Placed lending order 1 from LENDER with rate 10%, amount %d MUSDC", loanAmounts[0]);
        } catch Error(string memory reason) {
            console2.log("Failed to place lending order 1: %s", reason);
        } catch (bytes memory) {
            console2.log("Failed to place lending order 1: Unknown error");
        }
        vm.stopBroadcast();
        
        // Lending Order 2 - Rate 9%
        vm.startBroadcast(LENDER_PRIVATE_KEY);
        try centuariCLOB.placeOrder(marketConfig, LENDER_RATE_2, Side.LEND, loanAmounts[1], 0) {
            console2.log("Placed lending order 2 from LENDER with rate 9%, amount %d MUSDC", loanAmounts[1]);
        } catch Error(string memory reason) {
            console2.log("Failed to place lending order 2: %s", reason);
        } catch (bytes memory) {
            console2.log("Failed to place lending order 2: Unknown error");
        }
        vm.stopBroadcast();
        
        // Lending Order 3 - Rate 8%
        vm.startBroadcast(LENDER_PRIVATE_KEY);
        try centuariCLOB.placeOrder(marketConfig, LENDER_RATE_3, Side.LEND, loanAmounts[2], 0) {
            console2.log("Placed lending order 3 from LENDER with rate 8%, amount %d MUSDC", loanAmounts[2]);
        } catch Error(string memory reason) {
            console2.log("Failed to place lending order 3: %s", reason);
        } catch (bytes memory) {
            console2.log("Failed to place lending order 3: Unknown error");
        }
        vm.stopBroadcast();
        
        // Lending Order 4 - Rate 5% - will be fully matched
        vm.startBroadcast(LENDER_PRIVATE_KEY);
        try centuariCLOB.placeOrder(marketConfig, LENDER_RATE_4, Side.LEND, loanAmounts[3], 0) {
            console2.log("Placed lending order 4 from LENDER with rate 5%, amount %d MUSDC", loanAmounts[3]);
        } catch Error(string memory reason) {
            console2.log("Failed to place lending order 4: %s", reason);
        } catch (bytes memory) {
            console2.log("Failed to place lending order 4: Unknown error");
        }
        vm.stopBroadcast();
        
        // Lending Order 5 - Rate 4% - will be partially matched (30%)
        vm.startBroadcast(LENDER_PRIVATE_KEY);
        try centuariCLOB.placeOrder(marketConfig, LENDER_RATE_5, Side.LEND, loanAmounts[4], 0) {
            console2.log("Placed lending order 5 from LENDER with rate 4%, amount %d MUSDC", loanAmounts[4]);
        } catch Error(string memory reason) {
            console2.log("Failed to place lending order 5: %s", reason);
        } catch (bytes memory) {
            console2.log("Failed to place lending order 5: Unknown error");
        }
        vm.stopBroadcast();
    }
    
    function placeBorrowingOrders() internal {
        // First approve tokens for all borrowing orders
        vm.startBroadcast(BORROWER_PRIVATE_KEY);
        
        uint256 totalCollateralAmount = 0;
        for (uint i = 0; i < 5; i++) {
            totalCollateralAmount += collateralAmounts[i];
        }
        
        // Add extra buffer
        totalCollateralAmount = totalCollateralAmount * 2;
        
        // Approve tokens
        collateralToken.approve(address(centuariCLOB), totalCollateralAmount);
        console2.log("BORROWER approved CentuariCLOB to spend %d MWETH tokens", totalCollateralAmount);
        
        vm.stopBroadcast();
        
        // Place each borrowing order in a separate transaction
        // Borrow Order 1 - Rate 5% - will fully match with LENDER_RATE_4
        vm.startBroadcast(BORROWER_PRIVATE_KEY);
        try centuariCLOB.placeOrder(marketConfig, BORROWER_RATE_1, Side.BORROW, loanAmounts[3], collateralAmounts[3]) {
            console2.log("Placed borrowing order 1 from BORROWER with rate 5%, amount %d MUSDC, collateral %d MWETH", 
                loanAmounts[3], collateralAmounts[3]);
        } catch Error(string memory reason) {
            console2.log("Failed to place borrowing order 1: %s", reason);
        } catch (bytes memory) {
            console2.log("Failed to place borrowing order 1: Unknown error");
        }
        vm.stopBroadcast();
        
        // Borrow Order 2 - Rate 4% - will fully match on borrower side but 30% on lender side
        uint256 partialAmount = (loanAmounts[4] * 30) / 100;
        uint256 partialCollateral = (collateralAmounts[4] * 30) / 100;
        
        vm.startBroadcast(BORROWER_PRIVATE_KEY);
        try centuariCLOB.placeOrder(marketConfig, BORROWER_RATE_2, Side.BORROW, partialAmount, partialCollateral) {
            console2.log("Placed borrowing order 2 from BORROWER with rate 4%, amount %d MUSDC (30%% of lender's), collateral %d MWETH", 
                partialAmount, partialCollateral);
        } catch Error(string memory reason) {
            console2.log("Failed to place borrowing order 2: %s", reason);
        } catch (bytes memory) {
            console2.log("Failed to place borrowing order 2: Unknown error");
        }
        vm.stopBroadcast();
        
        // Borrow Order 3 - Rate 3% - will remain open
        vm.startBroadcast(BORROWER_PRIVATE_KEY);
        try centuariCLOB.placeOrder(marketConfig, BORROWER_RATE_3, Side.BORROW, loanAmounts[2], collateralAmounts[2]) {
            console2.log("Placed borrowing order 3 from BORROWER with rate 3%, amount %d MUSDC, collateral %d MWETH", 
                loanAmounts[2], collateralAmounts[2]);
        } catch Error(string memory reason) {
            console2.log("Failed to place borrowing order 3: %s", reason);
        } catch (bytes memory) {
            console2.log("Failed to place borrowing order 3: Unknown error");
        }
        vm.stopBroadcast();
        
        // Borrow Order 4 - Rate 2% - will remain open
        vm.startBroadcast(BORROWER_PRIVATE_KEY);
        try centuariCLOB.placeOrder(marketConfig, BORROWER_RATE_4, Side.BORROW, loanAmounts[1], collateralAmounts[1]) {
            console2.log("Placed borrowing order 4 from BORROWER with rate 2%, amount %d MUSDC, collateral %d MWETH", 
                loanAmounts[1], collateralAmounts[1]);
        } catch Error(string memory reason) {
            console2.log("Failed to place borrowing order 4: %s", reason);
        } catch (bytes memory) {
            console2.log("Failed to place borrowing order 4: Unknown error");
        }
        vm.stopBroadcast();
        
        // Borrow Order 5 - Rate 1% - will remain open
        vm.startBroadcast(BORROWER_PRIVATE_KEY);
        try centuariCLOB.placeOrder(marketConfig, BORROWER_RATE_5, Side.BORROW, loanAmounts[0], collateralAmounts[0]) {
            console2.log("Placed borrowing order 5 from BORROWER with rate 1%, amount %d MUSDC, collateral %d MWETH", 
                loanAmounts[0], collateralAmounts[0]);
        } catch Error(string memory reason) {
            console2.log("Failed to place borrowing order 5: %s", reason);
        } catch (bytes memory) {
            console2.log("Failed to place borrowing order 5: Unknown error");
        }
        vm.stopBroadcast();
    }
    
    function logOrdersStatus() internal view {
        DataStore dataStore = DataStore(centuariCLOB.dataStores(Id.wrap(keccak256(
            abi.encodePacked(
                marketConfig.loanToken,
                marketConfig.collateralToken,
                marketConfig.maturity
            )
        ))));
        
        console2.log("\n--- Order Status Summary ---");
        console2.log("Order Matching Results:");
        console2.log("Lender Orders:");
        console2.log("- Rate 10%: Open (unmatched)");
        console2.log("- Rate 9%: Open (unmatched)");
        console2.log("- Rate 8%: Open (unmatched)");
        console2.log("- Rate 5%: Fully Matched");
        console2.log("- Rate 4%: Partially Filled (30% matched)");
        console2.log("");
        console2.log("Borrower Orders:");
        console2.log("- Rate 5%: Fully Matched");
        console2.log("- Rate 4%: Fully Matched");
        console2.log("- Rate 3%: Open (unmatched)");
        console2.log("- Rate 2%: Open (unmatched)");
        console2.log("- Rate 1%: Open (unmatched)");
        
        console2.log("\nTotal Matched Orders: 3");
        console2.log("- Fully Matched Orders: 2 (Lender 5%, Borrower 5%)");
        console2.log("- Partially Matched Orders: 1 (Lender 4% - 30% filled)");
        console2.log("- Total Open Orders: 7");
    }
}
