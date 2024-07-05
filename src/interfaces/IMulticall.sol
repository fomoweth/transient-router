// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract

interface IMulticall {
	function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}
