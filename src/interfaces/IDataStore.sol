// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
interface IDataStore {
    function getBytes(bytes32 key) external view returns (bytes memory);
    function setBytes(bytes32 key, bytes memory value) external;
    function getUint(bytes32 key) external view returns (uint256);
    function setUint(bytes32 key, uint256 value) external;
    function getAddress(bytes32 key) external view returns (address);
    function setAddress(bytes32 key, address value) external;
    function getBool(bytes32 key) external view returns (bool);
    function setBool(bytes32 key, bool value) external;
    function getString(bytes32 key) external view returns (string memory);
    function setString(bytes32 key, string memory value) external;
}
