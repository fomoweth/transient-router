// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {SwapRouter, ImmutableState} from "src/SwapRouter.sol";
import {Create3} from "src/libraries/Create3.sol";
import {PoolAddress} from "src/libraries/PoolAddress.sol";
import {Currency} from "src/types/Currency.sol";
import {Arrays} from "test/shared/utils/Arrays.sol";
import {TestBase} from "./TestBase.t.sol";

abstract contract RouterTestBase is TestBase {
	using Arrays for Currency[];
	using Arrays for uint24[];

	uint256 constant ETH_AMOUNT = 5;

	SwapRouter router;

	function setUp() public virtual {
		fork(true);
		deployRouter();
		setApprovals(SENDER);
	}

	function deployRouter() internal {
		ImmutableState memory params = ImmutableState({
			weth9: WETH,
			v3Factory: UNISWAP_V3_FACTORY,
			poolInitCodeHash: UNISWAP_V3_POOL_INIT_CODE_HASH,
			v2Factory: UNISWAP_V2_FACTORY,
			pairInitCodeHash: UNISWAP_V2_PAIR_INIT_CODE_HASH
		});

		bytes32 salt = keccak256(bytes("SwapRouterV1"));

		bytes memory creationCode = type(SwapRouter).creationCode;
		bytes memory bytecode = abi.encodePacked(creationCode, abi.encode(params));

		router = SwapRouter(payable(create3("SwapRouter", salt, bytecode)));
	}

	function setApprovals(address account) internal virtual {
		deal(SENDER, 1000 ether);

		vm.startPrank(account);

		Currency[] memory currencies = getCurrencies();

		for (uint256 i; i < currencies.length; ++i) {
			currencies[i].approve(address(router), MAX_UINT256);
		}

		vm.stopPrank();
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

	function getCurrencies() internal pure virtual returns (Currency[] memory currencies) {}

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
