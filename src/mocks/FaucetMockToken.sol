// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MockToken} from "./MockToken.sol";

enum TokenType {
    USDC,
    WETH,
    WBTC,
    WSOL,
    WLINK,
    WAAVE
}

contract FaucetMockToken {
    mapping(address => uint256) public lastRequestTime;
    uint256 private constant COOLDOWN = 30 minutes;

    error RequestTooEarly(uint256 timeRemaining);

    MockToken[6] private tokens;

    uint256[6] private amounts = [
        uint256(100), // USDC
        uint256(100), // WETH
        uint256(100), // WBTC
        uint256(100), // SOL
        uint256(100), // LINK
        uint256(100) // AAVE
    ];

    event TokensRequested(address indexed recipient);

    constructor(MockToken[6] memory _tokens) {
        tokens = _tokens;
    }

    function requestTokens(TokenType[] memory _requestToken, address _recipient) external {
        uint256 timeSinceLastRequest = block.timestamp - lastRequestTime[_recipient];
        if (timeSinceLastRequest < COOLDOWN) {
            revert RequestTooEarly(COOLDOWN - timeSinceLastRequest);
        }

        lastRequestTime[_recipient] = block.timestamp;
        for (uint256 i = 0; i < _requestToken.length; i++) {
            tokens[uint256(_requestToken[i])].mint(_recipient, amounts[uint256(_requestToken[i])] * (10 ** tokens[uint256(_requestToken[i])].decimals()));
        }

        emit TokensRequested(_recipient);
    }
}
