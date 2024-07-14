// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {CommonBase} from "forge-std/Base.sol";
import {CurrencyNamer} from "src/libraries/CurrencyNamer.sol";
import {Currency} from "src/types/Currency.sol";
import {Constants} from "./Constants.sol";

abstract contract PermitSignature is CommonBase, Constants {
	using CurrencyNamer for Currency;

	struct Permit {
		address owner;
		address spender;
		uint256 value;
		uint256 nonce;
		uint256 deadline;
	}

	struct PermitAllowed {
		address holder;
		address spender;
		uint256 nonce;
		uint256 expiry;
		bool allowed;
	}

	bytes32 constant DOMAIN_TYPEHASH = 0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866;

	bytes32 constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

	bytes32 constant PERMIT_ALLOWED_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

	bytes32 constant DAI_DOMAIN_SEPARATOR = 0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7;

	function signPermit(
		Currency currency,
		uint256 privateKey,
		address spender,
		uint256 value,
		uint256 deadline
	) internal view returns (Permit memory permit, uint8 v, bytes32 r, bytes32 s) {
		if (canPermit(currency)) {
			address owner = vm.addr(privateKey);
			uint256 nonce = getNonce(currency, owner);

			permit = getStruct(owner, spender, value, nonce, deadline);

			(v, r, s) = vm.sign(privateKey, getTypedDataHash(permit, getEIP712Domain(currency)));
		}
	}

	function signPermit(
		Currency currency,
		uint256 privateKey,
		address spender,
		uint256 expiry
	) internal view returns (PermitAllowed memory permit, uint8 v, bytes32 r, bytes32 s) {
		if (getDomainSeparator(currency) == DAI_DOMAIN_SEPARATOR) {
			address holder = vm.addr(privateKey);
			uint256 nonce = getNonce(currency, holder);

			permit = getStruct(holder, spender, nonce, expiry);

			(v, r, s) = vm.sign(privateKey, getTypedDataHash(permit, DAI_DOMAIN_SEPARATOR));
		}
	}

	function canPermit(Currency currency) internal view returns (bool flag) {
		return getDomainSeparator(currency) != 0 || getPermitTypehash(currency) != 0;
	}

	function getEIP712Domain(Currency currency) internal view returns (bytes32 domainSeparator) {
		if ((domainSeparator = getDomainSeparator(currency)) == 0) {
			domainSeparator = keccak256(
				abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(currency.name())), block.chainid, currency)
			);
		}
	}

	function getDomainSeparator(Currency currency) internal view returns (bytes32 domainSeparator) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x3644e51500000000000000000000000000000000000000000000000000000000) // DOMAIN_SEPARATOR()

			if iszero(iszero(staticcall(gas(), currency, ptr, 0x04, 0x00, 0x20))) {
				domainSeparator := mload(0x00)
			}
		}
	}

	function getPermitTypehash(Currency currency) internal view returns (bytes32 permitTypehash) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x30adf81f00000000000000000000000000000000000000000000000000000000) // PERMIT_TYPEHASH()

			if iszero(iszero(staticcall(gas(), currency, ptr, 0x04, 0x00, 0x20))) {
				permitTypehash := mload(0x00)
			}
		}
	}

	function getNonce(Currency currency, address owner) internal view returns (uint256 nonce) {
		bytes4 selector = currency == AAVE ? bytes4(0xb9844d8d) : bytes4(0x7ecebe00);

		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, selector)
			mstore(add(ptr, 0x04), owner)

			if iszero(staticcall(gas(), currency, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			nonce := mload(0x00)
		}
	}

	function getStruct(
		address owner,
		address spender,
		uint256 value,
		uint256 nonce,
		uint256 deadline
	) internal pure returns (Permit memory permit) {
		return Permit({owner: owner, spender: spender, value: value, nonce: nonce, deadline: deadline});
	}

	function getStruct(
		address holder,
		address spender,
		uint256 nonce,
		uint256 expiry
	) internal pure returns (PermitAllowed memory permit) {
		return PermitAllowed({holder: holder, spender: spender, nonce: nonce, expiry: expiry, allowed: true});
	}

	function getStructHash(Permit memory permit) internal pure returns (bytes32 digest) {
		return
			keccak256(
				abi.encode(PERMIT_TYPEHASH, permit.owner, permit.spender, permit.value, permit.nonce, permit.deadline)
			);
	}

	function getStructHash(PermitAllowed memory permit) internal pure returns (bytes32 digest) {
		return
			keccak256(
				abi.encode(
					PERMIT_ALLOWED_TYPEHASH,
					permit.holder,
					permit.spender,
					permit.nonce,
					permit.expiry,
					permit.allowed
				)
			);
	}

	function getTypedDataHash(Permit memory permit, bytes32 domainSeparator) internal pure returns (bytes32 digest) {
		return toTypedDataHash(domainSeparator, getStructHash(permit));
	}

	function getTypedDataHash(
		PermitAllowed memory permit,
		bytes32 domainSeparator
	) internal pure returns (bytes32 digest) {
		return toTypedDataHash(domainSeparator, getStructHash(permit));
	}

	function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) private pure returns (bytes32 digest) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)
			mstore(ptr, hex"19_01")
			mstore(add(ptr, 0x02), domainSeparator)
			mstore(add(ptr, 0x22), structHash)
			digest := keccak256(ptr, 0x42)
		}
	}

	function encodeSignature(uint8 v, bytes32 r, bytes32 s) internal pure returns (bytes memory signature) {
		signature = bytes.concat(r, s, bytes1(v));
	}
}
