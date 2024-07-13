// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console2 as console} from "forge-std/Test.sol";
import {IAggregator} from "src/interfaces/external/ChainLink/IAggregator.sol";
import {Create3} from "src/libraries/Create3.sol";
import {PoolAddress} from "src/libraries/PoolAddress.sol";
import {Currency} from "src/types/Currency.sol";
import {Assertion} from "./Assertion.sol";
import {Constants} from "./Constants.sol";

abstract contract TestBase is Test, Assertion, Constants {
	address immutable SENDER = makeAddr("SENDER");
	address immutable RECIPIENT = makeAddr("RECIPIENT");

	function create3(string memory label, bytes32 salt, bytes memory creationCode) internal returns (address deployed) {
		vm.label((deployed = Create3.create3(encodeSalt(salt, address(this)), creationCode)), label);
	}

	function fork(bool forkOnBlock) internal {
		if (!forkOnBlock) {
			vm.createSelectFork(vm.envString("RPC_ETHEREUM"));
		} else {
			vm.createSelectFork(vm.envString("RPC_ETHEREUM"), vm.envUint("FORK_BLOCK_ETHEREUM"));
		}
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

	function computePool(Currency currencyA, Currency currencyB, uint24 fee) internal view returns (address pool) {
		pool = PoolAddress.compute(UNISWAP_V3_FACTORY, UNISWAP_V3_POOL_INIT_CODE_HASH, currencyA, currencyB, fee);
	}

	function computePair(Currency currencyA, Currency currencyB) internal view returns (address pair) {
		return PoolAddress.compute(UNISWAP_V2_FACTORY, UNISWAP_V2_PAIR_INIT_CODE_HASH, currencyA, currencyB);
	}

	function encodeSalt(bytes32 salt, address deployer) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked(deployer, salt));
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
}
