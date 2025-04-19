// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// External imports
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Internal imports - interfaces
import {ICentuari} from "../interfaces/ICentuari.sol";
import {ICentuariFlashLoanCallback} from "../interfaces/ICentuariCallbacks.sol";
import {IMockOracle} from "../interfaces/IMockOracle.sol";

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
    using SafeERC20 for IERC20;

    mapping(Id => address) public dataStores;
    address public centuariCLOB;

    modifier onlyActiveMarket(Id id) {
        DataStore dataStore = DataStore(dataStores[id]);

        if (!dataStore.getBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL)) {
            revert CentuariErrorsLib.MarketNotActive();
        }

        if (block.timestamp >= dataStore.getUint(CentuariDSLib.MATURITY_UINT256)) {
            dataStore.setBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL, false);
            revert CentuariErrorsLib.MarketExpired();
        }
        _;
    }

    modifier onlyActiveRate(Id id, uint256 rate) {
        if (DataStore(dataStores[id]).getAddress(CentuariDSLib.getBondTokenAddressKey(rate)) == address(0)) {
            revert CentuariErrorsLib.RateNotActive();
        }
        _;
    }

    modifier onlyCentuariCLOB() {
        if (msg.sender != centuariCLOB) revert CentuariErrorsLib.OnlyCentuariCLOB();
        _;
    }

    constructor(address owner_) Ownable(owner_) {}

    function setCentuariCLOB(address centuariCLOB_) external onlyOwner {
        centuariCLOB = centuariCLOB_;
    }

    function createDataStore(MarketConfig memory config) external onlyCentuariCLOB {
        // Validate market config
        if (
            config.loanToken == address(0) || config.collateralToken == address(0) || config.maturity <= block.timestamp
        ) revert CentuariErrorsLib.InvalidMarketConfig();

        Id marketConfigId = config.id();
        DataStore dataStore = new DataStore(owner(), address(this));
        dataStores[marketConfigId] = address(dataStore);

        // Set data store data
        dataStore.setAddress(CentuariDSLib.LOAN_TOKEN_ADDRESS, config.loanToken);
        dataStore.setAddress(CentuariDSLib.COLLATERAL_TOKEN_ADDRESS, config.collateralToken);
        dataStore.setUint(CentuariDSLib.MATURITY_UINT256, config.maturity);
        dataStore.setBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL, true);

        emit CentuariEventsLib.CreateDataStore(address(dataStore), config.loanToken, config.collateralToken, config.maturity);
    }

    function setDataStore(MarketConfig memory config, address dataStore) external onlyOwner {
        //Validate market config
        if (
            config.loanToken == address(0) || config.collateralToken == address(0) || config.maturity <= block.timestamp
        ) revert CentuariErrorsLib.InvalidMarketConfig();

        dataStores[config.id()] = dataStore;

        emit CentuariEventsLib.SetDataStore(dataStore, config.loanToken, config.collateralToken, config.maturity);
    }

    function getDataStore(MarketConfig memory config) external view returns (address) {
        return dataStores[config.id()];
    }

    function setLltv(MarketConfig memory config, uint256 lltv_) external onlyOwner onlyActiveMarket(config.id()) {
        if (lltv_ == 0 || lltv_ > 100e16) revert CentuariErrorsLib.InvalidLltv();
        DataStore(dataStores[config.id()]).setUint(CentuariDSLib.LLTV_UINT256, lltv_);
        emit CentuariEventsLib.LltvUpdated(config.id(), lltv_);
    }

    function setOracle(MarketConfig memory config, address oracle_) external onlyOwner onlyActiveMarket(config.id()) {
        if (oracle_ == address(0)) revert CentuariErrorsLib.InvalidOracle();
        DataStore(dataStores[config.id()]).setAddress(CentuariDSLib.ORACLE_ADDRESS, oracle_);
        emit CentuariEventsLib.OracleUpdated(config.id(), oracle_);
    }

    function _isHealthy(Id id, uint256 rate, address user) internal view returns (bool) {
        DataStore dataStore = DataStore(dataStores[id]);

        uint256 collateralPrice = IMockOracle(dataStore.getAddress(CentuariDSLib.ORACLE_ADDRESS)).price();
        uint256 collateralDecimals = 10 ** IERC20Metadata(dataStore.getAddress(CentuariDSLib.COLLATERAL_TOKEN_ADDRESS)).decimals();

        uint256 borrowedValue = (
            dataStore.getUint(CentuariDSLib.getUserBorrowSharesKey(rate, user))
                * dataStore.getUint(CentuariDSLib.getTotalBorrowAssetsKey(rate))
        ) / dataStore.getUint(CentuariDSLib.getTotalBorrowSharesKey(rate));
        uint256 collateralValue =
            (dataStore.getUint(CentuariDSLib.getUserCollateralKey(rate, user)) * collateralPrice) / collateralDecimals;
        uint256 maxBorrowedValue = (collateralValue * dataStore.getUint(CentuariDSLib.LLTV_UINT256)) / 1e18;

        return borrowedValue <= maxBorrowedValue;
    }

    function accrueInterest(MarketConfig memory config, uint256 rate)
        external
        onlyActiveRate(config.id(), rate)
        onlyActiveMarket(config.id())
    {
        _accrueInterest(config.id(), rate);
    }

    function _accrueInterest(Id id, uint256 rate) internal {
        DataStore dataStore = DataStore(dataStores[id]);
        uint256 totalBorrowAssets = dataStore.getUint(CentuariDSLib.getTotalBorrowAssetsKey(rate));
        uint256 interestPerYear = (totalBorrowAssets * rate) / 1e18;

        // Cap time passed at maturity
        uint256 timePassed;
        uint256 maxLastTimestamp;
        if (block.timestamp > dataStore.getUint(CentuariDSLib.MATURITY_UINT256)) {
            timePassed =
                dataStore.getUint(CentuariDSLib.MATURITY_UINT256) - dataStore.getUint(CentuariDSLib.getLastAccrueKey(rate));
            maxLastTimestamp = dataStore.getUint(CentuariDSLib.MATURITY_UINT256);
        } else {
            timePassed = block.timestamp - dataStore.getUint(CentuariDSLib.getLastAccrueKey(rate));
            maxLastTimestamp = block.timestamp;
        }

        uint256 interest = (interestPerYear * timePassed) / 365 days;

        dataStore.setUint(
            CentuariDSLib.getTotalSuppyAssetsKey(rate),
            dataStore.getUint(CentuariDSLib.getTotalSuppyAssetsKey(rate)) + interest
        );
        dataStore.setUint(
            CentuariDSLib.getTotalBorrowAssetsKey(rate),
            dataStore.getUint(CentuariDSLib.getTotalBorrowAssetsKey(rate)) + interest
        );
        dataStore.setUint(CentuariDSLib.getLastAccrueKey(rate), maxLastTimestamp);
    }

    function addRate(MarketConfig memory config, uint256 rate_) external onlyCentuariCLOB onlyActiveMarket(config.id()) {
        DataStore dataStore = DataStore(dataStores[config.id()]);
        if (dataStore.getAddress(CentuariDSLib.getBondTokenAddressKey(rate_)) != address(0)) {
            revert CentuariErrorsLib.RateAlreadyExists();
        }
        if (rate_ == 0 || rate_ == 100e16) revert CentuariErrorsLib.InvalidRate();

        dataStore.setUint(CentuariDSLib.getLastAccrueKey(rate_), block.timestamp);

        //Create new Bond Token
        BondToken.BondTokenConfig memory bondTokenConfig = BondToken.BondTokenConfig({
            loanToken: config.loanToken,
            collateralToken: config.collateralToken,
            rate: rate_,
            maturity: config.maturity,
            maturityMonth: DateLib.getMonth(config.maturity),
            maturityYear: DateLib.getYear(config.maturity),
            decimals: IERC20Metadata(config.loanToken).decimals()
        });
        BondToken bondToken = new BondToken(address(this), bondTokenConfig);
        dataStore.setAddress(CentuariDSLib.getBondTokenAddressKey(rate_), address(bondToken));

        emit CentuariEventsLib.RateAdded(rate_);
        emit CentuariEventsLib.BondTokenCreated(address(bondToken), rate_);
    }

    function supply(MarketConfig memory config, uint256 rate, address user, uint256 amount)
        external
        nonReentrant
        onlyCentuariCLOB
        onlyActiveMarket(config.id())
        onlyActiveRate(config.id(), rate)
    {
        if (user == address(0)) revert CentuariErrorsLib.InvalidUser();
        if (amount == 0) revert CentuariErrorsLib.InvalidAmount();
        _accrueInterest(config.id(), rate);

        DataStore dataStore = DataStore(dataStores[config.id()]);
        uint256 totalSupplyShares = dataStore.getUint(CentuariDSLib.getTotalSuppySharesKey(rate));
        uint256 totalSupplyAssets = dataStore.getUint(CentuariDSLib.getTotalSuppyAssetsKey(rate));

        uint256 shares = 0;
        if (totalSupplyShares == 0) {
            shares = amount;
        } else {
            shares = (amount * totalSupplyShares) / totalSupplyAssets;
        }

        dataStore.setUint(CentuariDSLib.getTotalSuppySharesKey(rate), totalSupplyShares + shares);
        dataStore.setUint(CentuariDSLib.getTotalSuppyAssetsKey(rate), totalSupplyAssets + amount);

        // mint tokenized bond to the lender
        BondToken(dataStore.getAddress(CentuariDSLib.getBondTokenAddressKey(rate))).mint(user, shares);

        emit CentuariEventsLib.Supply(user, rate, shares, amount);
    }

    function borrow(MarketConfig memory config, uint256 rate, address user, uint256 amount)
        external
        nonReentrant
        onlyCentuariCLOB
        onlyActiveMarket(config.id())
        onlyActiveRate(config.id(), rate)
    {
        if (user == address(0)) revert CentuariErrorsLib.InvalidUser();
        if (amount == 0) revert CentuariErrorsLib.InvalidAmount();
        _accrueInterest(config.id(), rate);

        DataStore dataStore = DataStore(dataStores[config.id()]);
        uint256 totalBorrowShares = dataStore.getUint(CentuariDSLib.getTotalBorrowSharesKey(rate));
        uint256 totalBorrowAssets = dataStore.getUint(CentuariDSLib.getTotalBorrowAssetsKey(rate));

        uint256 shares = 0;
        if (totalBorrowShares == 0) {
            shares = amount;
        } else {
            shares = (amount * totalBorrowShares) / totalBorrowAssets;
        }

        dataStore.setUint(
            CentuariDSLib.getUserBorrowSharesKey(rate, user),
            dataStore.getUint(CentuariDSLib.getUserBorrowSharesKey(rate, user)) + shares
        );
        dataStore.setUint(CentuariDSLib.getTotalBorrowSharesKey(rate), totalBorrowShares + shares);
        dataStore.setUint(CentuariDSLib.getTotalBorrowAssetsKey(rate), totalBorrowAssets + amount);

        if (!_isHealthy(config.id(), rate, user)) revert CentuariErrorsLib.InsufficientCollateral();

        emit CentuariEventsLib.Borrow(user, rate, shares, amount);
    }

    function withdraw(MarketConfig memory config, uint256 rate, uint256 shares)
        external
        nonReentrant
        onlyActiveRate(config.id(), rate)
    {
        if (shares == 0) revert CentuariErrorsLib.InvalidAmount();
        if (block.timestamp < config.maturity) revert CentuariErrorsLib.MarketNotMature();

        DataStore dataStore = DataStore(dataStores[config.id()]);
        uint256 totalSupplyShares = dataStore.getUint(CentuariDSLib.getTotalSuppySharesKey(rate));
        uint256 totalSupplyAssets = dataStore.getUint(CentuariDSLib.getTotalSuppyAssetsKey(rate));
        address loanTokenAddress = dataStore.getAddress(CentuariDSLib.LOAN_TOKEN_ADDRESS);
        address bondTokenAddress = dataStore.getAddress(CentuariDSLib.getBondTokenAddressKey(rate));

        if (IERC20(bondTokenAddress).balanceOf(msg.sender) < shares) revert CentuariErrorsLib.InsufficientShares();
        _accrueInterest(config.id(), rate);

        // Calculate amount to withdraw including interest
        uint256 amount = (shares * totalSupplyAssets) / totalSupplyShares;

        if (IERC20(loanTokenAddress).balanceOf(address(this)) < amount) {
            revert CentuariErrorsLib.InsufficientLiquidity();
        }

        dataStore.setUint(CentuariDSLib.getTotalSuppySharesKey(rate), totalSupplyShares - shares);
        dataStore.setUint(CentuariDSLib.getTotalSuppyAssetsKey(rate), totalSupplyAssets - amount);

        BondToken(bondTokenAddress).burn(msg.sender, shares);
        IERC20(loanTokenAddress).safeTransfer(msg.sender, amount);

        emit CentuariEventsLib.Withdraw(msg.sender, rate, shares, amount);
    }

    function supplyCollateral(MarketConfig memory config, uint256 rate, address user, uint256 amount)
        external
        nonReentrant
        onlyCentuariCLOB
        onlyActiveMarket(config.id())
        onlyActiveRate(config.id(), rate)
    {
        if (user == address(0)) revert CentuariErrorsLib.InvalidUser();
        if (amount == 0) revert CentuariErrorsLib.InvalidAmount();
        _accrueInterest(config.id(), rate);

        DataStore dataStore = DataStore(dataStores[config.id()]);

        dataStore.setUint(
            CentuariDSLib.getUserCollateralKey(rate, user),
            dataStore.getUint(CentuariDSLib.getUserCollateralKey(rate, user)) + amount
        );

        emit CentuariEventsLib.SupplyCollateral(user, rate, amount);
    }

    function withdrawCollateral(MarketConfig memory config, uint256 rate, uint256 amount)
        external
        nonReentrant
        onlyActiveRate(config.id(), rate)
    {
        if (amount == 0) revert CentuariErrorsLib.InvalidAmount();

        DataStore dataStore = DataStore(dataStores[config.id()]);

        uint256 userCollateral = dataStore.getUint(CentuariDSLib.getUserCollateralKey(rate, msg.sender));
        if (userCollateral < amount) revert CentuariErrorsLib.InsufficientCollateral();

        _accrueInterest(config.id(), rate);

        dataStore.setUint(CentuariDSLib.getUserCollateralKey(rate, msg.sender), userCollateral - amount);

        if (!_isHealthy(config.id(), rate, msg.sender)) revert CentuariErrorsLib.InsufficientCollateral();

        IERC20(dataStore.getAddress(CentuariDSLib.COLLATERAL_TOKEN_ADDRESS)).safeTransfer(msg.sender, amount);

        emit CentuariEventsLib.WithdrawCollateral(msg.sender, rate, amount);
    }

    function repay(MarketConfig memory config, uint256 rate, uint256 amount)
        external
        nonReentrant
        onlyActiveMarket(config.id())
        onlyActiveRate(config.id(), rate)
    {
        if (amount == 0) revert CentuariErrorsLib.InvalidAmount();
        _accrueInterest(config.id(), rate);

        DataStore dataStore = DataStore(dataStores[config.id()]);
        uint256 totalBorrowShares = dataStore.getUint(CentuariDSLib.getTotalBorrowSharesKey(rate));
        uint256 totalBorrowAssets = dataStore.getUint(CentuariDSLib.getTotalBorrowAssetsKey(rate));
        uint256 userBorrowShares = dataStore.getUint(CentuariDSLib.getUserBorrowSharesKey(rate, msg.sender));

        if (userBorrowShares < amount) revert CentuariErrorsLib.InsufficientBorrowShares();

        uint256 borrowAmount = (amount * totalBorrowAssets) / totalBorrowShares;

        dataStore.setUint(CentuariDSLib.getUserBorrowSharesKey(rate, msg.sender), userBorrowShares - amount);
        dataStore.setUint(CentuariDSLib.getTotalBorrowSharesKey(rate), totalBorrowShares - amount);
        dataStore.setUint(CentuariDSLib.getTotalBorrowAssetsKey(rate), totalBorrowAssets - borrowAmount);

        IERC20(dataStore.getAddress(CentuariDSLib.LOAN_TOKEN_ADDRESS)).safeTransferFrom(
            msg.sender, address(this), borrowAmount
        );

        emit CentuariEventsLib.Repay(msg.sender, rate, borrowAmount);
    }

    function liquidate(MarketConfig memory config, uint256 rate, address user)
        external
        nonReentrant
        onlyActiveRate(config.id(), rate)
    {
        if (user == address(0)) revert CentuariErrorsLib.InvalidUser();
        if (block.timestamp > config.maturity || !_isHealthy(config.id(), rate, user)) {
            revert CentuariErrorsLib.LiquidationNotAllowed();
        }

        DataStore dataStore = DataStore(dataStores[config.id()]);

        uint256 totalBorrowShares = dataStore.getUint(CentuariDSLib.getTotalBorrowSharesKey(rate));
        uint256 totalBorrowAssets = dataStore.getUint(CentuariDSLib.getTotalBorrowAssetsKey(rate));
        uint256 userBorrowShares = dataStore.getUint(CentuariDSLib.getUserBorrowSharesKey(rate, user));
        uint256 userCollateral = dataStore.getUint(CentuariDSLib.getUserCollateralKey(rate, user));

        uint256 debt = (userBorrowShares * totalBorrowAssets) / totalBorrowShares;

        dataStore.setUint(CentuariDSLib.getTotalBorrowSharesKey(rate), totalBorrowShares - userBorrowShares);
        dataStore.setUint(CentuariDSLib.getTotalBorrowAssetsKey(rate), totalBorrowAssets - debt);
        dataStore.setUint(CentuariDSLib.getUserBorrowSharesKey(rate, user), 0);
        dataStore.setUint(CentuariDSLib.getUserCollateralKey(rate, user), 0);

        //Get token from liquidator
        IERC20(dataStore.getAddress(CentuariDSLib.LOAN_TOKEN_ADDRESS)).safeTransferFrom(msg.sender, address(this), debt);
        //Send collateral to liquidator
        IERC20(dataStore.getAddress(CentuariDSLib.COLLATERAL_TOKEN_ADDRESS)).safeTransfer(msg.sender, userCollateral);

        emit CentuariEventsLib.Liquidate(msg.sender, rate, user, userBorrowShares, userCollateral);
    }

    function getUserCollateral(MarketConfig memory config, uint256 rate, address user)
        external
        view
        returns (uint256)
    {
        return DataStore(dataStores[config.id()]).getUint(CentuariDSLib.getUserCollateralKey(rate, user));
    }

    function getUserBorrowShares(MarketConfig memory config, uint256 rate, address user)
        external
        view
        returns (uint256)
    {
        return DataStore(dataStores[config.id()]).getUint(CentuariDSLib.getUserBorrowSharesKey(rate, user));
    }

    function flashLoan(address token, uint256 amount, bytes calldata data) external {
        if (amount == 0) revert CentuariErrorsLib.InvalidAmount();
        emit CentuariEventsLib.FlashLoan(msg.sender, token, amount);

        IERC20(token).safeTransfer(msg.sender, amount);

        ICentuariFlashLoanCallback(msg.sender).onCentuariFlashLoan(token, amount, data);

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function transferFrom(MarketConfig memory config, address token, address from, address to, uint256 amount) external onlyCentuariCLOB nonReentrant {
        IERC20(token).safeTransferFrom(from, to, amount);
        emit CentuariEventsLib.TransferFrom(config.id(), token, from, to, amount);
    }

    function liquidateUncollaterizeLoand() external {
        //@todo call slashing AVS
        //check if collateral is already in Centuari vault
        //liquidate the user 
    }

}
