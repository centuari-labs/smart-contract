// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../../BaseTest.sol";
import {MarketConfig, Id} from "../../../src/types/CommonTypes.sol";
import {MarketConfigLib} from "../../../src/libraries/MarketConfigLib.sol";
import {Centuari} from "../../../src/core/Centuari.sol";
import {ICentuari} from "../../../src/interfaces/ICentuari.sol";
import {DataStore} from "../../../src/core/DataStore.sol";
import {CentuariDSLib} from "../../../src/libraries/Centuari/CentuariDSLib.sol";
import {CentuariErrorsLib} from "../../../src/libraries/Centuari/CentuariErrorsLib.sol";
import {CentuariEventsLib} from "../../../src/libraries/Centuari/CentuariEventsLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DataStoreIntegrationTest is BaseTest {
    using MarketConfigLib for MarketConfig;

    function test_CreateDataStore() public {
        //Change caller to Lending CLOB
        vm.prank(address(centuariCLOB));

        MarketConfig memory config = MarketConfig({
            loanToken: address(usdc),
            collateralToken: address(weth),
            maturity: block.timestamp + 100 days
        });

        //Expect CreateDataStore event
        vm.expectEmit(false, false, false, true);
        emit CentuariEventsLib.CreateDataStore(address(0), config.loanToken, config.collateralToken, config.maturity);

        ICentuari(centuari).createDataStore(config);
        address dataStore = Centuari(centuari).dataStores(config.id());
    
        assertEq(DataStore(dataStore).getAddress(CentuariDSLib.LOAN_TOKEN_ADDRESS), config.loanToken);
        assertEq(DataStore(dataStore).getAddress(CentuariDSLib.COLLATERAL_TOKEN_ADDRESS), config.collateralToken);
        assertEq(DataStore(dataStore).getUint(CentuariDSLib.MATURITY_UINT256), config.maturity);
        assertEq(DataStore(dataStore).getBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL), true);
    }

    function test_SetDataStore() public {
        //Change caller to Lending CLOB
        vm.startPrank(address(centuariCLOB));

        //Create a DataStore
        MarketConfig memory config = MarketConfig({
            loanToken: address(usdc),
            collateralToken: address(weth),
            maturity: block.timestamp + 100 days
        });

        ICentuari(centuari).createDataStore(config);
        address dataStore = Centuari(centuari).dataStores(config.id());

        //Validate if the DataStore is set with the correct values
        assertEq(centuari.dataStores(config.id()), dataStore);
        assertEq(DataStore(dataStore).getAddress(CentuariDSLib.LOAN_TOKEN_ADDRESS), config.loanToken);
        assertEq(DataStore(dataStore).getAddress(CentuariDSLib.COLLATERAL_TOKEN_ADDRESS), config.collateralToken);
        assertEq(DataStore(dataStore).getUint(CentuariDSLib.MATURITY_UINT256), config.maturity);
        assertEq(DataStore(dataStore).getBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL), true);

        ICentuari(centuari).createDataStore(config);
        address newDataStore = Centuari(centuari).dataStores(config.id());

        //Change caller to owner to call setDataStore
        vm.stopPrank();
        vm.prank(owner);

        //Expect SetDataStore event
        vm.expectEmit(true, false, false, false);
        emit CentuariEventsLib.SetDataStore(newDataStore, config.loanToken, config.collateralToken, config.maturity);

        ICentuari(centuari).setDataStore(config, newDataStore);

        //Validate if the DataStore is set with the correct values
        assertEq(centuari.dataStores(config.id()), newDataStore);
        assertEq(DataStore(newDataStore).getAddress(CentuariDSLib.LOAN_TOKEN_ADDRESS), config.loanToken);
        assertEq(DataStore(newDataStore).getAddress(CentuariDSLib.COLLATERAL_TOKEN_ADDRESS), config.collateralToken);
        assertEq(DataStore(newDataStore).getUint(CentuariDSLib.MATURITY_UINT256), config.maturity);
        assertEq(DataStore(newDataStore).getBool(CentuariDSLib.IS_MARKET_ACTIVE_BOOL), true);
    }

    function test_CreateDataStore_RevertIf_InvalidMarketConfig() public {
        // Change caller to Lending CLOB
        vm.startPrank(address(centuariCLOB));
    
        // Use invalid market config with invalid loanToken
        MarketConfig memory configInvalidLoan = MarketConfig({
            loanToken: address(0),
            collateralToken: address(weth),
            maturity: block.timestamp + 100 days
        });
    
        // Expect revert for invalid loanToken
        vm.expectRevert(abi.encodeWithSelector(CentuariErrorsLib.InvalidMarketConfig.selector));
        ICentuari(centuari).createDataStore(configInvalidLoan);
    
        // Use invalid market config with invalid collateralToken
        MarketConfig memory configInvalidCollateral = MarketConfig({
            loanToken: address(usdc),
            collateralToken: address(0),
            maturity: block.timestamp + 100 days
        });
    
        // Expect revert for invalid collateralToken
        vm.expectRevert(abi.encodeWithSelector(CentuariErrorsLib.InvalidMarketConfig.selector));
        ICentuari(centuari).createDataStore(configInvalidCollateral);

        // Use invalid market config with past maturity
        vm.warp(MOCK_TIMESTAMP);
        MarketConfig memory configInvalidMaturity = MarketConfig({
            loanToken: address(usdc),
            collateralToken: address(weth),
            maturity: MOCK_TIMESTAMP - 1 days
        });
    
        // Expect revert for invalid maturity
        vm.expectRevert(abi.encodeWithSelector(CentuariErrorsLib.InvalidMarketConfig.selector));
        ICentuari(centuari).createDataStore(configInvalidMaturity);
    }

    function test_SetDataStore_RevertIf_InvalidMarketConfig() public {
        // Change caller to Lending CLOB
        vm.prank(address(centuariCLOB));

        //Create a DataStore
        MarketConfig memory config = MarketConfig({
            loanToken: address(usdc),
            collateralToken: address(weth),
            maturity: block.timestamp + 100 days
        });

        ICentuari(centuari).createDataStore(config);
        address dataStore = Centuari(centuari).dataStores(config.id());

        //Change caller to ownern to setDataStore
        vm.startPrank(owner);

        // Use invalid market config with invalid loanToken
        MarketConfig memory configInvalidLoan = MarketConfig({
            loanToken: address(0),
            collateralToken: address(weth),
            maturity: block.timestamp + 100 days
        });
    
        // Expect revert for invalid loanToken
        vm.expectRevert(abi.encodeWithSelector(CentuariErrorsLib.InvalidMarketConfig.selector));
        ICentuari(centuari).setDataStore(configInvalidLoan, dataStore);
    
        // Use invalid market config with invalid collateralToken
        MarketConfig memory configInvalidCollateral = MarketConfig({
            loanToken: address(usdc),
            collateralToken: address(0),
            maturity: block.timestamp + 100 days
        });
    
        // Expect revert for invalid collateralToken
        vm.expectRevert(abi.encodeWithSelector(CentuariErrorsLib.InvalidMarketConfig.selector));
        ICentuari(centuari).setDataStore(configInvalidCollateral, dataStore);

        // Use invalid market config with past maturity
        uint256 mockTimestamp = 1000000;
        vm.warp(1000000);
        MarketConfig memory configInvalidMaturity = MarketConfig({
            loanToken: address(usdc),
            collateralToken: address(weth),
            maturity: mockTimestamp - 1 days
        });
    
        // Expect revert for invalid maturity
        vm.expectRevert(abi.encodeWithSelector(CentuariErrorsLib.InvalidMarketConfig.selector));
        ICentuari(centuari).setDataStore(configInvalidMaturity, dataStore);

        vm.stopPrank();
    }

    function test_CreateDataStore_RevertIf_OnlyCentuariCLOB() public{
        //Create a DataStore
        MarketConfig memory config = MarketConfig({
            loanToken: address(usdc),
            collateralToken: address(weth),
            maturity: block.timestamp + 100 days
        });

        vm.expectRevert(abi.encodeWithSelector(CentuariErrorsLib.OnlyCentuariCLOB.selector));
        ICentuari(centuari).createDataStore(config);
    }

    function test_SetDataStore_RevertIf_OnlyOwner() public{
        //Change caller to Lending CLOB
        vm.startPrank(address(centuariCLOB));

        //Create a DataStore
        MarketConfig memory config = MarketConfig({
            loanToken: address(usdc),
            collateralToken: address(weth),
            maturity: block.timestamp + 100 days
        });
        ICentuari(centuari).createDataStore(config);

        //Create new DataStore
        ICentuari(centuari).createDataStore(config);
        address newDataStore = Centuari(centuari).dataStores(config.id());

        //Change caller to random address and call setDataStore
        vm.stopPrank();
        vm.prank(address1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address1));
        ICentuari(centuari).setDataStore(config, newDataStore);
    }
}