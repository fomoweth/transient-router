// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title TransientState
/// @notice Provides functions for caching and reading states at a slot by using transient-storage

library TransientState {
	function cache(bytes32 slot, bytes32 value) internal {
		assembly ("memory-safe") {
			tstore(slot, value)
		}
	}

	function clear(bytes32 slot) internal {
		assembly ("memory-safe") {
			if iszero(iszero(tload(slot))) {
				tstore(slot, 0x00)
			}
		}
	}

	function read(bytes32 slot) internal view returns (bytes32 value) {
		assembly ("memory-safe") {
			value := tload(slot)
		}
	}

	function isEmpty(bytes32 slot) internal view returns (bool b) {
		assembly ("memory-safe") {
			b := iszero(tload(slot))
		}
	}

	function derive(bytes32 slot, bytes32 key) internal pure returns (bytes32 derivedSlot) {
		assembly ("memory-safe") {
			mstore(0x00, key)
			mstore(0x20, slot)
			derivedSlot := keccak256(0x00, 0x40)
		}
	}
}
