// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @title CentuariToken
/// @notice A specialized ERC20 token representing lending positions in the Centuari protocol
/// @dev Implements position tracking with dynamic naming based on debt/collateral pair
contract CentuariToken is Ownable, ERC20 {
    using Strings for uint256;

    /// @notice Error thrown when invalid token information is provided
    /// @dev Thrown when any required field in CentuariTokenInfo is zero or empty
    /// @custom:error Thrown when:
    /// @custom:error - debtToken is zero address
    /// @custom:error - collateralToken is zero address
    /// @custom:error - maturity is in the past
    /// @custom:error - maturityMonth is empty string
    /// @custom:error - maturityYear is zero
    error InvalidCentuariTokenInfo();

    /// @notice Structure containing all relevant information for a Centuari bond token
    /// @dev Used to store and manage token-specific parameters
    /// @param debtToken Address of the token being borrowed
    /// @param collateralToken Address of the token used as collateral
    /// @param maturity Timestamp when the lending position matures
    /// @param maturityMonth String representation of maturity month (e.g., "JAN")
    /// @param maturityYear Year of maturity
    struct CentuariTokenConfig {
        address loanToken;
        address collateralToken;
        uint256 rate;
        uint256 maturity;
        string maturityMonth;
        uint256 maturityYear;
    }

    /// @notice Information about the current Centuari token instance
    /// @dev Stores all relevant parameters for this specific token
    CentuariTokenConfig public config;

    /// @notice Creates a new Centuari token instance
    /// @dev Initializes the token with a dynamic name and symbol based on the provided parameters
    /// @param centuari_ Address of the centuari that will own this token
    /// @param config_ Struct containing all token parameters
    constructor(address centuari_, CentuariTokenConfig memory config_)
        Ownable(centuari_)
        ERC20(
            string(
                abi.encodePacked(
                    "CENT ",
                    IERC20Metadata(config_.loanToken).symbol(),
                    "/",
                    IERC20Metadata(config_.collateralToken).symbol(),
                    " ",
                    (config_.rate / 1e14).toString(),
                    "RATE",
                    " ",
                    config_.maturityMonth,
                    "-",
                    config_.maturityYear.toString()
                )
            ),
            string(
                abi.encodePacked(
                    "cent",
                    IERC20Metadata(config_.loanToken).symbol(),
                    IERC20Metadata(config_.collateralToken).symbol(),
                    (config_.rate / 1e14).toString(),
                    "R",
                    config_.maturityMonth,
                    config_.maturityYear.toString()
                )
            )
        )
    {
        if (
            config_.loanToken == address(0) || config_.collateralToken == address(0) || config_.rate == 0
                || config_.maturity <= block.timestamp || bytes(config_.maturityMonth).length == 0
                || config_.maturityYear == 0
        ) {
            revert InvalidCentuariTokenInfo();
        }
        config = config_;
    }

    /// @notice Creates new tokens and assigns them to a specified account
    /// @dev Only the lending pool (owner) can mint tokens
    /// @param to_ The address that will receive the minted tokens
    /// @param amount_ The amount of tokens to mint
    function mint(address to_, uint256 amount_) external onlyOwner {
        _mint(to_, amount_);
    }

    /// @notice Destroys tokens from a specified account
    /// @dev Only the lending pool (owner) can burn tokens
    /// @param from_ The address to burn tokens from
    /// @param amount_ The amount of tokens to burn
    function burn(address from_, uint256 amount_) external onlyOwner {
        _burn(from_, amount_);
    }

    /// @notice Returns the number of decimals for the token
    /// @dev Overrides the ERC20 decimals function to return the configured decimals
    /// @return The number of decimals for the token
    function decimals() public view override returns (uint8) {
        return IERC20Metadata(config.loanToken).decimals();
    }
}
