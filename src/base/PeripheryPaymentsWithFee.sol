// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Wrapper} from "src/libraries/Wrapper.sol";
import {Currency} from "src/types/Currency.sol";
import {PeripheryPayments} from "./PeripheryPayments.sol";

/// @title PeripheryPaymentsWithFee
/// @dev Modified from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/PeripheryPaymentsWithFee.sol

abstract contract PeripheryPaymentsWithFee is PeripheryPayments {
	using Wrapper for Currency;

	function unwrapWETH9WithFee(
		uint256 amountMin,
		address recipient,
		uint256 feeBips,
		address feeRecipient
	) public payable {
		required(feeBips > 0 && feeBips <= 100, 0xad652cf0, feeBips); // FeeBipsOutOfBounds(uint256)

		uint256 balance = WETH9.balanceOfSelf();
		required(balance >= amountMin, 0xf4d678b8); // InsufficientBalance()

		if (balance != 0) {
			WETH9.unwrap(balance);
			uint256 feeAmount = (balance * feeBips) / 10000;
			if (feeAmount != 0) transferNative(feeRecipient, feeAmount);
			transferNative(recipient, balance - feeAmount);
		}
	}

	function sweepCurrencyWithFee(
		Currency currency,
		uint256 amountMin,
		address recipient,
		uint256 feeBips,
		address feeRecipient
	) public payable {
		required(feeBips > 0 && feeBips <= 100, 0xad652cf0, feeBips); // FeeBipsOutOfBounds(uint256)

		uint256 balance = currency.balanceOfSelf();
		required(balance >= amountMin, 0xf4d678b8); // InsufficientBalance()

		if (balance != 0) {
			uint256 feeAmount = (balance * feeBips) / 10000;
			if (feeAmount != 0) currency.transfer(feeRecipient, feeAmount);
			currency.transfer(recipient, balance - feeAmount);
		}
	}
}
