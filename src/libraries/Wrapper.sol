// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";

/// @title Wrapper
/// @notice Provides functions for wrapping and unwrapping native currency

library Wrapper {
	function wrap(Currency wrappedNative, uint256 value) internal {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xd0e30db000000000000000000000000000000000000000000000000000000000) // deposit()

			if iszero(call(gas(), wrappedNative, value, ptr, 0x04, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}
		}
	}

	function unwrap(Currency wrappedNative, uint256 value) internal {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x2e1a7d4d00000000000000000000000000000000000000000000000000000000) // withdraw(uint256)
			mstore(add(ptr, 0x04), value)

			if iszero(call(gas(), wrappedNative, 0x00, ptr, 0x24, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}
		}
	}
}
