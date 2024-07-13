// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ISelfPermit} from "src/interfaces/ISelfPermit.sol";
import {Currency} from "src/types/Currency.sol";

/// @title SelfPermit
/// @dev Modified from https://github.com/Uniswap/v3-periphery/blob/0.8/contracts/base/SelfPermit.sol

abstract contract SelfPermit is ISelfPermit {
	function selfPermit(
		Currency currency,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public payable {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xd505accf00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), caller())
			mstore(add(ptr, 0x24), address())
			mstore(add(ptr, 0x44), value)
			mstore(add(ptr, 0x64), deadline)
			mstore(add(ptr, 0x84), v)
			mstore(add(ptr, 0xa4), r)
			mstore(add(ptr, 0xc4), s)

			if iszero(call(gas(), currency, 0x00, ptr, 0xe4, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}
		}
	}

	function selfPermitIfNecessary(
		Currency currency,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external payable {
		if (shouldPermit(currency, value)) selfPermit(currency, value, deadline, v, r, s);
	}

	function selfPermitAllowed(
		Currency currency,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public payable {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x8fcbaf0c00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), caller())
			mstore(add(ptr, 0x24), address())
			mstore(add(ptr, 0x44), nonce)
			mstore(add(ptr, 0x64), expiry)
			mstore(add(ptr, 0x84), 0x01)
			mstore(add(ptr, 0xa4), v)
			mstore(add(ptr, 0xc4), r)
			mstore(add(ptr, 0xe4), s)

			if iszero(call(gas(), currency, 0x00, ptr, 0x104, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}
		}
	}

	function selfPermitAllowedIfNecessary(
		Currency currency,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external payable {
		if (shouldPermit(currency, type(uint256).max)) selfPermitAllowed(currency, nonce, expiry, v, r, s);
	}

	function shouldPermit(Currency currency, uint256 value) internal view virtual returns (bool) {
		return currency.allowance(msg.sender, address(this)) < value;
	}
}
