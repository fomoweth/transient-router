// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";
import {RouterTestBase} from "test/shared/RouterTestBase.t.sol";

abstract contract V3SwapRouterTest is RouterTestBase {}

contract V3SwapRouter2Pools is V3SwapRouterTest {
	function test_exactInputSingle() public {
		// WBTC -> WETH
		performTrades(getCurrencies(WBTC, WETH), getFees(FEE_LOW), true, ETH_AMOUNT);

		// USDC -> WETH
		performTrades(getCurrencies(USDC, WETH), getFees(FEE_LOW), true, ETH_AMOUNT);
	}

	function test_exactInput() public {
		// WBTC -> WETH -> USDC
		performTrades(getCurrencies(WBTC, WETH, USDC), getFees(FEE_LOW, FEE_LOW), true, ETH_AMOUNT);

		// USDC -> WETH -> WBTC
		performTrades(getCurrencies(USDC, WETH, WBTC), getFees(FEE_LOW, FEE_LOW), true, ETH_AMOUNT);
	}

	function test_exactOutputSingle() public {
		// WETH -> WBTC
		performTrades(getCurrencies(WBTC, WETH), getFees(FEE_LOW), false, ETH_AMOUNT);

		// WETH -> USDC
		performTrades(getCurrencies(USDC, WETH), getFees(FEE_LOW), false, ETH_AMOUNT);
	}

	function test_exactOutput() public {
		// USDC -> WETH -> WBTC
		performTrades(getCurrencies(WBTC, WETH, USDC), getFees(FEE_LOW, FEE_LOW), false, ETH_AMOUNT);

		// WBTC -> WETH -> USDC
		performTrades(getCurrencies(USDC, WETH, WBTC), getFees(FEE_LOW, FEE_LOW), false, ETH_AMOUNT);
	}

	function getCurrencies() internal pure virtual override returns (Currency[] memory currencies) {
		currencies = new Currency[](3);
		currencies[0] = WETH;
		currencies[1] = WBTC;
		currencies[2] = USDC;
	}
}

contract V3SwapRouter3Pools is V3SwapRouterTest {
	function test_exactInputSingle() public {
		// AAVE -> COMP
		performTrades(getCurrencies(AAVE, COMP), getFees(FEE_HIGH), true, ETH_AMOUNT);

		// COMP -> AAVE
		performTrades(getCurrencies(COMP, AAVE), getFees(FEE_HIGH), true, ETH_AMOUNT);
	}

	function test_exactInput() public {
		// WETH -> AAVE -> COMP -> WETH
		performTrades(getCurrencies(WETH, AAVE, COMP, WETH), getFees(FEE_MEDIUM, FEE_HIGH, FEE_HIGH), true, ETH_AMOUNT);

		// WETH -> COMP -> AAVE -> WETH
		performTrades(getCurrencies(WETH, COMP, AAVE, WETH), getFees(FEE_HIGH, FEE_HIGH, FEE_MEDIUM), true, ETH_AMOUNT);
	}

	function test_exactOutputSingle() public {
		// COMP -> AAVE
		performTrades(getCurrencies(AAVE, COMP), getFees(FEE_HIGH), false, ETH_AMOUNT);

		// AAVE -> COMP
		performTrades(getCurrencies(COMP, AAVE), getFees(FEE_HIGH), false, ETH_AMOUNT);
	}

	function test_exactOutput() public {
		// WETH -> COMP -> AAVE -> WETH
		performTrades(
			getCurrencies(WETH, AAVE, COMP, WETH),
			getFees(FEE_MEDIUM, FEE_HIGH, FEE_HIGH),
			false,
			ETH_AMOUNT
		);

		// WETH -> AAVE -> COMP -> WETH
		performTrades(
			getCurrencies(WETH, COMP, AAVE, WETH),
			getFees(FEE_HIGH, FEE_HIGH, FEE_MEDIUM),
			false,
			ETH_AMOUNT
		);
	}

	function getCurrencies() internal pure virtual override returns (Currency[] memory currencies) {
		currencies = new Currency[](3);
		currencies[0] = WETH;
		currencies[1] = AAVE;
		currencies[2] = COMP;
	}
}
