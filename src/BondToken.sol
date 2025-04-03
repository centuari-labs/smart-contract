// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract BondToken is Ownable, ERC20 {
    using Strings for uint256;

    error InvalidBondTokenInfo();

    struct BondTokenInfo {
        address debtToken;
        address collateralToken;
        uint256 rate;
        uint256 maturity;
        string maturityMonth;
        uint256 maturityYear;
        uint256 decimals;
    }

    BondTokenInfo public info;

    constructor(address lendingPool_, BondTokenInfo memory info_)
        Ownable(lendingPool_)
        ERC20(
            string(
                abi.encodePacked(
                    "POC ",
                    IERC20Metadata(info_.debtToken).symbol(),
                    "/",
                    IERC20Metadata(info_.collateralToken).symbol(),
                    " ",
                    (info_.rate / 1e14).toString(),
                    "RATE",
                    " ",
                    info_.maturityMonth,
                    "-",
                    info_.maturityYear.toString()
                )
            ),
            string(
                abi.encodePacked(
                    "poc",
                    IERC20Metadata(info_.debtToken).symbol(),
                    IERC20Metadata(info_.collateralToken).symbol(),
                    (info_.rate / 1e14).toString(),
                    "R",
                    info_.maturityMonth,
                    info_.maturityYear.toString()
                )
            )
        )
    {
        if (
            info_.debtToken == address(0) || info_.collateralToken == address(0) || info_.rate == 0
                || info_.maturity <= block.timestamp || bytes(info_.maturityMonth).length == 0 || info_.maturityYear == 0
        ) {
            revert InvalidBondTokenInfo();
        }
        info = info_;
    }

    function decimals() public view override returns (uint8) {
        return uint8(info.decimals);
    }

    function mint(address to_, uint256 amount_) external onlyOwner {
        _mint(to_, amount_);
    }

    function burn(address from_, uint256 amount_) external onlyOwner {
        _burn(from_, amount_);
    }
}
