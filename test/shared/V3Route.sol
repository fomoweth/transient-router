// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IUniswapV3Factory} from "src/interfaces/external/Uniswap/V3/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "src/interfaces/external/Uniswap/V3/IUniswapV3Pool.sol";
import {IQuoterV2} from "src/interfaces/external/Uniswap/V3/IQuoterV2.sol";
import {Math} from "src/libraries/Math.sol";
import {Currency} from "src/types/Currency.sol";
import {Arrays} from "test/shared/utils/Arrays.sol";
import {Common} from "test/shared/Common.sol";

abstract contract V3Route is Common {
	using Arrays for Currency[];
	using Arrays for uint24[];
	using Math for uint256;

	IUniswapV3Factory constant V3_FACTORY = IUniswapV3Factory(UNISWAP_V3_FACTORY);

	IQuoterV2 constant V3_QUOTER = IQuoterV2(UNISWAP_V3_QUOTER);

	function prepareTrades(
		Currency[] memory currencies,
		uint24[] memory fees,
		bool isExactInput,
		uint256 ethAmount
	) internal view returns (bytes memory path, uint256 amountIn, uint256 amountOut) {
		Currency currencyIn = currencies[0];
		Currency currencyOut = currencies[currencies.length - 1];

		if (isExactInput) {
			path = encodePath(currencies, fees, true);

			uint256 price = getAnswer(currencyIn, ETH);
			uint256 ratio = price.inverse(currencyIn.decimals(), 18);

			amountIn = ratio * ethAmount;
			amountOut = quoteExactInput(path, amountIn);
		} else {
			path = encodePath(currencies, fees, false);

			uint256 price = getAnswer(currencyOut, ETH);
			uint256 ratio = price.inverse(currencyOut.decimals(), 18);

			amountOut = ratio * ethAmount;
			amountIn = quoteExactOutput(path, amountOut);
		}
	}

	function performTrades(
		Currency[] memory currencies,
		uint24[] memory fees,
		bool isExactInput,
		uint256 ethAmount
	) internal returns (uint256 amountIn, uint256 amountOut) {
		bytes memory path;
		(path, amountIn, amountOut) = prepareTrades(currencies, fees, isExactInput, ethAmount);

		assertNotZero(amountIn, "!amountIn");
		assertNotZero(amountOut, "!amountOut");

		Currency currencyIn = currencies[0];
		Currency currencyOut = currencies[currencies.length - 1];

		deal(currencyIn, SENDER, amountIn);

		uint256 balanceIn = currencyIn.balanceOf(SENDER);
		uint256 balanceOut = currencyOut.balanceOf(RECIPIENT);

		if (isExactInput) {
			amountOut = performExactInput(path, amountIn, amountOut);
		} else {
			amountIn = performExactOutput(path, amountOut, amountIn);
		}

		assertEq(currencyIn.balanceOf(SENDER), balanceIn - amountIn, "balanceIn");
		assertEq(currencyOut.balanceOf(RECIPIENT), balanceOut + amountOut, "balanceOut");
	}

	function performExactInput(
		bytes memory path,
		uint256 amountIn,
		uint256 amountOutMin
	) internal returns (uint256 amountOut) {
		vm.prank(SENDER);

		amountOut = router.exactInput(path, RECIPIENT, amountIn, amountOutMin, DEADLINE);
	}

	function performExactOutput(
		bytes memory path,
		uint256 amountOut,
		uint256 amountInMax
	) internal returns (uint256 amountIn) {
		vm.prank(SENDER);

		amountIn = router.exactOutput(path, RECIPIENT, amountOut, amountInMax, DEADLINE);
	}

	function quoteExactInput(bytes memory path, uint256 amountIn) internal view returns (uint256 amountOut) {
		(amountOut, , , ) = V3_QUOTER.quoteExactInput(path, amountIn);
	}

	function quoteExactOutput(bytes memory path, uint256 amountOut) internal view returns (uint256 amountIn) {
		(amountIn, , , ) = V3_QUOTER.quoteExactOutput(path, amountOut);
	}

	function encodePath(
		Currency[] memory currencies,
		uint24[] memory fees,
		bool isExactInput
	) internal pure returns (bytes memory path) {
		assertGe(currencies.length, 2, "!currencies");
		assertGe(fees.length, 1, "!fees");
		assertEq(currencies.length - 1, fees.length);

		if (!isExactInput) {
			currencies = currencies.reverse();
			fees = fees.reverse();
		}

		path = abi.encodePacked(currencies[0]);

		for (uint256 i; i < fees.length; ++i) {
			path = abi.encodePacked(path, fees[i], currencies[i + 1]);
		}
	}

	function getPool(Currency currencyA, Currency currencyB, uint24 fee) internal view returns (IUniswapV3Pool) {
		address pool = V3_FACTORY.getPool(currencyA, currencyB, fee);
		assertTrue(pool != address(0), "!pool");

		return IUniswapV3Pool(pool);
	}

	function getFees(uint24 fee0) internal pure returns (uint24[] memory fees) {
		fees = new uint24[](1);
		fees[0] = fee0;
	}

	function getFees(uint24 fee0, uint24 fee1) internal pure returns (uint24[] memory fees) {
		fees = new uint24[](2);
		fees[0] = fee0;
		fees[1] = fee1;
	}

	function getFees(uint24 fee0, uint24 fee1, uint24 fee2) internal pure returns (uint24[] memory fees) {
		fees = new uint24[](3);
		fees[0] = fee0;
		fees[1] = fee1;
		fees[2] = fee2;
	}

	function getFees(uint24 fee0, uint24 fee1, uint24 fee2, uint24 fee3) internal pure returns (uint24[] memory fees) {
		fees = new uint24[](4);
		fees[0] = fee0;
		fees[1] = fee1;
		fees[2] = fee2;
		fees[3] = fee3;
	}
}
