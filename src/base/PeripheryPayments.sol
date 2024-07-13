// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IPeripheryPayments} from "src/interfaces/IPeripheryPayments.sol";
import {Math} from "src/libraries/Math.sol";
import {Currency} from "src/types/Currency.sol";
import {PeripheryImmutableState} from "./PeripheryImmutableState.sol";
import {PeripheryValidation} from "./PeripheryValidation.sol";

/// @title PeripheryPayments
/// @dev Modified from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/PeripheryPayments.sol

abstract contract PeripheryPayments is IPeripheryPayments, PeripheryImmutableState, PeripheryValidation {
	using Math for uint256;

	receive() external payable virtual {
		required(msg.sender == Currency.unwrap(WETH9), 0x48f5c3ed); // InvalidCaller()
	}

	function pull(Currency currency, uint256 value) external payable {
		required(value != 0, 0x7c946ed7); // ZeroValue()
		currency.transferFrom(msg.sender, address(this), value);
	}

	function wrapETH(uint256 value) external payable {
		wrapNative(WETH9, value.min(selfBalance()));
	}

	function unwrapWETH(uint256 value) external payable {
		unwrapNative(WETH9, value.min(WETH9.balanceOfSelf()));
	}

	function refund(Currency currency) external payable {
		uint256 balance = currency.balanceOfSelf();
		if (balance != 0) currency.transfer(msg.sender, balance);
	}

	function refundETH(bool unwrap) external payable {
		if (unwrap) unwrapNative(WETH9, WETH9.balanceOfSelf());

		assembly ("memory-safe") {
			if iszero(iszero(selfbalance())) {
				if iszero(call(gas(), caller(), selfbalance(), 0x00, 0x00, 0x00, 0x00)) {
					mstore(0x00, 0xb06a467a) // TransferNativeFailed()
					revert(0x1c, 0x04)
				}
			}
		}
	}

	function pay(Currency currency, address payer, address recipient, uint256 value) internal {
		if (payer == address(this)) {
			currency.transfer(recipient, value);
		} else {
			currency.transferFrom(payer, recipient, value);
		}
	}

	function wrapNative(Currency weth, uint256 value) private {
		assembly ("memory-safe") {
			if iszero(iszero(value)) {
				let ptr := mload(0x40)

				mstore(ptr, 0xd0e30db000000000000000000000000000000000000000000000000000000000)

				if iszero(call(gas(), weth, value, ptr, 0x04, 0x00, 0x00)) {
					returndatacopy(ptr, 0x00, returndatasize())
					revert(ptr, returndatasize())
				}
			}
		}
	}

	function unwrapNative(Currency weth, uint256 value) private {
		assembly ("memory-safe") {
			if iszero(iszero(value)) {
				let ptr := mload(0x40)

				mstore(ptr, 0x2e1a7d4d00000000000000000000000000000000000000000000000000000000)
				mstore(add(ptr, 0x04), value)

				if iszero(call(gas(), weth, 0x00, ptr, 0x24, 0x00, 0x00)) {
					returndatacopy(ptr, 0x00, returndatasize())
					revert(ptr, returndatasize())
				}
			}
		}
	}

	function selfBalance() private view returns (uint256 value) {
		assembly ("memory-safe") {
			value := selfbalance()
		}
	}
}
