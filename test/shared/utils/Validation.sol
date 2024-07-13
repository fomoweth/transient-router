// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";

library Validation {
	function verifyContract(address target) internal view returns (address) {
		assembly ("memory-safe") {
			if iszero(extcodesize(target)) {
				mstore(0x00, 0xb5cf5b8f) // NotContract(address)
				mstore(0x04, target)
				revert(0x1c, 0x24)
			}
		}

		return target;
	}

	function verifyPoolFee(uint24 fee) internal pure returns (uint24) {
		assembly ("memory-safe") {
			if iszero(or(or(eq(fee, 100), eq(fee, 500)), or(eq(fee, 3000), eq(fee, 10000)))) {
				mstore(0x00, 0x1213a0ab) // InvalidPoolFee()
				revert(0x1c, 0x04)
			}
		}

		return fee;
	}

	function verifyNotZero(address target) internal pure returns (address) {
		assembly ("memory-safe") {
			if iszero(target) {
				mstore(0x00, 0xd92e233d) // ZeroAddress()
				revert(0x1c, 0x04)
			}
		}

		return target;
	}

	function verifyNotZero(Currency target) internal pure returns (Currency) {
		assembly ("memory-safe") {
			if iszero(target) {
				mstore(0x00, 0xf5993428) // InvalidCurrency()
				revert(0x1c, 0x04)
			}
		}

		return target;
	}

	function verifyNotZero(bytes32 target) internal pure returns (bytes32) {
		assembly ("memory-safe") {
			if iszero(target) {
				mstore(0x00, 0xdff66326) // ZeroBytes32()
				revert(0x1c, 0x04)
			}
		}

		return target;
	}

	function verifyNotZero(uint256 target) internal pure returns (uint256) {
		assembly ("memory-safe") {
			if iszero(target) {
				mstore(0x00, 0x7c946ed7) // ZeroValue()
				revert(0x1c, 0x04)
			}
		}

		return target;
	}
}
