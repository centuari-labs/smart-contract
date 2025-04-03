// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract MockOracle is Ownable {
    address public baseFeed;
    address public quoteFeed;
    uint256 public price;

    error InvalidPrice();

    constructor(address baseFeed_, address quoteFeed_) Ownable(msg.sender) {
        baseFeed = baseFeed_;
        quoteFeed = quoteFeed_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        if (price_ == 0) revert InvalidPrice();
        price = price_;
    }
}