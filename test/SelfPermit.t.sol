// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";
import {RouterTestBase} from "test/shared/RouterTestBase.t.sol";

contract SelfPermitTest is RouterTestBase {
	uint256 constant DELAY = 3 minutes;

	function test_selfPermit() public {
		testSelfPermit(AAVE);
		testSelfPermit(UNI);
		testSelfPermit(STETH);
		testSelfPermit(WSTETH);
	}

	function testSelfPermit(Currency currency) internal {
		uint256 value = 1000 ether;
		uint256 deadline = block.timestamp + DELAY;

		vm.startPrank(SENDER);

		(Permit memory permit, uint8 v, bytes32 r, bytes32 s) = signPermit(
			currency,
			SENDER_KEY,
			address(router),
			value,
			deadline
		);

		assertEq(permit.owner, SENDER, "!owner");
		assertEq(permit.spender, address(router), "!spender");
		assertEq(permit.value, value, "!value");
		assertEq(permit.deadline, deadline, "!deadline");
		assertZero(currency.allowance(permit.owner, permit.spender), "allowance != 0");

		router.selfPermit(currency, permit.value, permit.deadline, v, r, s);

		assertEq(currency.allowance(permit.owner, permit.spender), value, "allowance != value");
		assertEq(permit.nonce + 1, getNonce(currency, permit.owner), "!nonce");

		vm.stopPrank();
	}

	function test_selfPermitAllowed() public {
		Currency currency = DAI;
		uint256 expiry = block.timestamp + DELAY;

		vm.startPrank(SENDER);

		(PermitAllowed memory permit, uint8 v, bytes32 r, bytes32 s) = signPermit(
			currency,
			SENDER_KEY,
			address(router),
			expiry
		);

		assertEq(permit.holder, SENDER, "!holder");
		assertEq(permit.spender, address(router), "!spender");
		assertEq(permit.expiry, expiry, "!expiry");
		assertTrue(permit.allowed, "!allowed");
		assertZero(currency.allowance(permit.holder, permit.spender), "allowance != 0");

		router.selfPermitAllowed(currency, permit.nonce, expiry, v, r, s);

		assertEq(currency.allowance(permit.holder, permit.spender), type(uint256).max, "allowance != amount");
		assertEq(permit.nonce + 1, getNonce(currency, permit.holder), "!nonce");

		vm.stopPrank();
	}
}
