// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IV3SwapRouter} from "src/interfaces/IV3SwapRouter.sol";
import {CallbackValidation} from "src/libraries/CallbackValidation.sol";
import {Path} from "src/libraries/Path.sol";
import {PoolActions} from "src/libraries/PoolActions.sol";
import {PoolAddress} from "src/libraries/PoolAddress.sol";
import {SafeCast} from "src/libraries/SafeCast.sol";
import {Currency} from "src/types/Currency.sol";
import {Routing} from "./Routing.sol";

/// @title V3SwapRouter
/// @notice Router for Uniswap V3 trades

abstract contract V3SwapRouter is IV3SwapRouter, Routing {
	using Path for bytes;
	using PoolActions for address;
	using SafeCast for uint256;

	bytes4 private constant UNISWAP_V3_SWAP_CALLBACK_SELECTOR = 0xfa461e33;

	uint160 private constant MIN_SQRT_PRICE_LIMIT = 4295128740;
	uint160 private constant MAX_SQRT_PRICE_LIMIT = 1461446703485210103287273052203988822378723970341;

	function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata path) external {
		required(amount0Delta > 0 || amount1Delta > 0, INVALID_SWAP_ERROR);

		CallbackValidation.verifyCallback();

		(Currency currencyIn, Currency currencyOut, ) = path.decodeFirstPool();

		(bool isExactInput, uint256 amountToPay) = amount0Delta > 0
			? (currencyIn < currencyOut, uint256(amount0Delta))
			: (currencyOut < currencyIn, uint256(amount1Delta));

		if (isExactInput) {
			pay(currencyIn, payerCached(), msg.sender, amountToPay);
		} else {
			if (path.hasMultiplePools()) {
				v3Swap(false, -amountToPay.toInt256(), msg.sender, path.skipCurrency());
			} else {
				uint256 amountInMaxCached = amountInCached();
				required(amountInMaxCached >= amountToPay, INSUFFICIENT_AMOUNT_IN_ERROR);

				pay(currencyOut, payerCached(), msg.sender, amountToPay);

				cacheAmountIn(amountToPay);
			}
		}
	}

	function exactInput(
		bytes calldata path,
		address recipient,
		uint256 amountIn,
		uint256 amountOutMin,
		uint256 deadline
	) external payable checkDeadline(deadline) returns (uint256 amountOut) {
		return v3SwapExactInput(path, msg.sender, recipient, amountIn, amountOutMin);
	}

	function exactOutput(
		bytes calldata path,
		address recipient,
		uint256 amountOut,
		uint256 amountInMax,
		uint256 deadline
	) external payable checkDeadline(deadline) returns (uint256 amountIn) {
		return v3SwapExactOutput(path, msg.sender, recipient, amountOut, amountInMax);
	}

	function v3SwapExactInput(
		bytes calldata path,
		address payer,
		address recipient,
		uint256 amountIn,
		uint256 amountOutMin
	) internal returns (uint256 amountOut) {
		required(amountIn != 0, AMOUNT_IN_ZERO_ERROR);

		cacheSwapAction(SwapType.V3ExactInput);
		cachePayer(payer);

		while (true) {
			bool hasMultiplePools = path.hasMultiplePools();

			(int256 amount0Delta, int256 amount1Delta, bool zeroForOne) = v3Swap(
				true,
				amountIn.toInt256(),
				hasMultiplePools ? address(this) : recipient,
				path.getFirstPool()
			);

			amountIn = uint256(-(zeroForOne ? amount1Delta : amount0Delta));

			if (hasMultiplePools) {
				if (payerCached() != address(this)) cachePayer(address(this));
				path = path.skipCurrency();
			} else {
				amountOut = amountIn;
				break;
			}
		}

		required(amountOut >= amountOutMin, INSUFFICIENT_AMOUNT_OUT_ERROR);

		clearSwapActionCached();
		clearPayerCached();
	}

	function v3SwapExactOutput(
		bytes calldata path,
		address payer,
		address recipient,
		uint256 amountOut,
		uint256 amountInMax
	) internal returns (uint256 amountIn) {
		required(amountOut != 0, AMOUNT_OUT_ZERO_ERROR);
		required(amountInMax != 0, AMOUNT_IN_MAX_ZERO_ERROR);

		cacheSwapAction(SwapType.V3ExactOutput);
		cachePayer(payer);
		cacheAmountIn(amountInMax);

		(int256 amount0Delta, int256 amount1Delta, bool zeroForOne) = v3Swap(
			false,
			-amountOut.toInt256(),
			recipient,
			path
		);

		uint256 amountReceived = uint256(-(zeroForOne ? amount1Delta : amount0Delta));
		required(amountReceived == amountOut, INSUFFICIENT_AMOUNT_OUT_ERROR);
		required((amountIn = amountInCached()) <= amountInMax, INSUFFICIENT_AMOUNT_IN_ERROR);

		clearSwapActionCached();
		clearPayerCached();
		clearAmountInCached();
	}

	function v3Swap(
		bool isExactInput,
		int256 amountSpecified,
		address recipient,
		bytes calldata path
	) private returns (int256 amount0Delta, int256 amount1Delta, bool zeroForOne) {
		(Currency currencyIn, Currency currencyOut, uint24 fee) = path.decodeFirstPool();

		address pool = getPool(currencyIn, currencyOut, fee);

		CallbackValidation.setCallback(pool, UNISWAP_V3_SWAP_CALLBACK_SELECTOR);

		(amount0Delta, amount1Delta) = pool.swap(
			recipient,
			(zeroForOne = isExactInput ? currencyIn < currencyOut : currencyOut < currencyIn),
			amountSpecified,
			(zeroForOne ? MIN_SQRT_PRICE_LIMIT : MAX_SQRT_PRICE_LIMIT),
			path
		);
	}

	function getPool(Currency currency0, Currency currency1, uint24 fee) private view returns (address pool) {
		return PoolAddress.compute(UNISWAP_V3_FACTORY, UNISWAP_V3_POOL_INIT_CODE_HASH, currency0, currency1, fee);
	}
}
