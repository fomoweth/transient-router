// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title BytesLib
/// @dev Implementation from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/BytesLib.sol

library BytesLib {
	function slice(
		bytes memory data,
		uint256 offset,
		uint256 length
	) internal pure returns (bytes memory res) {
		assembly ("memory-safe") {
			if or(lt(add(length, 0x1f), length), lt(add(offset, length), offset)) {
				mstore(0x00, 0x47aaf07a) // SliceOverflow()
				revert(0x1c, 0x04)
			}

			if lt(mload(data), add(offset, length)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := mload(0x40)

			switch iszero(length)
			case 0x00 {
				let lengthmod := and(length, 0x1f)
				let mc := add(add(res, lengthmod), mul(0x20, iszero(lengthmod)))
				let end := add(mc, length)

				for {
					let cc := add(add(add(data, lengthmod), mul(0x20, iszero(lengthmod))), offset)
				} lt(mc, end) {
					mc := add(mc, 0x20)
					cc := add(cc, 0x20)
				} {
					mstore(mc, mload(cc))
				}

				mstore(res, length)
				mstore(0x40, and(add(mc, 0x1f), not(0x1f)))
			}
			default {
				mstore(res, 0x00)
				mstore(0x40, add(res, 0x20))
			}
		}
	}

	function toAddress(bytes memory data, uint256 offset) internal pure returns (address res) {
		assembly ("memory-safe") {
			if lt(add(offset, 0x14), offset) {
				mstore(0x00, 0x47aaf07a) // SliceOverflow()
				revert(0x1c, 0x04)
			}

			if lt(mload(data), add(offset, 0x14)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := shr(0x60, mload(add(add(data, 0x20), offset)))
		}
	}

	function toUint24(bytes memory data, uint256 offset) internal pure returns (uint24 res) {
		assembly ("memory-safe") {
			if lt(add(offset, 0x03), offset) {
				mstore(0x00, 0x47aaf07a) // SliceOverflow()
				revert(0x1c, 0x04)
			}

			if lt(mload(data), add(offset, 0x03)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := mload(add(add(data, 0x03), offset))
		}
	}
}
