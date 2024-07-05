// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {UNISWAP_V3_FACTORY, UNISWAP_V3_POOL_INIT_CODE_HASH} from "src/libraries/Constants.sol";
import {Currency} from "./Currency.sol";

type PoolId is bytes32;

using PoolKeyLibrary for PoolKey global;

struct PoolKey {
	Currency currency0;
	Currency currency1;
	uint24 fee;
}

function toPoolKey(Currency currency0, Currency currency1, uint24 fee) pure returns (PoolKey memory key) {
	assembly ("memory-safe") {
		if or(iszero(currency0), iszero(currency1)) {
			mstore(0x00, 0xf5993428) // InvalidCurrency()
			revert(0x1c, 0x04)
		}

		if eq(currency0, currency1) {
			mstore(0x00, 0xd07bec9c) // IdenticalCurrencies()
			revert(0x1c, 0x04)
		}

		if iszero(or(or(eq(fee, 100), eq(fee, 500)), or(eq(fee, 3000), eq(fee, 10000)))) {
			mstore(0x00, 0x1213a0ab) // InvalidPoolFee()
			revert(0x1c, 0x04)
		}

		if gt(currency0, currency1) {
			let temp := currency0
			currency0 := currency1
			currency1 := temp
		}

		mstore(key, currency0)
		mstore(add(key, 0x20), currency1)
		mstore(add(key, 0x40), fee)
	}
}

/// @title PoolKeyLibrary
/// @notice Library for PoolKey struct

library PoolKeyLibrary {
	function computeAddress(PoolKey memory key) internal view returns (address pool) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, add(hex"ff", shl(0x58, UNISWAP_V3_FACTORY)))
			mstore(add(ptr, 0x15), keccak256(key, 0x60))
			mstore(add(ptr, 0x35), UNISWAP_V3_POOL_INIT_CODE_HASH)

			pool := and(keccak256(ptr, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)

			// reverts if the pool at computed address hasn't deployed yet
			if iszero(extcodesize(pool)) {
				mstore(0x00, 0x0ba98f1c) // PoolNotExists()
				revert(0x1c, 0x04)
			}
		}
	}

	function toId(PoolKey memory key) internal pure returns (PoolId id) {
		assembly ("memory-safe") {
			id := keccak256(key, 0x60)
		}
	}

	function tickSpacing(PoolKey memory key) internal pure returns (int24 ts) {
		assembly ("memory-safe") {
			let fee := mload(add(key, 0x40))
			ts := sub(div(fee, 50), eq(fee, 100))
		}
	}
}
