// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {StdCheats} from "forge-std/StdCheats.sol";
import {IAggregator} from "src/interfaces/external/ChainLink/IAggregator.sol";
import {PoolAddress} from "src/libraries/PoolAddress.sol";
import {Currency} from "src/types/Currency.sol";
import {Assertion} from "./Assertion.sol";
import {Deployer} from "./Deployer.sol";

abstract contract Common is Deployer, Assertion, StdCheats {
	uint256 immutable SENDER_KEY = encodePrivateKey("SENDER");
	address immutable SENDER = makeAddr("SENDER");

	uint256 immutable RECIPIENT_KEY = encodePrivateKey("RECIPIENT");
	address immutable RECIPIENT = makeAddr("RECIPIENT");

	function fork(bool forkOnBlock) internal {
		if (!forkOnBlock) {
			vm.createSelectFork(vm.envString("RPC_ETHEREUM"));
		} else {
			vm.createSelectFork(vm.envString("RPC_ETHEREUM"), vm.envUint("FORK_BLOCK_ETHEREUM"));
		}
	}

	function encodePrivateKey(string memory desc) internal pure returns (uint256 privateKey) {
		return uint256(keccak256(abi.encodePacked(desc)));
	}

	function deal(Currency currency, uint256 amount) internal {
		deal(currency, address(this), amount);
	}

	function deal(Currency currency, address account, uint256 amount) internal {
		deal(Currency.unwrap(currency), account, amount);
	}

	function getAnswer(Currency base, address quote) internal view returns (uint256) {
		if (base == WETH && quote == ETH) return 1 ether;

		int256 answer = FEED_REGISTRY.latestAnswer(_resolveBase(base), _resolveQuote(quote));
		assertGt(answer, 0, "!answer");

		return uint256(answer);
	}

	function getDecimals(Currency base, address quote) internal view returns (uint8) {
		return FEED_REGISTRY.decimals(_resolveBase(base), _resolveQuote(quote));
	}

	function getFeed(Currency base, address quote) internal view returns (IAggregator) {
		return FEED_REGISTRY.getFeed(_resolveBase(base), _resolveQuote(quote));
	}

	function _resolveBase(Currency currency) private pure returns (address) {
		assertTrue(!currency.isZero(), "!base");

		if (currency == WETH) return ETH;
		if (currency == WBTC) return BTC;

		return Currency.unwrap(currency);
	}

	function _resolveQuote(address quote) private pure returns (address) {
		assertTrue(quote == ETH || quote == USD, "!quote");
		return quote;
	}

	function computePool(Currency currencyA, Currency currencyB, uint24 fee) internal view returns (address pool) {
		return PoolAddress.compute(UNISWAP_V3_FACTORY, UNISWAP_V3_POOL_INIT_CODE_HASH, currencyA, currencyB, fee);
	}

	function computePair(Currency currencyA, Currency currencyB) internal view returns (address pair) {
		return PoolAddress.compute(UNISWAP_V2_FACTORY, UNISWAP_V2_PAIR_INIT_CODE_HASH, currencyA, currencyB);
	}

	function getCurrencies(Currency currency0) internal pure virtual returns (Currency[] memory currencies) {
		currencies = new Currency[](1);
		currencies[0] = currency0;
	}

	function getCurrencies(
		Currency currency0,
		Currency currency1
	) internal pure virtual returns (Currency[] memory currencies) {
		currencies = new Currency[](2);
		currencies[0] = currency0;
		currencies[1] = currency1;
	}

	function getCurrencies(
		Currency currency0,
		Currency currency1,
		Currency currency2
	) internal pure virtual returns (Currency[] memory currencies) {
		currencies = new Currency[](3);
		currencies[0] = currency0;
		currencies[1] = currency1;
		currencies[2] = currency2;
	}

	function getCurrencies(
		Currency currency0,
		Currency currency1,
		Currency currency2,
		Currency currency3
	) internal pure virtual returns (Currency[] memory currencies) {
		currencies = new Currency[](4);
		currencies[0] = currency0;
		currencies[1] = currency1;
		currencies[2] = currency2;
		currencies[3] = currency3;
	}
}
