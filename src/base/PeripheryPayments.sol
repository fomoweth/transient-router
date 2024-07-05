// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Reverter} from "src/libraries/Reverter.sol";
import {Wrapper} from "src/libraries/Wrapper.sol";
import {Currency} from "src/types/Currency.sol";
import {PeripheryImmutableState} from "./PeripheryImmutableState.sol";
import {PeripheryValidation} from "./PeripheryValidation.sol";

/// @title PeripheryPayments
/// @dev Modified from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/PeripheryPayments.sol

abstract contract PeripheryPayments is PeripheryImmutableState, PeripheryValidation {
	using Wrapper for Currency;

	receive() external payable virtual {
		required(msg.sender == Currency.unwrap(WETH9), 0x48f5c3ed); // InvalidCaller()
	}

	function unwrapWETH9(uint256 amountMin, address recipient) public payable {
		uint256 balance = WETH9.balanceOfSelf();
		required(balance >= amountMin, 0x897f6c58, Currency.unwrap(WETH9)); // InsufficientBalance(address)

		if (balance != 0) {
			WETH9.unwrap(amountMin);

			assembly ("memory-safe") {
				if iszero(call(gas(), recipient, amountMin, 0x00, 0x00, 0x00, 0x00)) {
					mstore(0x00, 0xb06a467a) // TransferNativeFailed()
					revert(0x1c, 0x04)
				}
			}
		}
	}

	function sweepCurrency(Currency currency, uint256 amountMin, address recipient) public payable {
		uint256 balance = currency.balanceOfSelf();
		required(balance >= amountMin, 0xf4d678b8); // InsufficientBalance()

		if (balance > 0) currency.transfer(recipient, balance);
	}

	function refundETH() external payable {
		assembly ("memory-safe") {
			let value := selfbalance()

			if iszero(iszero(value)) {
				if iszero(call(gas(), caller(), value, 0x00, 0x00, 0x00, 0x00)) {
					mstore(0x00, 0xb06a467a) // TransferNativeFailed()
					revert(0x1c, 0x04)
				}
			}
		}
	}

	function pay(Currency currency, address payer, address recipient, uint256 value) internal {
		if (currency == WETH9 && address(this).balance >= value) {
			WETH9.wrap(value);
			WETH9.transfer(recipient, value);
		} else if (payer == address(this)) {
			currency.transfer(recipient, value);
		} else {
			currency.transferFrom(payer, recipient, value);
		}
	}

	function transferNative(address recipient, uint256 value) internal {
		assembly ("memory-safe") {
			if iszero(call(gas(), recipient, value, 0x00, 0x00, 0x00, 0x00)) {
				mstore(0x00, 0xb06a467a) // TransferNativeFailed()
				revert(0x1c, 0x04)
			}
		}
	}
}
