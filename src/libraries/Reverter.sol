// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title Reverter
/// @notice Provides functions for reverting with a custom exception and value

library Reverter {
	function revertWith(bytes4 exception, address value) internal pure {
		assembly ("memory-safe") {
			mstore(0x00, exception)
			mstore(0x04, value)
			revert(0x1c, 0x24)
		}
	}

	function revertWith(bytes4 exception, bytes32 value) internal pure {
		assembly ("memory-safe") {
			mstore(0x00, exception)
			mstore(0x04, value)
			revert(0x1c, 0x24)
		}
	}

	function revertWith(bytes4 exception, uint256 value) internal pure {
		assembly ("memory-safe") {
			mstore(0x00, exception)
			mstore(0x04, value)
			revert(0x1c, 0x24)
		}
	}

	function revertWith(bytes4 exception) internal pure {
		assembly ("memory-safe") {
			mstore(0x00, exception)
			revert(0x1c, 0x04)
		}
	}
}
