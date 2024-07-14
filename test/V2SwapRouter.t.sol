// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";
import {RouterTestBase} from "test/shared/RouterTestBase.t.sol";

abstract contract V2SwapRouterTest is RouterTestBase {}

contract V2SwapRouter2Pools is V2SwapRouterTest {
	function test_exactInputSingle() public {
		// AAVE -> WETH
		performTrades(getCurrencies(AAVE, WETH), true, ETH_AMOUNT);

		// UNI -> WETH
		performTrades(getCurrencies(UNI, WETH), true, ETH_AMOUNT);
	}

	function test_exactInput() public {
		// AAVE -> WETH -> UNI
		performTrades(getCurrencies(AAVE, WETH, UNI), true, ETH_AMOUNT);

		// UNI -> WETH -> AAVE
		performTrades(getCurrencies(UNI, WETH, AAVE), true, ETH_AMOUNT);
	}

	function test_exactOutputSingle() public {
		// WETH -> AAVE
		performTrades(getCurrencies(AAVE, WETH), false, ETH_AMOUNT);

		// WETH -> UNI
		performTrades(getCurrencies(UNI, WETH), false, ETH_AMOUNT);
	}

	function test_exactOutput() public {
		// AAVE -> WETH -> UNI
		performTrades(getCurrencies(AAVE, WETH, UNI), false, ETH_AMOUNT);

		// UNI -> WETH -> AAVE
		performTrades(getCurrencies(UNI, WETH, AAVE), false, ETH_AMOUNT);
	}

	function getCurrencies() internal pure virtual override returns (Currency[] memory currencies) {
		currencies = new Currency[](3);
		currencies[0] = WETH;
		currencies[1] = AAVE;
		currencies[2] = UNI;
	}
}

contract V2SwapRouter3Pools is V2SwapRouterTest {
	function test_exactInputSingle() public {
		// DAI -> MKR
		performTrades(getCurrencies(DAI, MKR), true, ETH_AMOUNT);

		// MKR -> DAI
		performTrades(getCurrencies(MKR, DAI), true, ETH_AMOUNT);
	}

	function test_exactInput() public {
		// WETH -> DAI -> MKR -> WETH
		performTrades(getCurrencies(WETH, DAI, MKR, WETH), true, ETH_AMOUNT);

		// WETH -> MKR -> DAI -> WETH
		performTrades(getCurrencies(WETH, MKR, DAI, WETH), true, ETH_AMOUNT);
	}

	function test_exactOutputSingle() public {
		// MKR -> DAI
		performTrades(getCurrencies(DAI, MKR), false, ETH_AMOUNT);

		// DAI -> MKR
		performTrades(getCurrencies(MKR, DAI), false, ETH_AMOUNT);
	}

	function test_exactOutput() public {
		// WETH -> DAI -> MKR -> WETH
		performTrades(getCurrencies(WETH, DAI, MKR, WETH), false, ETH_AMOUNT);

		// WETH -> MKR -> DAI -> WETH
		performTrades(getCurrencies(WETH, MKR, DAI, WETH), false, ETH_AMOUNT);
	}

	function getCurrencies() internal pure virtual override returns (Currency[] memory currencies) {
		currencies = new Currency[](3);
		currencies[0] = WETH;
		currencies[1] = DAI;
		currencies[2] = MKR;
	}
}
