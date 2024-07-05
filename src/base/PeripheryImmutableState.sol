// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";

/// @title PeripheryImmutableState
/// @notice Immutable state used by periphery contracts
/// @dev Modified from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/PeripheryImmutableState.sol

abstract contract PeripheryImmutableState {
	address public immutable factory;

	Currency public immutable WETH9;

	constructor(address _factory, Currency _WETH9) {
		factory = _factory;
		WETH9 = _WETH9;
	}
}
