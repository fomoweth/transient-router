// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title CallbackValidation
/// @notice Provides validation for callbacks executed to this contract

library CallbackValidation {
	// bytes32(uint256(keccak256("CallbackValidation.storage.slot")) - 1) & ~bytes32(uint256(0xff))
	bytes32 internal constant SLOT = 0x4302a1faddcb1771bd1bd736333d9902051a213afd1b3163986f4a241b525c00;

	function setCallback(address expectedCaller, bytes4 expectedSig) internal {
		assembly ("memory-safe") {
			// verify the slot is empty
			if iszero(iszero(tload(SLOT))) {
				mstore(0x00, 0x55b9fb08) // SlotNotEmpty()
				revert(0x1c, 0x04)
			}

			// verify the expected caller is not zero
			if iszero(expectedCaller) {
				mstore(0x00, 0x48f5c3ed) // InvalidCaller()
				revert(0x1c, 0x04)
			}

			// verify the expected signature is not zero
			if iszero(expectedSig) {
				mstore(0x00, 0x8baa579f) // InvalidSignature()
				revert(0x1c, 0x04)
			}

			// store the expected caller and signature in the slot
			tstore(SLOT, add(expectedSig, expectedCaller))
		}
	}

	function verifyCallback() internal {
		assembly ("memory-safe") {
			function format(data, offset, direction) -> ret {
				switch direction
				case 0x00 {
					ret := shl(offset, shr(offset, data))
				}
				default {
					ret := shr(offset, shl(offset, data))
				}
			}

			let state := tload(SLOT)

			// verify the slot is not empty
			if iszero(state) {
				mstore(0x00, 0xce174065) // SlotEmpty()
				revert(0x1c, 0x04)
			}

			// verify the caller is equal to the expected caller
			if xor(caller(), format(state, 0x60, 0x01)) {
				mstore(0x00, 0x48f5c3ed) // InvalidCaller()
				revert(0x1c, 0x04)
			}

			// verify the signature is equal to the expected signature
			if xor(format(calldataload(0x00), 0xe0, 0x00), format(state, 0xe0, 0x00)) {
				mstore(0x00, 0x8baa579f) // InvalidSignature()
				revert(0x1c, 0x04)
			}

			// clear the slot
			tstore(SLOT, 0x00)
		}
	}
}
