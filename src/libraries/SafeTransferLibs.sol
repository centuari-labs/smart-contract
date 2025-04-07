// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "../interfaces/IERC20.sol";
import {ErrorsLib} from "./ErrorsLib.sol";

interface IERC20Internal {
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to,uint256 value) external;
}

library SafeTransferLib{
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(address(token).code.length > 0, ErrorsLib.NO_CODE);

        (bool success, bytes memory returndata) =
            address(token).call(abi.encodeCall(IERC20Internal.transfer, (to, value)));
        require(success, ErrorsLib.TRANSFER_REVERTED);
        require(returndata.length == 0 || abi.decode(returndata, (bool)), ErrorsLib.TRANSFER_RETURNED_FALSE);
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(address(token).code.length > 0, ErrorsLib.NO_CODE);

        (bool success, bytes memory returndata) =
            address(token).call(abi.encodeCall(IERC20Internal.transferFrom, (from, to, value)));
        require(success, ErrorsLib.TRANSFER_FROM_REVERTED);
        require(returndata.length == 0 || abi.decode(returndata, (bool)), ErrorsLib.TRANSFER_FROM_RETURNED_FALSE);
    }
}