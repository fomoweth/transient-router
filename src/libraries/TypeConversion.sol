// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title TypeConversion

library TypeConversion {
	function asBytes32(bool input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBool(bytes32 input) internal pure returns (bool output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(address input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asAddress(bytes32 input) internal pure returns (address output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint256 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint256(bytes32 input) internal pure returns (uint256 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int256 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt256(bytes32 input) internal pure returns (int256 output) {
		assembly ("memory-safe") {
			output := input
		}
	}
}
