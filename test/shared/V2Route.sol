// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IUniswapV2Factory} from "src/interfaces/external/Uniswap/V2/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "src/interfaces/external/Uniswap/V2/IUniswapV2Pair.sol";
import {Math} from "src/libraries/Math.sol";
import {Currency} from "src/types/Currency.sol";
import {Common} from "test/shared/Common.sol";

abstract contract V2Route is Common {
	using Math for uint256;

	IUniswapV2Factory constant V2_FACTORY = IUniswapV2Factory(UNISWAP_V2_FACTORY);

	function prepareTrades(
		Currency[] memory path,
		bool isExactInput,
		uint256 ethAmount
	) internal view returns (uint256 amountIn, uint256 amountOut) {
		Currency currencyIn = path[0];
		Currency currencyOut = path[path.length - 1];

		if (isExactInput) {
			uint256 price = getAnswer(currencyIn, ETH);
			uint256 ratio = price.inverse(currencyIn.decimals(), 18);

			amountIn = ratio * ethAmount;
			amountOut = quoteExactOutput(path, amountIn);
		} else {
			uint256 price = getAnswer(currencyOut, ETH);
			uint256 ratio = price.inverse(currencyOut.decimals(), 18);

			amountOut = ratio * ethAmount;
			amountIn = quoteExactInput(path, amountOut);
		}
	}

	function performTrades(
		Currency[] memory path,
		bool isExactInput,
		uint256 ethAmount
	) internal returns (uint256 amountIn, uint256 amountOut) {
		(amountIn, amountOut) = prepareTrades(path, isExactInput, ethAmount);

		assertNotZero(amountIn, "!amountIn");
		assertNotZero(amountOut, "!amountOut");

		Currency currencyIn = path[0];
		Currency currencyOut = path[path.length - 1];

		deal(currencyIn, SENDER, amountIn);

		uint256 balanceIn = currencyIn.balanceOf(SENDER);
		uint256 balanceOut = currencyOut.balanceOf(RECIPIENT);

		vm.prank(SENDER);

		if (isExactInput) {
			amountOut = performExactInput(path, amountIn, amountOut);
		} else {
			amountIn = performExactOutput(path, amountOut, amountIn);
		}

		assertEq(currencyIn.balanceOf(SENDER), balanceIn - amountIn, "!balanceIn");
		assertGe(currencyOut.balanceOf(RECIPIENT), balanceOut + amountOut, "!balanceOut");
	}

	function performExactInput(
		Currency[] memory path,
		uint256 amountIn,
		uint256 amountOutMin
	) internal returns (uint256 amountOut) {
		amountOut = router.swapExactTokensForTokens(path, RECIPIENT, amountIn, amountOutMin, DEADLINE);
	}

	function performExactOutput(
		Currency[] memory path,
		uint256 amountOut,
		uint256 amountInMax
	) internal returns (uint256 amountIn) {
		amountIn = router.swapTokensForExactTokens(path, RECIPIENT, amountOut, amountInMax, DEADLINE);
	}

	function quoteExactInput(Currency[] memory path, uint256 amountOut) internal view returns (uint256 amountIn) {
		unchecked {
			amountIn = amountOut;

			uint256 length = path.length - 1;

			for (uint256 i = length; i > 0; --i) {
				if (amountIn == 0) return 0;

				IUniswapV2Pair pair = getPair(path[i - 1], path[i]);

				(uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
				assertNotZero(reserve0, "!reserve0");
				assertNotZero(reserve1, "!reserve1");

				(uint256 reserveIn, uint256 reserveOut) = path[i - 1] < path[i]
					? (reserve0, reserve1)
					: (reserve1, reserve0);

				amountIn = computeAmountIn(reserveIn, reserveOut, amountIn);
			}
		}
	}

	function quoteExactOutput(Currency[] memory path, uint256 amountIn) internal view returns (uint256 amountOut) {
		unchecked {
			amountOut = amountIn;

			uint256 length = path.length - 1;

			for (uint256 i; i < length; ++i) {
				if (amountOut == 0) return 0;

				IUniswapV2Pair pair = getPair(path[i], path[i + 1]);

				(uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
				assertNotZero(reserve0, "!reserve0");
				assertNotZero(reserve1, "!reserve1");

				(uint256 reserveIn, uint256 reserveOut) = path[i] < path[i + 1]
					? (reserve0, reserve1)
					: (reserve1, reserve0);

				amountOut = computeAmountOut(reserveIn, reserveOut, amountOut);
			}
		}
	}

	function getPair(Currency currencyA, Currency currencyB) internal view returns (IUniswapV2Pair) {
		address pair = V2_FACTORY.getPair(currencyA, currencyB);
		assertTrue(pair != address(0), "!pair");

		return IUniswapV2Pair(pair);
	}

	function computeAmountIn(
		uint256 reserveIn,
		uint256 reserveOut,
		uint256 amountOut
	) private pure returns (uint256 amountIn) {
		assembly ("memory-safe") {
			amountIn := add(div(mul(mul(reserveIn, amountOut), 1000), mul(sub(reserveOut, amountOut), 997)), 1)
		}
	}

	function computeAmountOut(
		uint256 reserveIn,
		uint256 reserveOut,
		uint256 amountIn
	) private pure returns (uint256 amountOut) {
		assembly ("memory-safe") {
			amountIn := mul(amountIn, 997)
			amountOut := div(mul(amountIn, reserveOut), add(mul(reserveIn, 1000), amountIn))
		}
	}
}
