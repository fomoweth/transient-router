// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ISwapRouter} from "src/interfaces/ISwapRouter.sol";
import {Currency} from "src/types/Currency.sol";
import {Multicall} from "src/base/Multicall.sol";
import {PeripheryImmutableState, ImmutableState} from "src/base/PeripheryImmutableState.sol";
import {SelfPermit} from "src/base/SelfPermit.sol";
import {V2SwapRouter} from "./V2SwapRouter.sol";
import {V3SwapRouter} from "./V3SwapRouter.sol";

/// @title SwapRouter

contract SwapRouter is ISwapRouter, Multicall, SelfPermit, V2SwapRouter, V3SwapRouter {
	constructor(ImmutableState memory params) PeripheryImmutableState(params) {}
}
