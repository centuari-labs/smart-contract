// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { ICentuari } from "../interfaces/ICentuari.sol";
import { ErrorsLib } from "../libraries/ErrorsLib.sol";
import { SafeTransferLib } from "../libraries/SafeTransferLibs.sol";
import { IERC20 } from "../interfaces/IERC20.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Centuari is ICentuari, Ownable {
    using SafeTransferLib for IERC20;

    address public router;
    
    modifier onlyRouter() {
        require(msg.sender == router, ErrorsLib.ONLY_ROUTER);
        _;
    }

    constructor(address owner_) Ownable(owner_) {}

    function setRouter(address router_) external onlyOwner {
        require(router_ != address(0), "Invalid router address");
        router = router_;
    }

    function deposit(address token, uint256 amount) external onlyRouter {
        //TODO: Add Logic
    }

    function withdraw(address token, uint256 amount) external onlyRouter {
        //TODO: Add Logic
    }

    function flashLoan(address token, uint256 assets, bytes calldata data) external {
        //TODO: Add Logic
    }
}
