// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {SafeCast} from "src/libraries/SafeCast.sol";

type BalanceDelta is int256;

using {add as +, sub as -, eq as ==, neq as !=} for BalanceDelta global;
using BalanceDeltaLibrary for BalanceDelta global;
using SafeCast for int256;

function toBalanceDelta(int128 amount0, int128 amount1) pure returns (BalanceDelta z) {
	assembly ("memory-safe") {
		z := or(shl(128, amount0), and(sub(shl(128, 1), 1), amount1))
	}
}

function add(BalanceDelta x, BalanceDelta y) pure returns (BalanceDelta) {
	int256 z0;
	int256 z1;

	assembly ("memory-safe") {
		z0 := add(sar(128, x), sar(128, y))
		z1 := add(signextend(15, x), signextend(15, y))
	}

	return toBalanceDelta(z0.toInt128(), z1.toInt128());
}

function sub(BalanceDelta x, BalanceDelta y) pure returns (BalanceDelta) {
	int256 z0;
	int256 z1;

	assembly ("memory-safe") {
		z0 := sub(sar(128, x), sar(128, y))
		z1 := sub(signextend(15, x), signextend(15, y))
	}

	return toBalanceDelta(z0.toInt128(), z1.toInt128());
}

function eq(BalanceDelta x, BalanceDelta y) pure returns (bool z) {
	assembly ("memory-safe") {
		z := eq(x, y)
	}
}

function neq(BalanceDelta x, BalanceDelta y) pure returns (bool z) {
	assembly ("memory-safe") {
		z := iszero(eq(x, y))
	}
}

/// @title BalanceDeltaLibrary
/// @dev Implementation from https://github.com/Uniswap/v4-core/blob/main/src/types/BalanceDelta.sol

library BalanceDeltaLibrary {
	function amount0(BalanceDelta x) internal pure returns (int128 z) {
		assembly ("memory-safe") {
			z := sar(128, x)
		}
	}

	function amount1(BalanceDelta x) internal pure returns (int128 z) {
		assembly ("memory-safe") {
			z := signextend(15, x)
		}
	}

	function isZero(BalanceDelta x) internal pure returns (bool z) {
		assembly ("memory-safe") {
			z := iszero(x)
		}
	}
}
