//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Id, Side, Status} from "../../types/CommonTypes.sol";

library CentuariCLOBEventsLib {
    event OrderPlaced(
        Id indexed id,
        uint256 orderId,
        address indexed trader,
        uint256 amount,
        uint256 collateralAmount,
        uint256 rate,
        Side side,
        Status status
    );
    event OrderMatched(Id indexed id, uint256 newOrderId, uint256 oppositeOrderId, uint256 matchedAmount);
    event OrderCancelled(Id indexed id, uint256 orderId);
    event MarketLendingRateUpdated(Id indexed id, uint256 rate);
    event MarketBorrowingRateUpdated(Id indexed id, uint256 rate);
}
