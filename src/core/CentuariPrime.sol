// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// External imports
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Internal imports - contracts
import {DataStore} from "./DataStore.sol";
import {ICentuari} from "../interfaces/ICentuari.sol";

// Internal imports - types
import {Id, MarketConfig, VaultConfig, VaultMarketConfig} from "../types/CommonTypes.sol";

// Internal imports - libraries
import {MarketConfigLib} from "../libraries/MarketConfigLib.sol";
import {VaultConfigLib} from "../libraries/VaultConfigLib.sol";
import {CentuariPrimeDSLib} from "../libraries/centuari-prime/CentuariPrimeDSLib.sol";
import {CentuariPrimeErrorsLib} from "../libraries/centuari-prime/CentuariPrimeErrorsLib.sol";
import {CentuariPrimeEventsLib} from "../libraries/centuari-prime/CentuariPrimeEventsLib.sol";
import {CentuariDSLib} from "../libraries/centuari/CentuariDSLib.sol";

// struct VaultConfig{
//     address curator;
//     string name;
//     address token;
//     MarketConfig[] supplyQueue;
//     MarketConfig[] withdrawQueue;
//     uint256 totalShares;
//     uint256 totalAssets;
//     uint256 lastAccrue;
//     address centuariPrimeToken;
//     bool isActive;
// }

