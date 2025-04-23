// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseTest} from "../../BaseTest.sol";
import {MarketConfig, Id} from "../../../src/types/CommonTypes.sol";
import {MarketConfigLib} from "../../../src/libraries/MarketConfigLib.sol";
import {Centuari} from "../../../src/core/Centuari.sol";
import {ICentuari} from "../../../src/interfaces/ICentuari.sol";
import {DataStore} from "../../../src/core/DataStore.sol";
import {CentuariDSLib} from "../../../src/libraries/Centuari/CentuariDSLib.sol";
import {CentuariErrorsLib} from "../../../src/libraries/Centuari/CentuariErrorsLib.sol";
import {CentuariEventsLib} from "../../../src/libraries/Centuari/CentuariEventsLib.sol";
import {BondToken} from "../../../src/core/BondToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {console} from "forge-std/Test.sol";

contract AddRateIntegrationTest is BaseTest {
    using MarketConfigLib for MarketConfig;

    function test_AddRate() public {
        vm.startPrank(address(centuariCLOB));

        //Create data store
        ICentuari(centuari).createDataStore(usdcWethMarketConfig);

        //Get data store
        address dataStore = Centuari(centuari).dataStores(usdcWethMarketConfig.id());

        // Expect Rate Added event
        vm.expectEmit(true, false, false, false);
        emit CentuariEventsLib.RateAdded(usdcWethMarketConfig.id(), RATE);

        // Expect Bond Token Created event
        // We don't know the exact address yet so we use address(0), so we only check the rate
        vm.expectEmit(false, false, false, true);
        emit CentuariEventsLib.BondTokenCreated(usdcWethMarketConfig.id(), address(0), RATE);

        // Change caller to Lending CLOB and add rate
        vm.warp(MOCK_TIMESTAMP);
        ICentuari(centuari).addRate(usdcWethMarketConfig, RATE);

        //Get the last accrue timestamp
        uint256 lastAccrueTimestamp = DataStore(dataStore).getUint(CentuariDSLib.getLastAccrueKey(RATE));
        assertEq(lastAccrueTimestamp, MOCK_TIMESTAMP);

        // Get the bond token address
        address bondTokenAddress = DataStore(dataStore).getAddress(CentuariDSLib.getBondTokenAddressKey(RATE));
        assertTrue(bondTokenAddress != address(0), "Bond token not created");

        // Check bond token configuration
        BondToken addRateBondToken = BondToken(bondTokenAddress);
        (
            address loanToken,
            address collateralToken,
            uint256 rate,
            uint256 maturity,
            string memory maturityMonth,
            uint256 maturityYear,
            uint256 decimals
        ) = addRateBondToken.config();
        assertEq(loanToken, address(usdc), "Incorrect loan token");
        assertEq(collateralToken, address(weth), "Incorrect collateral token");
        assertEq(rate, RATE, "Incorrect rate");
        assertEq(maturity, MATURITY, "Incorrect maturity");
        assertEq(decimals, usdc.decimals(), "Incorrect decimals");
    }
}
