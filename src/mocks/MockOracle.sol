// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IMockOracle} from "../interfaces/IMockOracle.sol";

contract MockOracle is Ownable, IMockOracle {
    address public baseFeed;
    address public quoteFeed;
    uint256 public price;

    constructor(address baseFeed_, address quoteFeed_) Ownable(msg.sender) {
        baseFeed = baseFeed_;
        quoteFeed = quoteFeed_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        if (price_ == 0) revert InvalidPrice();
        price = price_;
    }
}