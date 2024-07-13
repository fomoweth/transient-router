// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";

interface IPeripheryPayments {
	function pull(Currency currency, uint256 value) external payable;

	function wrapETH(uint256 value) external payable;

	function unwrapWETH(uint256 value) external payable;

	function refund(Currency currency) external payable;

	function refundETH(bool unwrap) external payable;
}
