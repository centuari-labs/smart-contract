// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract CentuariPrimeToken is Ownable, ERC20 {
    using Strings for uint256;

    error InvalidCentuariPrimeTokenConfig();

    constructor(address centuariPrime_, string memory name_)
        Ownable(centuariPrime_)
        ERC20(
            string(
                abi.encodePacked(
                    "CPT ",
                    name_
                )
            ),
            string(
                abi.encodePacked(
                    "CPT",
                    name_
                )
            )
        )
    {}

    function mint(address to_, uint256 amount_) external onlyOwner {
        _mint(to_, amount_);
    }

    function burn(address from_, uint256 amount_) external onlyOwner {
        _burn(from_, amount_);
    }
}
