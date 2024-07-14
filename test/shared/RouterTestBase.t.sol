// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {SwapRouter, ImmutableState} from "src/SwapRouter.sol";
import {Create3} from "src/libraries/Create3.sol";
import {PoolAddress} from "src/libraries/PoolAddress.sol";
import {Currency} from "src/types/Currency.sol";
import {Arrays} from "test/shared/utils/Arrays.sol";
import {PermitSignature} from "./PermitSignature.sol";
import {V2Route} from "./V2Route.sol";
import {V3Route} from "./V3Route.sol";

abstract contract RouterTestBase is Test, V2Route, V3Route, PermitSignature {
	using Arrays for Currency[];
	using Arrays for uint24[];

	uint256 constant ETH_AMOUNT = 5;

	function setUp() public virtual {
		fork(true);
		deployRouter();
		setApprovals(SENDER);
	}

	function setApprovals(address account) internal {
		deal(SENDER, 1000 ether);

		vm.startPrank(account);

		Currency[] memory currencies = getCurrencies();

		for (uint256 i; i < currencies.length; ++i) {
			currencies[i].approve(address(router), MAX_UINT256);
		}

		vm.stopPrank();
	}

	function getCurrencies() internal pure virtual returns (Currency[] memory currencies) {}
}
