// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";

interface ISelfPermit {
	function selfPermit(
		Currency currency,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external payable;

	function selfPermitIfNecessary(
		Currency currency,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external payable;

	function selfPermitAllowed(
		Currency currency,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external payable;

	function selfPermitAllowedIfNecessary(
		Currency currency,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external payable;
}
