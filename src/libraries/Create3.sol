// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Create3
/// @dev Modified from https://github.com/Vectorized/solady/blob/main/src/utils/CREATE3.sol

library Create3 {
	uint256 private constant PROXY_BYTECODE = 0x67363d3d37363d34f03d5260086018f3;

	bytes32 private constant PROXY_BYTECODE_HASH = 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

	function create3(bytes32 salt, bytes memory creationCode) internal returns (address) {
		return create3(salt, creationCode, 0);
	}

	function create3(bytes32 salt, bytes memory creationCode, uint256 value) internal returns (address instance) {
		instance = addressOf(salt);

		assembly ("memory-safe") {
			if iszero(iszero(extcodesize(instance))) {
				mstore(0x00, 0xcd43efa1) // TargetAlreadyExists()
				revert(0x1c, 0x04)
			}

			mstore(0x00, PROXY_BYTECODE)

			let proxy := create2(0x00, 0x10, 0x10, salt)

			if iszero(proxy) {
				mstore(0x00, 0xd49e7d74) // ProxyCreationFailed()
				revert(0x1c, 0x04)
			}

			mstore(0x14, proxy)
			mstore(0x00, 0xd694)
			mstore8(0x34, 0x01)

			instance := keccak256(0x1e, 0x17)

			if iszero(
				and(
					iszero(iszero(extcodesize(instance))),
					call(gas(), proxy, value, add(creationCode, 0x20), mload(creationCode), 0x00, 0x00)
				)
			) {
				mstore(0x00, 0xa28c2473) // ContractCreationFailed()
				revert(0x1c, 0x04)
			}
		}
	}

	function addressOf(bytes32 salt) internal view returns (address instance) {
		return addressOf(salt, address(this));
	}

	function addressOf(bytes32 salt, address deployer) internal pure returns (address instance) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(0x00, deployer)
			mstore8(0x0b, 0xff)
			mstore(0x20, salt)
			mstore(0x40, PROXY_BYTECODE_HASH)
			mstore(0x14, keccak256(0x0b, 0x55))

			mstore(0x40, ptr)
			mstore(0x00, 0xd694)
			mstore8(0x34, 0x01)

			instance := keccak256(0x1e, 0x17)
		}
	}
}
