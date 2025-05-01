import {BaseTest} from "../../BaseTest.sol";
import {CentuariPrime} from "../../../src/core/CentuariPrime.sol";
import {VaultConfig, VaultMarketSupplyConfig, VaultMarketWithdrawConfig, MarketConfig, Id} from "../../../src/types/CommonTypes.sol";
import {DataStore} from "../../../src/core/DataStore.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/Test.sol";
import {CentuariPrimeDSLib} from "../../../src/libraries/centuari-prime/CentuariPrimeDSLib.sol";
import {CentuariDSLib} from "../../../src/libraries/centuari/CentuariDSLib.sol";
import {IDataStore} from "../../../src/interfaces/IDataStore.sol";

contract DepositIntegration is BaseTest {
    
    function test_Deposit() public {
       for (uint256 i = 0; i < 5; i++) {
            centuariPrime.createVault(VaultConfig({
                curator: owner,
                token: address(mockUsdc),
                name: string.concat("Vault ", mockUsdc.symbol(), " ", vm.toString(i+1))
            }));
        }
        
        // Set supply and withdraw queues
        for (uint256 i = 0; i < 5; i++) {
            VaultMarketSupplyConfig[] memory supplyQueue = new VaultMarketSupplyConfig[](5);
            VaultMarketWithdrawConfig[] memory withdrawQueue = new VaultMarketWithdrawConfig[](5);
            for (uint256 j = 0; j < 5; j++) {
                uint256 rate_ = (j+1) * 1e16;
                supplyQueue[j] = VaultMarketSupplyConfig({
                    marketConfig: MarketConfig({
                        loanToken: address(mockUsdc),
                        collateralToken: address(mockTokens[j]),
                        maturity: maturities[j]
                    }),
                    rate: rate_,
                    cap: 1000000e6
                });

                withdrawQueue[j] = VaultMarketWithdrawConfig({
                    marketConfig: MarketConfig({
                        loanToken: address(mockUsdc),
                        collateralToken: address(mockTokens[j]),
                        maturity: maturities[j]
                    }),
                    rate: rate_
                });
            }

            centuariPrime.setSupplyQueue(VaultConfig({
                curator: owner,
                token: address(mockUsdc),
                name: string.concat("Vault ", mockUsdc.symbol(), " ", vm.toString(i+1))
            }), supplyQueue);

            centuariPrime.setWithdrawQueue(VaultConfig({
                curator: owner,
                token: address(mockUsdc),
                name: string.concat("Vault ", mockUsdc.symbol(), " ", vm.toString(i+1))
            }), withdrawQueue);
        }

        mockUsdc.mint(address1, 20000e6);
        vm.startPrank(address1);
        // First create the vault configuration outside the loop so we can reuse it
        VaultConfig memory firstVaultConfig = VaultConfig({
            curator: owner,
            token: address(mockUsdc),
            name: string.concat("Vault ", mockUsdc.symbol(), " ", "1")
        });
        
        // Make deposits into 5 different vaults
        for (uint256 i = 0; i < 5; i++) {
            VaultConfig memory vaultConfig;
            if (i == 0) {
                // For the first iteration, use the previously defined config
                vaultConfig = firstVaultConfig;
            } else {
                // For other iterations, create a new vault config
                vaultConfig = VaultConfig({
                    curator: owner,
                    token: address(mockUsdc),
                    name: string.concat("Vault ", mockUsdc.symbol(), " ", vm.toString(i+1))
                });
            }
            
            mockUsdc.approve(address(centuariPrime), 2000e6);
            centuariPrime.deposit(vaultConfig, 2000e6); 
            assertEq(IERC20(address(mockUsdc)).balanceOf(address(centuari)), 2000e6*(i+1));
        }
        
        // Now make a 6th deposit into the first vault again
        console.log("Starting 6th deposit to first vault");

        // Get the vault ID to check supply queue
        bytes32 vaultId = keccak256(abi.encodePacked(firstVaultConfig.curator, firstVaultConfig.token, firstVaultConfig.name));
        address vaultAddress = address(centuariPrime.vaults(Id.wrap(vaultId)));
        console.log("Vault Address:", vaultAddress);
        
        // Check the supply queue
        bytes memory supplyQueueBytes = DataStore(vaultAddress).getBytes(CentuariPrimeDSLib.SUPPLY_QUEUE_BYTES);
        if (supplyQueueBytes.length > 0) {
            VaultMarketSupplyConfig[] memory supplyQueue = abi.decode(supplyQueueBytes, (VaultMarketSupplyConfig[]));
            console.log("Supply Queue Length:", supplyQueue.length);
            
            // Check supply caps
            for (uint256 i = 0; i < supplyQueue.length; i++) {
                if (supplyQueue[i].marketConfig.loanToken != address(0)) {
                    console.log("Market", i, "cap:", supplyQueue[i].cap);
                    console.log("Market", i, "loanToken:", supplyQueue[i].marketConfig.loanToken);
                    console.log("Market", i, "collateralToken:", supplyQueue[i].marketConfig.collateralToken);
                    console.log("Market", i, "rate:", supplyQueue[i].rate);
                    console.log("Market", i, "maturity:", supplyQueue[i].marketConfig.maturity);
                    console.log("Market", i, "centuariToken:", CentuariDSLib.getCentuariTokenAddress(IDataStore(centuari.getDataStore(supplyQueue[i].marketConfig)), supplyQueue[i].rate) == address(0) ? "true" : "false");
                }
            }
        } else {
            console.log("Supply Queue is empty");
        }
        
        mockUsdc.approve(address(centuariPrime), 2000e6);
        centuariPrime.deposit(firstVaultConfig, 2000e6);
        
        assertEq(IERC20(address(mockUsdc)).balanceOf(address(centuari)), 2000e6*6);
        vm.stopPrank();
    }
}