contract CentuariPrime is Ownable, ReentrancyGuard {
    using VaultConfigLib for VaultConfig;
    using MarketConfigLib for MarketConfig;
    using SafeERC20 for IERC20;

    mapping(Id => address) public vaults;

    address public lendingCLOB;
    address public centuari;

    constructor(address owner_, address lendingCLOB_, address centuari_) Ownable(owner_) {
        lendingCLOB = lendingCLOB_;
        centuari = centuari_;
    }

    function setLendingCLOB(address lendingCLOB_) external onlyOwner {
        lendingCLOB = lendingCLOB_;
    }

    function createVault(VaultConfig memory config) external {
        if (config.curator == address(0) || config.token == address(0) || bytes(config.name).length == 0) {
            revert CentuariPrimeErrorsLib.InvalidVaultConfig();
        }
        if (vaults[config.id()] != address(0)) {revert CentuariPrimeErrorsLib.VaultAlreadyExists();}

        DataStore vault = new DataStore(msg.sender, address(this));
        vaults[config.id()] = address(vault);

        // Set vault data
        vault.setAddress(CentuariPrimeDSLib.CURATOR_ADDRESS, config.curator);
        vault.setAddress(CentuariPrimeDSLib.TOKEN_ADDRESS, config.token);
        vault.setString(CentuariPrimeDSLib.NAME_STRING, config.name);
        vault.setBool(CentuariPrimeDSLib.IS_ACTIVE_BOOL, true);

        emit CentuariPrimeEventsLib.CreateVault(address(vault), config.curator, config.token, config.name);
    }

    function deposit(VaultConfig memory config, uint256 amount) external nonReentrant {
        if(vaults[config.id()] == address(0)) {revert CentuariPrimeErrorsLib.VaultDoesNotExist();}
        
        // Get the vault's data store
        DataStore vault = DataStore(vaults[config.id()]);
        
        // Get the token address from the vault
        address vaultToken = vault.getAddress(CentuariPrimeDSLib.TOKEN_ADDRESS);
        
        // // Accrue interest before making any changes
        // _accrueInterest(vault);
        
        // // Calculate shares to mint
        // uint256 shares = _calculateSharesToMint(vault, amount);
        
        // // Update user's share balance
        // uint256 userShares = vault.getUint(CentuariPrimeDSLib.getUserSharesKey(msg.sender));
        // vault.setUint(CentuariPrimeDSLib.getUserSharesKey(msg.sender), userShares + shares);
        
        // // Update total shares and assets
        // uint256 totalShares = vault.getUint(CentuariPrimeDSLib.TOTAL_SHARES_UINT256);
        // uint256 totalAssets = vault.getUint(CentuariPrimeDSLib.TOTAL_ASSETS_UINT256);
        // vault.setUint(CentuariPrimeDSLib.TOTAL_SHARES_UINT256, totalShares + shares);
        // vault.setUint(CentuariPrimeDSLib.TOTAL_ASSETS_UINT256, totalAssets + amount);
        
        // Transfer tokens from user to Centuari (for lending)
        IERC20(vaultToken).safeTransferFrom(msg.sender, centuari, amount);
        
        // Emit deposit event
        emit CentuariPrimeEventsLib.Deposit(address(vault), msg.sender, amount);
    }
    
    // /**
    //  * @notice Calculates shares to mint based on the amount being deposited
    //  * @param vault The vault data store
    //  * @param amount The amount being deposited
    //  * @return shares The number of shares to mint
    //  */
    // function _calculateSharesToMint(DataStore vault, uint256 amount) internal view returns (uint256 shares) {
    //     uint256 totalShares = vault.getUint(CentuariPrimeDSLib.TOTAL_SHARES_UINT256);
    //     uint256 totalAssets = vault.getUint(CentuariPrimeDSLib.TOTAL_ASSETS_UINT256);
        
    //     // If there are no shares yet, mint 1:1, otherwise calculate based on the ratio
    //     if (totalShares == 0) {
    //         shares = amount;
    //     } else {
    //         shares = (amount * totalShares) / totalAssets;
    //     }
    // }
    
    // /**
    //  * @notice Accrues interest for the vault based on vault's performance
    //  * @param vault The vault data store
    //  */
    // function _accrueInterest(DataStore vault) internal {
    //     // Calculate interest based on market performance
    //     uint256 newTotalAssets = _calculateVaultAssets(vault);
    //     vault.setUint(CentuariPrimeDSLib.TOTAL_ASSETS_UINT256, newTotalAssets);
    // }
    
    // /**
    //  * @notice Calculates the current total assets in the vault by querying market positions
    //  * @param vault The vault data store
    //  * @return totalAssets The current total assets value
    //  */
    // function _calculateVaultAssets(DataStore vault) internal view returns (uint256 totalAssets) {
    //     address vaultToken = vault.getAddress(CentuariPrimeDSLib.TOKEN_ADDRESS);
        
    //     // Start with the base assets
    //     totalAssets = vault.getUint(CentuariPrimeDSLib.TOTAL_ASSETS_UINT256);
        
    //     // Get the supply queue (markets where funds are supplied)
    //     bytes memory supplyQueueBytes = vault.getBytes(CentuariPrimeDSLib.SUPPLY_QUEUE);
    //     MarketConfig[] memory supplyQueue = abi.decode(supplyQueueBytes, (MarketConfig[]));
        
    //     // Calculate the total value across all markets
    //     for (uint256 i = 0; i < supplyQueue.length; i++) {
    //         MarketConfig memory market = supplyQueue[i];
            
    //         // Skip if market doesn't match our token
    //         if (market.loanToken != vaultToken) continue;
            
    //         // Get market data store
    //         address marketDataStore = ICentuari(centuari).dataStores(market.id());
    //         if (marketDataStore == address(0)) continue;
            
    //         DataStore marketDS = DataStore(marketDataStore);
            
    //         // For each active rate in this market
    //         bytes memory activeRatesBytes = marketDS.getBytes(CentuariDSLib.ACTIVE_RATES_BYTES);
    //         uint256[] memory activeRates = abi.decode(activeRatesBytes, (uint256[]));
            
    //         for (uint256 j = 0; j < activeRates.length; j++) {
    //             uint256 rate = activeRates[j];
                
    //             // Get bond token for this rate
    //             address bondToken = marketDS.getAddress(CentuariDSLib.getBondTokenAddressKey(rate));
    //             if (bondToken == address(0)) continue;
                
    //             // Get vault's bond token balance
    //             uint256 bondBalance = IERC20(bondToken).balanceOf(address(vault));
    //             if (bondBalance == 0) continue;
                
    //             // Calculate value of these bonds
    //             uint256 totalBondShares = marketDS.getUint(CentuariDSLib.getTotalSuppySharesKey(rate));
    //             uint256 totalBondAssets = marketDS.getUint(CentuariDSLib.getTotalSuppyAssetsKey(rate));
                
    //             if (totalBondShares > 0) {
    //                 uint256 marketValue = (bondBalance * totalBondAssets) / totalBondShares;
    //                 totalAssets += marketValue;
    //             }
    //         }
    //     }
        
    //     return totalAssets;
    // }
    
    // /**
    //  * @notice Allows users to withdraw their funds plus accrued interest
    //  * @param config The vault configuration
    //  * @param shares The number of shares to withdraw
    //  */
    // function withdraw(VaultConfig memory config, uint256 shares) external nonReentrant {
    //     if(vaults[config.id()] == address(0)) {revert CentuariPrimeErrorsLib.VaultDoesNotExist();}
    //     if(shares == 0) {revert CentuariPrimeErrorsLib.InvalidAmount();}
        
    //     // Get the vault's data store
    //     DataStore vault = DataStore(vaults[config.id()]);
        
    //     // Get user's share balance
    //     uint256 userShares = vault.getUint(CentuariPrimeDSLib.getUserSharesKey(msg.sender));
    //     if(userShares < shares) {revert CentuariPrimeErrorsLib.InsufficientShares();}
        
    //     // Accrue interest before calculating withdrawal amount
    //     _accrueVaultInterest(vault);
        
    //     // Calculate assets to withdraw
    //     uint256 totalShares = vault.getUint(CentuariPrimeDSLib.TOTAL_SHARES_UINT256);
    //     uint256 totalAssets = vault.getUint(CentuariPrimeDSLib.TOTAL_ASSETS_UINT256);
    //     uint256 assets = (shares * totalAssets) / totalShares;
        
    //     // Update user's share balance
    //     vault.setUint(CentuariPrimeDSLib.getUserSharesKey(msg.sender), userShares - shares);
        
    //     // Update total shares and assets
    //     vault.setUint(CentuariPrimeDSLib.TOTAL_SHARES_UINT256, totalShares - shares);
    //     vault.setUint(CentuariPrimeDSLib.TOTAL_ASSETS_UINT256, totalAssets - assets);
        
    //     // Get the token address from the vault
    //     address vaultToken = vault.getAddress(CentuariPrimeDSLib.TOKEN_ADDRESS);
        
    //     // Transfer tokens from Centuari to user
    //     IERC20(vaultToken).safeTransferFrom(centuari, msg.sender, assets);
        
    //     // Emit withdraw event
    //     emit CentuariPrimeEventsLib.Withdraw(address(vault), msg.sender, shares, assets);
    // }

    function setSupplyQueue(VaultConfig memory config, VaultMarketConfig[] memory supplyQueue) external {
        if(vaults[config.id()] == address(0)) {revert CentuariPrimeErrorsLib.VaultDoesNotExist();}
        
        // Get the vault's data store
        DataStore vault = DataStore(vaults[config.id()]);

        if(vault.getAddress(CentuariPrimeDSLib.CURATOR_ADDRESS) != msg.sender) {revert CentuariPrimeErrorsLib.OnlyCurator();}
        
        // Check if the vault still has tokens in markets that are being removed
        bytes memory previousMarketBytes = vault.getBytes(CentuariPrimeDSLib.getSupplyQueueKey());
        VaultMarketConfig[] memory previousMarkets = abi.decode(previousMarketBytes, (VaultMarketConfig[]));
        
        // For each previous market, check if it exists in the new supply queue
        for(uint256 i = 0; i < previousMarkets.length; i++) {
            bool marketExists = false;
            
            // Check if this market+rate combination exists in the new supply queue
            for(uint256 j = 0; j < supplyQueue.length; j++) {
                if(Id.unwrap(previousMarkets[i].marketConfig.id()) == Id.unwrap(supplyQueue[j].marketConfig.id()) && 
                   previousMarkets[i].rate == supplyQueue[j].rate) {
                    marketExists = true;
                    break;
                }
            }
            
            // If the market is being removed, check if it still has tokens
            if(!marketExists) {
                DataStore centuariDataStore = DataStore(ICentuari(centuari).getDataStore(previousMarkets[i].marketConfig));
                address bondToken = centuariDataStore.getAddress(CentuariDSLib.getBondTokenAddressKey(previousMarkets[i].rate));
                if(bondToken != address(0) && IERC20(bondToken).balanceOf(address(vault)) > 0) {
                    revert CentuariPrimeErrorsLib.InsufficientShares();
                }
            }
        }

        //Check if the market is active
        for(uint256 i = 0; i < supplyQueue.length; i++) {
            DataStore centuariDataStore = DataStore(ICentuari(centuari).getDataStore(supplyQueue[i].marketConfig));
            if(!centuariDataStore.getBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL)
                || centuariDataStore.getAddress(CentuariDSLib.getBondTokenAddressKey(supplyQueue[i].rate)) == address(0)
                || centuariDataStore.getUint(CentuariDSLib.MATURITY_UINT256) <= block.timestamp
            ) {
                revert CentuariPrimeErrorsLib.MarketNotActive();
            }
        }

        // Set the supply queue
        vault.setBytes(CentuariPrimeDSLib.getSupplyQueueKey(), abi.encode(supplyQueue));
    }
}
