// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";

struct ImmutableState {
	Currency weth9;
	address v3Factory;
	bytes32 poolInitCodeHash;
	address v2Factory;
	bytes32 pairInitCodeHash;
}

/// @title PeripheryImmutableState
/// @notice Immutable states used by router

abstract contract PeripheryImmutableState {
	Currency internal immutable WETH9;

	address internal immutable UNISWAP_V3_FACTORY;

	bytes32 internal immutable UNISWAP_V3_POOL_INIT_CODE_HASH;

	address internal immutable UNISWAP_V2_FACTORY;

	bytes32 internal immutable UNISWAP_V2_PAIR_INIT_CODE_HASH;

	constructor(ImmutableState memory params) {
		WETH9 = params.weth9;
		UNISWAP_V3_FACTORY = params.v3Factory;
		UNISWAP_V3_POOL_INIT_CODE_HASH = params.poolInitCodeHash;
		UNISWAP_V2_FACTORY = params.v2Factory;
		UNISWAP_V2_PAIR_INIT_CODE_HASH = params.pairInitCodeHash;
	}
}
