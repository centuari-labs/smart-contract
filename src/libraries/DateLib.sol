// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library DateLib {
    /// @notice Converts a timestamp to month string (e.g., "JAN", "FEB", etc.)
    /// @param timestamp The timestamp to convert
    /// @return monthString The 3-letter month string
    function getMonth(uint256 timestamp) internal pure returns (string memory monthString) {
        uint256 month = (timestamp / 2629743) % 12; // Approximate month from timestamp
        
        if (month == 0) return "JAN";
        if (month == 1) return "FEB";
        if (month == 2) return "MAR";
        if (month == 3) return "APR";
        if (month == 4) return "MAY";
        if (month == 5) return "JUN";
        if (month == 6) return "JUL";
        if (month == 7) return "AUG";
        if (month == 8) return "SEP";
        if (month == 9) return "OCT";
        if (month == 10) return "NOV";
        return "DEC";
    }

    /// @notice Converts a timestamp to year
    /// @param timestamp The timestamp to convert
    /// @return year The year
    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        return 1970 + (timestamp / 31556926); // Approximate year from timestamp
    }
} 