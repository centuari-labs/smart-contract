// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// External imports
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";

// Internal imports - interfaces
import {ICentuari} from "../interfaces/ICentuari.sol";

// Internal imports - libraries
import {MarketConfigLib} from "../libraries/MarketConfigLib.sol";
import {DateLib} from "../libraries/DateLib.sol";
import {CentuariDSLib} from "../libraries/Centuari/CentuariDSLib.sol";
import {CentuariErrorsLib} from "../libraries/Centuari/CentuariErrorsLib.sol";
import {CentuariEventsLib} from "../libraries/Centuari/CentuariEventsLib.sol";

// Internal imports - types
import {Id, MarketConfig} from "../types/CommonTypes.sol";

// Internal imports - contracts
import {BondToken} from "./BondToken.sol";
import {DataStore} from "./DataStore.sol";

contract Centuari is ICentuari, Ownable, ReentrancyGuard {
    using MarketConfigLib for MarketConfig;

    mapping(Id => address) public dataStores;

    modifier onlyBeforeMaturity(Id id) {
        DataStore dataStore = dataStores[id];
        
        if (!dataStore.getBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL)) {
            revert MarketNotActive();
        }

        if (block.timestamp >= dataStore.getUint(CentuariDSLib.MATURITY_UINT256)) {
            dataStore.setBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL, false);
            revert MarketExpired();
        }
        _;
    }

    constructor(address owner_) Ownable(owner_) {}

    function createDataStore(MarketConfig memory config) external {
        // Validate market config
        require(config.loanToken != address(0), CentuariErrorsLib.INVALID_MARKET_CONFIG);
        require(config.collateralToken != address(0), CentuariErrorsLib.INVALID_MARKET_CONFIG);
        require(config.maturity > block.timestamp, CentuariErrorsLib.INVALID_MARKET_CONFIG);

        Id marketConfigId = config.id();
        DataStore storage dataStore = dataStores[marketConfigId];
        dataStore.setAddress(CentuariDSLib.LOAN_TOKEN_ADDRESS, config.loanToken);
        dataStore.setAddress(CentuariDSLib.COLLATERAL_TOKEN_ADDRESS, config.collateralToken);
        dataStore.setUint(CentuariDSLib.MATURITY_UINT256, config.maturity);
        dataStore.setBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL, true);
    }

    function setDataStore(MarketConfig memory config, address dataStore) external onlyOwner {
        //Validate market config
        require(config.loanToken != address(0), CentuariErrorsLib.INVALID_MARKET_CONFIG);
        require(config.collateralToken != address(0), CentuariErrorsLib.INVALID_MARKET_CONFIG);
        require(config.maturity > block.timestamp, CentuariErrorsLib.INVALID_MARKET_CONFIG);

        Id marketConfigId = config.id();
        dataStores[marketConfigId] = dataStore;
    }

    function setLltv(MarketConfig memory config, uint256 lltv_) external onlyOwner {
        //TODO: Check if market is available
        if(lltv_ == 0 || lltv_ > 100e16) revert InvalidLltv();
        dataStores[config.id()].setUint(CentuariDSLib.LLTV_UINT256, lltv_);
    }

    function setOracle(MarketConfig memory config, address oracle_) external onlyOwner {
        //TODO: Check if market is available
        if(oracle_ == address(0)) revert InvalidOracle();
        dataStores[config.id()].setAddress(CentuariDSLib.ORACLE_ADDRESS, oracle_);
    }

    function isHealthy(address user) external view returns (bool) {
        //TODO: Add Logic
        return true;
    }

    function addBorrowRate(MarketConfig memory config, uint256 borrowRate_) external override onlyBeforeMaturity(config.id()) {
        if (dataStores[config.id()].getBool(CentuariDSLib.getIsPoolActiveKey(borrowRate_))) revert BorrowRateAlreadyExists();
        if (borrowRate_ == 0 || borrowRate_ == 100e16) revert InvalidBorrowRate();

        dataStores[config.id()].setUint(CentuariDSLib.getLastAccrueKey(borrowRate_), block.timestamp);

        //Create new Bond Token
        BondToken.BondTokenConfig memory bondTokenConfig = BondToken.BondTokenConfig({
            debtToken: config.loanToken,
            collateralToken: config.collateralToken,
            maturity: config.maturity,
            maturityMonth: DateLib.getMonth(config.maturity),
            maturityYear: DateLib.getYear(config.maturity)
        });
        BondToken bondToken = new BondToken(address(this), bondTokenConfig);
        dataStores[config.id()].setAddress(CentuariDSLib.getBondTokenAddressKey(borrowRate_), address(bondToken));

        emit CentuariEventsLib.BorrowRateAdded(borrowRate_);
        emit CentuariEventsLib.BondTokenCreated(address(bondToken), borrowRate_);
    }

    function supply(MarketConfig memory config, int256 borrowRate, address user, uint256 amount) external override nonReentrant onlyBeforeMaturity(config.id()){
        if (user == address(0)) revert InvalidUser();
        if (amount == 0) revert InvalidAmount();
        _accrueInterest(config.id(),borrowRate);

        DataStore dataStore = dataStores[config.id()];
        uint256 totalSupplyShares = dataStore.getUint(CentuariDSLib.getTotalSuppySharesKey(borrowRate));
        uint256 totalSupplyAssets = dataStore.getUint(CentuariDSLib.getTotalSuppyAssetsKey(borrowRate));

        uint256 shares = 0;
        if (totalSupplyShares == 0) {
            shares = amount;
        } else {
            shares =
                (amount * totalSupplyShares) /
                totalSupplyAssets;
        }

        dataStore.setUint(CentuariDSLib.getTotalSuppySharesKey(borrowRate), totalSupplyShares + shares);
        dataStore.setUint(CentuariDSLib.getTotalSuppyAssetsKey(borrowRate), totalSupplyAssets + amount);

        // mint tokenized bond to the lender
        BondToken(dataStore.getAddress(CentuariDSLib.getBondTokenAddressKey(borrowRate))).mint(user, shares);

        emit CentuariEventsLib.Supply(borrowRate, user, shares, amount);
    }

    function borrow(uint256 borrowRate, address user, uint256 amount) external override {
        //TODO: Add Logic
    }

    function withdraw(uint256 borrowRate, uint256 shares) external override {
        //TODO: Add Logic
    }

    function supplyCollateral(uint256 borrowRate, address user, uint256 amount) external override {
        //TODO: Add Logic
    }

    function withdrawCollateral(uint256 borrowRate, uint256 amount) external override {
        //TODO: Add Logic
    }

    function repay(uint256 borrowRate, uint256 amount) external override {
        //TODO: Add Logic
    }

    function accrueInterest(MarketConfig memory config, uint256 borrowRate) external override onlyBeforeMaturity(config.id()) {
        _accrueInterest(config.id(),borrowRate);
    }

    function _accrueInterest(Id id, uint256 borrowRate) internal {
        DataStore dataStore = dataStores[id];
        uint256 totalBorrowAssets = dataStore.getUint(TOTAL_BORROW_ASSETS_UINT256);
        uint256 interestPerYear = (totalBorrowAssets * borrowRate) / 1e18;

        // Cap time passed at maturity
        uint256 timePassed;
        uint256 maxLastTimestamp;
        if (block.timestamp > dataStore.getUint(MATURITY_UINT256)) {
            timePassed = dataStore.getUint(MATURITY_UINT256) - dataStore.getUint(LAST_ACCRUE_UINT256);
            maxLastTimestamp = dataStore.getUint(MATURITY_UINT256);
        } else {
            timePassed = block.timestamp - dataStore.getUint(LAST_ACCRUE_UINT256);
            maxLastTimestamp = block.timestamp;
        }

        uint256 interest = (interestPerYear * timePassed) / 365 days;

        dataStore.setUint(TOTAL_SUPPLY_ASSETS_UINT256, dataStore.getUint(TOTAL_SUPPLY_ASSETS_UINT256) + interest);
        dataStore.setUint(TOTAL_BORROW_ASSETS_UINT256, dataStore.getUint(TOTAL_BORROW_ASSETS_UINT256) + interest);
        dataStore.setUint(LAST_ACCRUE_UINT256, maxLastTimestamp);
    }

    function getUserCollateral(uint256 borrowRate, address user) external view override returns (uint256) {
        //TODO: Add Logic
        return 0;
    }

    function getUserBorrowShares(uint256 borrowRate, address user) external view override returns (uint256) {
        //TODO: Add Logic
        return 0;
    }

    function liquidate(uint256 borrowRate, address user) external override {
        //TODO: Add Logic
    }

    function flashLoan(address token, uint256 assets, bytes calldata data) external {
        //TODO: Add Logic
    }
}
