// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IV2SwapRouter} from "src/interfaces/IV2SwapRouter.sol";
import {CallbackValidation} from "src/libraries/CallbackValidation.sol";
import {PoolActions} from "src/libraries/PoolActions.sol";
import {PoolAddress} from "src/libraries/PoolAddress.sol";
import {Currency} from "src/types/Currency.sol";
import {Routing} from "./Routing.sol";

/// @title V2SwapRouter
/// @notice Router for Uniswap V2 trades

abstract contract V2SwapRouter is IV2SwapRouter, Routing {
	using PoolActions for address;

	function swapExactTokensForTokens(
		Currency[] calldata path,
		address recipient,
		uint256 amountIn,
		uint256 amountOutMin,
		uint256 deadline
	) external payable checkDeadline(deadline) returns (uint256 amountOut) {
		return v2SwapExactInput(path, msg.sender, recipient, amountIn, amountOutMin);
	}

	function swapTokensForExactTokens(
		Currency[] calldata path,
		address recipient,
		uint256 amountOut,
		uint256 amountInMax,
		uint256 deadline
	) external payable checkDeadline(deadline) returns (uint256 amountIn) {
		return v2SwapExactOutput(path, msg.sender, recipient, amountOut, amountInMax);
	}

	function v2SwapExactInput(
		Currency[] calldata path,
		address payer,
		address recipient,
		uint256 amountIn,
		uint256 amountOutMin
	) internal returns (uint256 amountOut) {
		required(path.length > 1, INVALID_PATH_LENGTH_ERROR);
		required(amountIn != 0, AMOUNT_IN_ZERO_ERROR);

		cacheSwapAction(SwapType.V2ExactInput);

		address firstPair = pairFor(path[0], path[1]);
		pay(path[0], payer, firstPair, amountIn);

		Currency currencyOut = path[path.length - 1];
		uint256 balanceOut = currencyOut.balanceOf(recipient);

		v2Swap(path, recipient, firstPair);

		amountOut = currencyOut.balanceOf(recipient) - balanceOut;
		required(amountOut != 0 && amountOut >= amountOutMin, INSUFFICIENT_AMOUNT_OUT_ERROR);

		clearSwapActionCached();
	}

	function v2SwapExactOutput(
		Currency[] calldata path,
		address payer,
		address recipient,
		uint256 amountOut,
		uint256 amountInMax
	) internal returns (uint256 amountIn) {
		required(path.length > 1, INVALID_PATH_LENGTH_ERROR);
		required(amountOut != 0, AMOUNT_OUT_ZERO_ERROR);
		required(amountInMax != 0, AMOUNT_IN_MAX_ZERO_ERROR);

		cacheSwapAction(SwapType.V2ExactOutput);

		address firstPair;
		(amountIn, firstPair) = getAmountInAndFirstPair(path, amountOut);
		required(amountIn != 0 && amountIn <= amountInMax, INSUFFICIENT_AMOUNT_IN_ERROR);

		pay(path[0], payer, firstPair, amountIn);

		v2Swap(path, recipient, firstPair);

		clearSwapActionCached();
	}

	function v2Swap(Currency[] calldata path, address recipient, address pair) private {
		unchecked {
			uint256 lastIndex = path.length - 1;
			uint256 penultimateIndex = lastIndex - 1;

			uint256 amountIn;
			uint256 amountOut;

			for (uint256 i; i < lastIndex; ++i) {
				(Currency currencyIn, Currency currencyOut) = (path[i], path[i + 1]);

				bool zeroForOne = currencyIn < currencyOut;

				(uint256 reserveIn, uint256 reserveOut) = getReserves(pair, zeroForOne);
				required(reserveIn != 0 && reserveOut != 0, INSUFFICIENT_RESERVES_ERROR, pair);

				required((amountIn = currencyIn.balanceOf(pair) - reserveIn) != 0, INSUFFICIENT_AMOUNT_IN_ERROR);
				required(
					(amountOut = computeAmountOut(reserveIn, reserveOut, amountIn)) != 0,
					INSUFFICIENT_AMOUNT_OUT_ERROR
				);

				address nextPair = i < penultimateIndex ? pairFor(currencyOut, path[i + 2]) : recipient;

				pair.swap(zeroForOne, amountOut, nextPair, _zeroBytes());

				pair = nextPair;
			}
		}
	}

	function getAmountInAndFirstPair(
		Currency[] calldata path,
		uint256 amountOut
	) internal view returns (uint256 amountIn, address pair) {
		unchecked {
			amountIn = amountOut;

			uint256 length = path.length - 1;

			for (uint256 i = length; i > 0; --i) {
				(Currency currencyIn, Currency currencyOut) = (path[i - 1], path[i]);

				(uint256 reserveIn, uint256 reserveOut) = getReserves(
					(pair = pairFor(currencyIn, currencyOut)),
					currencyIn < currencyOut
				);

				required(reserveIn != 0 && reserveOut != 0, INSUFFICIENT_RESERVES_ERROR, pair);
				required(
					(amountIn = computeAmountIn(reserveIn, reserveOut, amountIn)) != 0,
					INSUFFICIENT_AMOUNT_IN_ERROR
				);
			}
		}
	}

	function getReserves(address pair, bool zeroForOne) internal view returns (uint256 reserveIn, uint256 reserveOut) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x0902f1ac00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), pair, ptr, 0x04, 0x00, 0x40)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			switch zeroForOne
			case 0x00 {
				reserveOut := mload(0x00)
				reserveIn := mload(0x20)
			}
			default {
				reserveIn := mload(0x00)
				reserveOut := mload(0x20)
			}
		}
	}

	function pairFor(Currency currencyA, Currency currencyB) private view returns (address pair) {
		return PoolAddress.compute(UNISWAP_V2_FACTORY, UNISWAP_V2_PAIR_INIT_CODE_HASH, currencyA, currencyB);
	}

	function computeAmountIn(
		uint256 reserveIn,
		uint256 reserveOut,
		uint256 amountOut
	) internal pure returns (uint256 amountIn) {
		assembly ("memory-safe") {
			if iszero(or(or(iszero(reserveIn), iszero(reserveOut)), iszero(amountOut))) {
				amountIn := add(div(mul(mul(reserveIn, amountOut), 1000), mul(sub(reserveOut, amountOut), 997)), 1)
			}
		}
	}

	function computeAmountOut(
		uint256 reserveIn,
		uint256 reserveOut,
		uint256 amountIn
	) internal pure returns (uint256 amountOut) {
		assembly ("memory-safe") {
			if iszero(or(or(iszero(reserveIn), iszero(reserveOut)), iszero(amountIn))) {
				amountIn := mul(amountIn, 997)
				amountOut := div(mul(amountIn, reserveOut), add(mul(reserveIn, 1000), amountIn))
			}
		}
	}

	function _zeroBytes() private pure returns (bytes calldata data) {
		assembly ("memory-safe") {
			data.length := 0
		}
	}
}
