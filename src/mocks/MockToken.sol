// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockToken is Ownable, ERC20 {
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) Ownable(msg.sender) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    function mint(address account_, uint256 amount_) external onlyOwner {
        _mint(account_, amount_);
    }

    function burn(uint256 amount_) external onlyOwner {
        _burn(msg.sender, amount_);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}