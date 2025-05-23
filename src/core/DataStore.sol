// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IDataStore} from "../interfaces/IDataStore.sol";

contract DataStore is IDataStore, AccessControl {
    // Define roles
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    address controller;

    constructor(address owner_, address controller_) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
        _grantRole(CONTROLLER_ROLE, controller_);
        controller = controller_;
    }

    //store for bytes values
    mapping(bytes32 => bytes) public bytesValues;
    // store for uint values
    mapping(bytes32 => uint256) public uintValues;
    // store for address values
    mapping(bytes32 => address) public addressValues;
    // store for bool values
    mapping(bytes32 => bool) public boolValues;
    // store for string values
    mapping(bytes32 => string) public stringValues;

    function setController(address controller_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CONTROLLER_ROLE, controller_);
        _revokeRole(CONTROLLER_ROLE, controller);
    }

    // @dev get the bytes value for the given key
    // @param key the key of the value
    // @return the bytes value for the key
    function getBytes(bytes32 key) external view returns (bytes memory) {
        return bytesValues[key];
    }

    // @dev set the bytes value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the bytes value for the key
    function setBytes(bytes32 key, bytes memory value) external onlyRole(CONTROLLER_ROLE) {
        bytesValues[key] = value;
    }

    // @dev get the uint value for the given key
    // @param key the key of the value
    // @return the uint value for the key
    function getUint(bytes32 key) external view returns (uint256) {
        return uintValues[key];
    }

    // @dev set the uint value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the uint value for the key
    function setUint(bytes32 key, uint256 value) external onlyRole(CONTROLLER_ROLE) {
        uintValues[key] = value;
    }

    // @dev get the address value for the given key
    // @param key the key of the value
    // @return the address value for the key
    function getAddress(bytes32 key) external view returns (address) {
        return addressValues[key];
    }

    // @dev set the address value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the address value for the key
    function setAddress(bytes32 key, address value) external onlyRole(CONTROLLER_ROLE) {
        addressValues[key] = value;
    }

    // @dev get the bool value for the given key
    // @param key the key of the value
    // @return the bool value for the key
    function getBool(bytes32 key) external view returns (bool) {
        return boolValues[key];
    }

    // @dev set the bool value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the bool value for the key
    function setBool(bytes32 key, bool value) external onlyRole(CONTROLLER_ROLE) {
        boolValues[key] = value;
    }

    // @dev get the string value for the given key
    // @param key the key of the value
    // @return the string value for the key
    function getString(bytes32 key) external view returns (string memory) {
        return stringValues[key];
    }

    // @dev set the string value for the given key
    // @param key the key of the value
    // @param value the value to set
    // @return the string value for the key
    function setString(bytes32 key, string memory value) external onlyRole(CONTROLLER_ROLE) {
        stringValues[key] = value;
    }
}
