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
import {Id, MarketConfig, VaultConfig, VaultMarketSupplyConfig, VaultMarketWithdrawConfig} from "../types/CommonTypes.sol";

// Internal imports - libraries
import {MarketConfigLib} from "../libraries/MarketConfigLib.sol";
import {VaultConfigLib} from "../libraries/VaultConfigLib.sol";
import {CentuariPrimeDSLib} from "../libraries/centuari-prime/CentuariPrimeDSLib.sol";
import {CentuariPrimeErrorsLib} from "../libraries/centuari-prime/CentuariPrimeErrorsLib.sol";
import {CentuariPrimeEventsLib} from "../libraries/centuari-prime/CentuariPrimeEventsLib.sol";
import {CentuariPrimeToken} from "./CentuariPrimeToken.sol";
import {CentuariDSLib} from "../libraries/centuari/CentuariDSLib.sol";

contract CentuariPrime is Ownable, ReentrancyGuard {
    using VaultConfigLib for VaultConfig;
    using MarketConfigLib for MarketConfig;
    using SafeERC20 for IERC20;

    mapping(Id => address) public vaults;

    address public centuariCLOB;
    ICentuari public CENTUARI;

    modifier onlyActiveVault(Id id) {
        if(vaults[id] == address(0)) {revert CentuariPrimeErrorsLib.VaultDoesNotExist();}
        if(!DataStore(vaults[id]).getBool(CentuariPrimeDSLib.IS_ACTIVE_BOOL)) {revert CentuariPrimeErrorsLib.VaultInactive();}
        _;
    }

    modifier onlyVaultOwner(Id id) {
        if(msg.sender != DataStore(vaults[id]).getAddress(CentuariPrimeDSLib.CURATOR_ADDRESS)) {revert CentuariPrimeErrorsLib.OnlyVaultOwner();}
        _;
    }

    constructor(address owner_, address centuariCLOB_, address centuari_) Ownable(owner_) {
        centuariCLOB = centuariCLOB_;
        CENTUARI = ICentuari(centuari_);
    }

    function setCentuariCLOB(address centuariCLOB_) external onlyOwner {
        centuariCLOB = centuariCLOB_;
    }

    function setCentuari(address centuari_) external onlyOwner {
        CENTUARI = ICentuari(centuari_);
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

        emit CentuariPrimeEventsLib.CreateVault(msg.sender, address(vault), config.token, config.name);
    }

    function deposit(VaultConfig memory config, uint256 amount) 
        external 
        onlyActiveVault(config.id())
        onlyVaultOwner(config.id())
        nonReentrant 
    {
        // Get the vault's data store
        DataStore vault = DataStore(vaults[config.id()]);
        
        // For existing vaults with positions, accrue interest first
        if (vault.getUint(CentuariPrimeDSLib.TOTAL_SHARES_UINT256) > 0) {
            _accrueInterest(vault);
        }
        
        // Calculate shares to mint
        uint256 shares = _calculateSharesToMint(vault, amount);
        
        // Get or create the vault token
        address tokenAddress = vault.getAddress(CentuariPrimeDSLib.CENTUARI_PRIME_TOKEN_ADDRESS);
        if (tokenAddress == address(0)) {
            // First deposit - create the token
            string memory name = vault.getString(CentuariPrimeDSLib.NAME_STRING);
            CentuariPrimeToken centuariPrimeToken = new CentuariPrimeToken(vault.getAddress(CentuariPrimeDSLib.CURATOR_ADDRESS), name);
            vault.setAddress(CentuariPrimeDSLib.CENTUARI_PRIME_TOKEN_ADDRESS, address(centuariPrimeToken));
            tokenAddress = address(centuariPrimeToken);
        }
        
        // Mint shares to the user
        CentuariPrimeToken(tokenAddress).mint(msg.sender, shares);
        
        // Update total shares
        uint256 totalShares = vault.getUint(CentuariPrimeDSLib.TOTAL_SHARES_UINT256);
        vault.setUint(CentuariPrimeDSLib.TOTAL_SHARES_UINT256, totalShares + shares);

        // Update total assets
        uint256 totalAssets = vault.getUint(CentuariPrimeDSLib.TOTAL_ASSETS_UINT256);
        vault.setUint(CentuariPrimeDSLib.TOTAL_ASSETS_UINT256, totalAssets + amount);
        
        // Transfer tokens from user to Centuari
        address collateralToken = vault.getAddress(CentuariPrimeDSLib.TOKEN_ADDRESS);
        IERC20(collateralToken).safeTransferFrom(msg.sender, address(CENTUARI), amount);
        
        // Supply to markets according to the supply queue
        _supplyToMarkets(vault, amount);
        
        // Emit deposit event
        emit CentuariPrimeEventsLib.Deposit(address(vault), config.curator, msg.sender, amount);
    }
    
    /**
     * @notice Calculates shares to mint based on the amount being deposited
     * @param vault The vault data store
     * @param amount The amount being deposited
     * @return shares The number of shares to mint
     */
    function _calculateSharesToMint(DataStore vault, uint256 amount) internal view returns (uint256 shares) {
        uint256 totalShares = vault.getUint(CentuariPrimeDSLib.TOTAL_SHARES_UINT256);
        uint256 totalAssets = vault.getUint(CentuariPrimeDSLib.TOTAL_ASSETS_UINT256);
        
        if (totalShares == 0) {
            shares = amount;
        } else {
            shares = (amount * totalShares) / totalAssets;
        }
    }
    
    /**
     * @notice Calculates the current total assets in the vault by querying market positions
     * @param vault The vault data store
     */
    function _accrueInterest(DataStore vault) internal {
        // Start with the base assets
        uint256 totalAssets = vault.getUint(CentuariPrimeDSLib.TOTAL_ASSETS_UINT256);
        
        // Get the supply queue (markets where funds are supplied)
        bytes memory supplyQueueBytes = vault.getBytes(CentuariPrimeDSLib.SUPPLY_QUEUE_BYTES);
        VaultMarketSupplyConfig[] memory supplyQueue = abi.decode(supplyQueueBytes, (VaultMarketSupplyConfig[]));
        
        // Calculate the total value across all markets
        for (uint256 i = 0; i < supplyQueue.length; i++) {
            MarketConfig memory marketConfig = supplyQueue[i].marketConfig;
            
            // Get market data store
            address marketDataStore = CENTUARI.getDataStore(marketConfig);
            
            // Get bond token for this rate
            address bondToken = DataStore(marketDataStore).getAddress(CentuariDSLib.getBondTokenAddressKey(supplyQueue[i].rate));
            
            // Get vault's bond token balance
            address curator = DataStore(vault).getAddress(CentuariPrimeDSLib.CURATOR_ADDRESS);
            uint256 bondBalance = IERC20(bondToken).balanceOf(curator);
            if (bondBalance == 0) continue;
            
            // Calculate value of these bonds
            CENTUARI.accrueInterest(marketConfig, supplyQueue[i].rate);
            uint256 totalMarketSupplyShares = DataStore(marketDataStore).getUint(CentuariDSLib.getTotalSuppySharesKey(supplyQueue[i].rate));
            uint256 totalMarketSupplyAssets = DataStore(marketDataStore).getUint(CentuariDSLib.getTotalSuppyAssetsKey(supplyQueue[i].rate));
            
            if (totalMarketSupplyShares > 0) {
                uint256 marketValue = (bondBalance * totalMarketSupplyAssets) / totalMarketSupplyShares;
                totalAssets += marketValue;
            }
        }
        
        vault.setUint(CentuariPrimeDSLib.TOTAL_ASSETS_UINT256, totalAssets);
    }

    function _supplyToMarkets(DataStore vault, uint256 amount) internal {
        bytes memory supplyQueueBytes = vault.getBytes(CentuariPrimeDSLib.SUPPLY_QUEUE_BYTES);
        VaultMarketSupplyConfig[] memory supplyQueue = abi.decode(supplyQueueBytes, (VaultMarketSupplyConfig[]));
        
        for (uint256 i = 0; i < supplyQueue.length; i++) {
            uint256 supplyAmount = amount;
            MarketConfig memory marketConfig = supplyQueue[i].marketConfig;
            uint256 rate = supplyQueue[i].rate;
            
            uint256 cap = supplyQueue[i].cap;
            if(cap == 0) continue;

            if(cap < amount) {
                supplyAmount = cap;
                amount -= cap;
            }

            //@todo place order to CLOB
        }
    }
    
    /**
     * @notice Allows users to withdraw their funds plus accrued interest
     * @param config The vault configuration
     * @param shares The number of shares to withdraw
     */
    function withdraw(VaultConfig memory config, uint256 shares) 
        external
        onlyActiveVault(config.id())
        onlyVaultOwner(config.id())
        nonReentrant 
    {
        if(shares == 0) {revert CentuariPrimeErrorsLib.InvalidAmount();}
        
        // Get the vault's data store
        DataStore vault = DataStore(vaults[config.id()]);
        
        // Get user's share balance
        address centuariPrimeToken = vault.getAddress(CentuariPrimeDSLib.CENTUARI_PRIME_TOKEN_ADDRESS);
        uint256 userShares = IERC20(centuariPrimeToken).balanceOf(msg.sender);
        if(userShares < shares) {revert CentuariPrimeErrorsLib.InsufficientShares();}
        
        // Accrue interest before calculating withdrawal amount
        _accrueInterest(vault);
        
        // Calculate assets to withdraw
        uint256 totalShares = vault.getUint(CentuariPrimeDSLib.TOTAL_SHARES_UINT256);
        uint256 totalAssets = vault.getUint(CentuariPrimeDSLib.TOTAL_ASSETS_UINT256);
        uint256 assets = (shares * totalAssets) / totalShares;
        
        // Update user's share balance
        CentuariPrimeToken(centuariPrimeToken).burn(msg.sender, shares);
        
        // Update total shares and assets
        vault.setUint(CentuariPrimeDSLib.TOTAL_SHARES_UINT256, totalShares - shares);
        vault.setUint(CentuariPrimeDSLib.TOTAL_ASSETS_UINT256, totalAssets - assets);

        // Withdraw from markets according to the withdraw queue
        _withdrawFromMarkets(vault, assets);
        
        // Emit withdraw event
        emit CentuariPrimeEventsLib.Withdraw(address(vault), config.curator, msg.sender, assets);
    }

    function _withdrawFromMarkets(DataStore vault, uint256 assets) internal {
        bytes memory withdrawQueueBytes = vault.getBytes(CentuariPrimeDSLib.WITHDRAW_QUEUE_BYTES);
        VaultMarketWithdrawConfig[] memory withdrawQueue = abi.decode(withdrawQueueBytes, (VaultMarketWithdrawConfig[]));
        
        uint256 totalWithdrawn = 0;
        uint256 remaining = assets;
        for (uint256 i = 0; i < withdrawQueue.length; i++) {
            MarketConfig memory marketConfig = withdrawQueue[i].marketConfig;
            uint256 rate = withdrawQueue[i].rate;
            
            address vaultBondToken = DataStore(CENTUARI.getDataStore(marketConfig)).getAddress(CentuariDSLib.getBondTokenAddressKey(rate));
            uint256 vaultBondBalance = IERC20(vaultBondToken).balanceOf(msg.sender); //Get vault bond token from curator
            uint256 withdrawAmount = remaining;
            if(vaultBondBalance < remaining) {
                withdrawAmount = vaultBondBalance;
            }
            remaining -= withdrawAmount;

            CENTUARI.withdraw(marketConfig, rate, withdrawAmount);
            totalWithdrawn += withdrawAmount;
        }
        if(remaining > 0) {revert CentuariPrimeErrorsLib.InsufficientLiquidity();}
        address loanToken = vault.getAddress(CentuariPrimeDSLib.TOKEN_ADDRESS);
        IERC20(loanToken).safeTransfer(msg.sender, totalWithdrawn);
    }

    function setSupplyQueue(VaultConfig memory config, VaultMarketSupplyConfig[] memory supplyQueue) 
        external
        onlyActiveVault(config.id())
        onlyVaultOwner(config.id())
    {
        // Get the vault's data store
        DataStore vault = DataStore(vaults[config.id()]);

        // Check if the vault still has tokens in markets that are being removed
        bytes memory previousMarketBytes = vault.getBytes(CentuariPrimeDSLib.SUPPLY_QUEUE_BYTES);
        VaultMarketSupplyConfig[] memory previousMarkets = abi.decode(previousMarketBytes, (VaultMarketSupplyConfig[]));
        
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
                DataStore centuariDataStore = DataStore(CENTUARI.getDataStore(previousMarkets[i].marketConfig));
                address bondToken = centuariDataStore.getAddress(CentuariDSLib.getBondTokenAddressKey(previousMarkets[i].rate));
                if(bondToken != address(0) && IERC20(bondToken).balanceOf(address(vault)) > 0) {
                    revert CentuariPrimeErrorsLib.RemoveMarketNotAllowed(
                        previousMarkets[i].marketConfig.loanToken, 
                        previousMarkets[i].marketConfig.collateralToken, 
                        previousMarkets[i].marketConfig.maturity, 
                        previousMarkets[i].rate
                    );
                }
            }
        }

        // Validate all markets in the queue
        bytes32[] memory seenMarkets = new bytes32[](supplyQueue.length);
        uint256 seenCount = 0;
        
        for(uint256 i = 0; i < supplyQueue.length; i++) {
            VaultMarketSupplyConfig memory market = supplyQueue[i];
            
            // Check if market is active
            DataStore centuariDataStore = DataStore(CENTUARI.getDataStore(market.marketConfig));
            if(!centuariDataStore.getBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL)
                || centuariDataStore.getAddress(CentuariDSLib.getBondTokenAddressKey(market.rate)) == address(0)
                || centuariDataStore.getUint(CentuariDSLib.MATURITY_UINT256) <= block.timestamp
                || vault.getAddress(CentuariPrimeDSLib.TOKEN_ADDRESS) != centuariDataStore.getAddress(CentuariDSLib.LOAN_TOKEN_ADDRESS)
            ) {
                revert CentuariPrimeErrorsLib.InvalidMarket(
                    market.marketConfig.loanToken, 
                    market.marketConfig.collateralToken, 
                    market.marketConfig.maturity, 
                    market.rate
                );
            }
            
            // Check for valid cap
            if(market.cap == 0) { 
                revert CentuariPrimeErrorsLib.InvalidCap();
            }
            
            // Check for duplicates using a more efficient approach
            bytes32 marketKey = keccak256(abi.encodePacked(
                Id.unwrap(market.marketConfig.id()),
                market.rate
            ));
            
            for (uint256 j = 0; j < seenCount; j++) {
                if (seenMarkets[j] == marketKey) {
                    revert CentuariPrimeErrorsLib.DuplicateVaultMarketConfig(
                        market.marketConfig.loanToken,
                        market.marketConfig.collateralToken,
                        market.marketConfig.maturity,
                        market.rate
                    );
                }
            }
            
            // Add to seen markets
            seenMarkets[seenCount] = marketKey;
            seenCount++;
        }

        // Set the supply queue
        vault.setBytes(CentuariPrimeDSLib.SUPPLY_QUEUE_BYTES, abi.encode(supplyQueue));
        emit CentuariPrimeEventsLib.SetSupplyQueue(msg.sender, address(vault), supplyQueue);
    }
    
    function setWithdrawQueue(VaultConfig memory config, VaultMarketWithdrawConfig[] memory withdrawQueue) 
        external
        onlyActiveVault(config.id())
        onlyVaultOwner(config.id())
    {
        // Get the vault's data store
        DataStore vault = DataStore(vaults[config.id()]);
        
        // Validate all markets in the queue
        bytes32[] memory seenMarkets = new bytes32[](withdrawQueue.length);
        uint256 seenCount = 0;
        
        for(uint256 i = 0; i < withdrawQueue.length; i++) {
            VaultMarketWithdrawConfig memory market = withdrawQueue[i];
            
            // Check if market is active
            DataStore centuariDataStore = DataStore(CENTUARI.getDataStore(market.marketConfig));
            if(centuariDataStore.getAddress(CentuariDSLib.getBondTokenAddressKey(market.rate)) == address(0)
                || vault.getAddress(CentuariPrimeDSLib.TOKEN_ADDRESS) != centuariDataStore.getAddress(CentuariDSLib.LOAN_TOKEN_ADDRESS)
            ) {
                revert CentuariPrimeErrorsLib.InvalidMarket(
                    market.marketConfig.loanToken, 
                    market.marketConfig.collateralToken, 
                    market.marketConfig.maturity, 
                    market.rate
                );
            }
            
            // Check for duplicates using a more efficient approach
            bytes32 marketKey = keccak256(abi.encodePacked(
                Id.unwrap(market.marketConfig.id()),
                market.rate
            ));
            
            for (uint256 j = 0; j < seenCount; j++) {
                if (seenMarkets[j] == marketKey) {
                    revert CentuariPrimeErrorsLib.DuplicateVaultMarketConfig(
                        market.marketConfig.loanToken,
                        market.marketConfig.collateralToken,
                        market.marketConfig.maturity,
                        market.rate
                    );
                }
            }
            
            // Add to seen markets
            seenMarkets[seenCount] = marketKey;
            seenCount++;
        }

        // Set the withdraw queue
        vault.setBytes(CentuariPrimeDSLib.WITHDRAW_QUEUE_BYTES, abi.encode(withdrawQueue));
        emit CentuariPrimeEventsLib.SetWithdrawQueue(msg.sender, address(vault), withdrawQueue);
    }

    function reallocate(VaultConfig memory config) external onlyActiveVault(config.id()) onlyVaultOwner(config.id()) {
        //@todo implement reallocate
    }
    
}
