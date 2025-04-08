// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Id } from "../types/CommonTypes.sol";
import { ICentuari } from "../interfaces/ICentuari.sol";
import { IERC20 } from "../interfaces/IERC20.sol";
import { SafeTransferLib } from "../libraries/SafeTransferLibs.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { ILendingCLOB } from "../interfaces/ILendingCLOB.sol";
import { ILendingPool } from "../interfaces/ILendingPool.sol";
import { LendingPoolConfig, LendingPoolConfigLib } from "../libraries/LendingPoolConfigLib.sol";
import { LendingCLOBConfig, LendingCLOBConfigLib } from "../libraries/LendingCLOBConfigLib.sol";
import { ILendingRouter } from "../interfaces/ILendingRouter.sol";

contract LendingRouter is ILendingRouter, Ownable {
    ICentuari public centuari;
    using LendingPoolConfigLib for LendingPoolConfig;
    using LendingCLOBConfigLib for LendingCLOBConfig;

    mapping(Id => address) public lendingPools;
    mapping(Id => address) public lendingCLOBs;

    constructor(address centuari_, address owner_) Ownable(owner_) {
        require(centuari_ != address(0), "Invalid Centuari address");
        centuari = ICentuari(centuari_);
    }

    function setCentuari(address centuari_) external onlyOwner {
        require(centuari_ != address(0), "Invalid Centuari address");
        centuari = ICentuari(centuari_);
    }
    
    function depositCLOB(address token, uint256 amount) external {
        // Add validation to check if the lending CLOB exists
        centuari.deposit(token, amount);
        //TODO: Add Logic
    }

    function depositPool(address token, uint256 amount) external {  
        // Add validation to check if the lending pool exists
        centuari.deposit(token, amount);
        //TODO: Add Logic
    }
    
    function withdrawCLOB(address token, uint256 amount) external { 
        // Add validation to check if the lending CLOB exists
        centuari.withdraw(token, amount);
        //TODO: Add Logic
    }

    function withdrawPool(address token, uint256 amount) external {
        // Add validation to check if the lending pool exists
        centuari.withdraw(token, amount);
        //TODO: Add Logic
    }

    function flashLoan(address token, uint256 assets, bytes calldata data) external {
        //TODO: Add Logic   
    }
}