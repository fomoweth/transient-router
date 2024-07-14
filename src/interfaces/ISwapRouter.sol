// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IMulticall} from "./IMulticall.sol";
import {ISelfPermit} from "./ISelfPermit.sol";
import {IV2SwapRouter} from "./IV2SwapRouter.sol";
import {IV3SwapRouter} from "./IV3SwapRouter.sol";

interface ISwapRouter is IV2SwapRouter, IV3SwapRouter, IMulticall, ISelfPermit {}
