// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";
import {UNISWAP_V3_FACTORY, UNISWAP_V3_POOL_INIT_CODE_HASH} from "./Constants.sol";

/// @title PoolAddress
/// @dev Modified from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/PoolAddress.sol

library PoolAddress {
	function compute(
		address factory,
		bytes32 initCodeHash,
		Currency currency0,
		Currency currency1,
		uint24 fee
	) internal view returns (address pool) {
		assembly ("memory-safe") {
			// swap currency0 and currency1 if currency order is invalid
			if gt(currency0, currency1) {
				let temp := currency0
				currency0 := currency1
				currency1 := temp
			}

			let ptr := mload(0x40)

			// store currency0, currency1, and fee on memory to compute the salt of the pool
			mstore(add(ptr, 0x15), currency0)
			mstore(add(ptr, 0x35), currency1)
			mstore(add(ptr, 0x55), fee)

			// store factory address, salt, and init code hash on memory
			mstore(ptr, add(hex"ff", shl(0x58, factory)))
			mstore(add(ptr, 0x15), keccak256(add(ptr, 0x15), 0x60))
			mstore(add(ptr, 0x35), initCodeHash)

			// compute the address of the pool
			pool := and(keccak256(ptr, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)

			// reverts if the pool at computed address hasn't deployed yet
			if iszero(extcodesize(pool)) {
				mstore(0x00, 0x3f36c1ab) // PoolNotExists(address)
				mstore(0x20, pool)
				revert(0x1c, 0x24)
			}
		}
	}

	function compute(
		address factory,
		Currency currency0,
		Currency currency1,
		uint24 fee
	) internal view returns (address pool) {
		assembly ("memory-safe") {
			// swap currency0 and currency1 if currency order is invalid
			if gt(currency0, currency1) {
				let temp := currency0
				currency0 := currency1
				currency1 := temp
			}

			let ptr := mload(0x40)

			// store currency0, currency1, and fee on memory to compute the salt of the pool
			mstore(add(ptr, 0x15), currency0)
			mstore(add(ptr, 0x35), currency1)
			mstore(add(ptr, 0x55), fee)

			// store factory address, salt, and init code hash on memory
			mstore(ptr, add(hex"ff", shl(0x58, factory)))
			mstore(add(ptr, 0x15), keccak256(add(ptr, 0x15), 0x60))
			mstore(add(ptr, 0x35), UNISWAP_V3_POOL_INIT_CODE_HASH)

			// compute the address of the pool
			pool := and(keccak256(ptr, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)

			// reverts if the pool at computed address hasn't deployed yet
			if iszero(extcodesize(pool)) {
				mstore(0x00, 0x3f36c1ab) // PoolNotExists(address)
				mstore(0x20, pool)
				revert(0x1c, 0x24)
			}
		}
	}

	function compute(
		Currency currency0,
		Currency currency1,
		uint24 fee
	) internal view returns (address pool) {
		assembly ("memory-safe") {
			// swap currency0 and currency1 if currency order is invalid
			if gt(currency0, currency1) {
				let temp := currency0
				currency0 := currency1
				currency1 := temp
			}

			let ptr := mload(0x40)

			// store currency0, currency1, and fee on memory to compute the salt of the pool
			mstore(add(ptr, 0x15), currency0)
			mstore(add(ptr, 0x35), currency1)
			mstore(add(ptr, 0x55), fee)

			// store factory address, salt, and init code hash on memory
			mstore(ptr, add(hex"ff", shl(0x58, UNISWAP_V3_FACTORY)))
			mstore(add(ptr, 0x15), keccak256(add(ptr, 0x15), 0x60))
			mstore(add(ptr, 0x35), UNISWAP_V3_POOL_INIT_CODE_HASH)

			// compute the address of the pool
			pool := and(keccak256(ptr, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)

			// reverts if the pool at computed address hasn't deployed yet
			if iszero(extcodesize(pool)) {
				mstore(0x00, 0x3f36c1ab) // PoolNotExists(address)
				mstore(0x20, pool)
				revert(0x1c, 0x24)
			}
		}
	}
}
