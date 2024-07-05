// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";
import {BytesLib} from "./BytesLib.sol";

/// @title Path

library Path {
	using BytesLib for bytes;

	uint256 internal constant ADDR_SIZE = 20;
	uint256 internal constant FEE_SIZE = 3;
	uint256 internal constant NEXT_OFFSET = 23; // ADDR_SIZE + FEE_SIZE
	uint256 internal constant POP_OFFSET = 43; // NEXT_OFFSET + ADDR_SIZE
	uint256 internal constant MULTIPLE_POOLS_MIN_LENGTH = 66; // POP_OFFSET + NEXT_OFFSET

	function hasMultiplePools(bytes memory path) internal pure returns (bool) {
		return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
	}

	function numPools(bytes memory path) internal pure returns (uint256) {
		return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
	}

	function decodeFirstPool(
		bytes memory path
	) internal pure returns (Currency currencyA, Currency currencyB, uint24 fee) {
		currencyA = Currency.wrap(path.toAddress(0));
		currencyB = Currency.wrap(path.toAddress(NEXT_OFFSET));
		fee = path.toUint24(ADDR_SIZE);
	}

	function decodeFirstCurrency(bytes memory path) internal pure returns (Currency) {
		return Currency.wrap(path.toAddress(0));
	}

	function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
		return path.slice(0, POP_OFFSET);
	}

	function skipCurrency(bytes memory path) internal pure returns (bytes memory) {
		return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
	}
}
