// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {TransientState} from "src/libraries/TransientState.sol";
import {TypeConversion} from "src/libraries/TypeConversion.sol";
import {PeripheryPayments} from "src/base/PeripheryPayments.sol";

/// @title Routing

abstract contract Routing is PeripheryPayments {
	using TransientState for bytes32;
	using TypeConversion for bytes32;
	using TypeConversion for address;
	using TypeConversion for uint256;

	enum SwapType {
		EmptyAction,
		V3ExactInput,
		V3ExactOutput,
		V2ExactInput,
		V2ExactOutput
	}

	bytes32 private constant V3_EXACT_IN = "V3_EXACT_IN";
	bytes32 private constant V3_EXACT_OUT = "V3_EXACT_OUT";
	bytes32 private constant V2_EXACT_IN = "V2_EXACT_IN";
	bytes32 private constant V2_EXACT_OUT = "V2_EXACT_OUT";

	// bytes32(uint256(keccak256("Routing.swapActionCached.slot")) - 1) & ~bytes32(uint256(0xff))
	bytes32 private constant SWAP_ACTION_CACHED_SLOT =
		0x92b8f245bf2fa3dc533d89f752143cbd5bb4b2b6eb819893a9f6a90a5a113d00;

	// bytes32(uint256(keccak256("Routing.amountInCached.slot")) - 1) & ~bytes32(uint256(0xff))
	bytes32 private constant AMOUNT_IN_CACHED_SLOT = 0x095874a8bbf018eab101d2a903c1a6f6a2bbad44aec6040fdc2de2e98558f400;

	// bytes32(uint256(keccak256("Routing.payerCached.slot")) - 1) & ~bytes32(uint256(0xff))
	bytes32 private constant PAYER_CACHED_SLOT = 0x1b4d302b7f737861cbf1544ccf4caa8c76b6e98ba00bd04bd021e2793594ea00;

	bytes4 internal constant AMOUNT_IN_ZERO_ERROR = 0x40561e0d; // AmountInZero()
	bytes4 internal constant AMOUNT_IN_MAX_ZERO_ERROR = 0x0ce80233; // AmountInMaxZero()
	bytes4 internal constant AMOUNT_OUT_ZERO_ERROR = 0x40561e0d; // AmountOutZero()

	bytes4 internal constant INSUFFICIENT_AMOUNT_IN_ERROR = 0xdf5b2ee6; // InsufficientAmountIn()
	bytes4 internal constant INSUFFICIENT_AMOUNT_OUT_ERROR = 0xe52970aa; // InsufficientAmountOut()
	bytes4 internal constant INSUFFICIENT_RESERVES_ERROR = 0xbe5222a3; // InsufficientReserves(address)

	bytes4 internal constant INVALID_SWAP_ERROR = 0x11157667; // InvalidSwap()
	bytes4 internal constant INVALID_SWAP_TYPE_ERROR = 0x893f2d3b; // InvalidSwapType(uint8)
	bytes4 internal constant INVALID_PATH_LENGTH_ERROR = 0xcd608bfe; // InvalidPathLength()
	bytes4 internal constant INVALID_PAYER_ERROR = 0x11157667; // InvalidPayer()

	bytes4 internal constant SLOT_EMPTY_ERROR = 0xce174065; // SlotEmpty()
	bytes4 internal constant SLOT_NOT_EMPTY_ERROR = 0x55b9fb08; // SlotNotEmpty()

	modifier checkDeadline(uint256 deadline) {
		_checkDeadline(deadline);
		_;
	}

	function _checkDeadline(uint256 deadline) private view {
		required(blockTimestamp() <= deadline, 0x1ab7da6b); // DeadlineExpired()
	}

	function blockTimestamp() internal view returns (uint48 bts) {
		assembly ("memory-safe") {
			bts := timestamp()
		}
	}

	function cacheSwapAction(SwapType swapType) internal {
		required(SWAP_ACTION_CACHED_SLOT.isEmpty(), SLOT_NOT_EMPTY_ERROR);
		SWAP_ACTION_CACHED_SLOT.cache(mapSwapAction(swapType));
	}

	function clearSwapActionCached() internal {
		required(!SWAP_ACTION_CACHED_SLOT.isEmpty(), SLOT_EMPTY_ERROR);
		SWAP_ACTION_CACHED_SLOT.clear();
	}

	function swapActionCached() internal view returns (bytes32 swapAction) {
		return SWAP_ACTION_CACHED_SLOT.read();
	}

	function swapTypeCached() internal view returns (SwapType swapType) {
		return parseSwapType(swapActionCached());
	}

	function cachePayer(address payer) internal {
		required(payer != address(0), INVALID_PAYER_ERROR);
		PAYER_CACHED_SLOT.cache(payer.asBytes32());
	}

	function clearPayerCached() internal {
		required(!PAYER_CACHED_SLOT.isEmpty(), SLOT_EMPTY_ERROR);
		PAYER_CACHED_SLOT.clear();
	}

	function payerCached() internal view returns (address payer) {
		return PAYER_CACHED_SLOT.read().asAddress();
	}

	function cacheAmountIn(uint256 amountIn) internal {
		AMOUNT_IN_CACHED_SLOT.cache(amountIn.asBytes32());
	}

	function clearAmountInCached() internal {
		required(!AMOUNT_IN_CACHED_SLOT.isEmpty(), SLOT_EMPTY_ERROR);
		AMOUNT_IN_CACHED_SLOT.clear();
	}

	function amountInCached() internal view returns (uint256 amountIn) {
		return AMOUNT_IN_CACHED_SLOT.read().asUint256();
	}

	function mapSwapAction(SwapType swapType) internal pure returns (bytes32 swapAction) {
		assembly ("memory-safe") {
			switch swapType
			case 0x01 {
				swapAction := V3_EXACT_IN
			}
			case 0x02 {
				swapAction := V3_EXACT_OUT
			}
			case 0x03 {
				swapAction := V2_EXACT_IN
			}
			case 0x04 {
				swapAction := V2_EXACT_OUT
			}
			default {
				mstore(0x00, INVALID_SWAP_TYPE_ERROR) // InvalidSwapType(uint8)
				mstore(0x04, swapType)
				revert(0x1c, 0x24)
			}

			swapAction := add(swapAction, swapType)
		}
	}

	function parseSwapType(bytes32 swapAction) internal pure returns (SwapType swapType) {
		assembly ("memory-safe") {
			swapType := shr(248, shl(248, swapAction))
		}
	}
}
