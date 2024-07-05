// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IMulticall} from "src/interfaces/IMulticall.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
/// @dev Implementation from https://github.com/Vectorized/solady/blob/main/src/utils/Multicallable.sol

abstract contract Multicall is IMulticall {
	function multicall(bytes[] calldata data) external payable returns (bytes[] memory) {
		assembly ("memory-safe") {
			mstore(0x00, 0x20)
			mstore(0x20, data.length)

			if iszero(data.length) {
				return(0x00, 0x40)
			}

			let results := 0x40
			let guard := shl(0x05, data.length)

			calldatacopy(0x40, data.offset, guard)

			let res := guard
			guard := add(results, guard)

			// prettier-ignore
			for {} 0x01 {} {
				let offset := add(data.offset, mload(results))
				let ptr := add(res, 0x40)

				calldatacopy(ptr, add(offset, 0x20), calldataload(offset))

				if iszero(delegatecall(gas(), address(), ptr, calldataload(offset), codesize(), 0x00)) {
					returndatacopy(0x00, 0x00, returndatasize())
					revert(0x00, returndatasize())
				}

				mstore(results, res)
				results := add(results, 0x20)

				mstore(ptr, returndatasize())
				returndatacopy(add(ptr, 0x20), 0x00, returndatasize())

				res := and(add(add(res, returndatasize()), 0x3f), 0xffffffffffffffe0)
				if iszero(lt(results, guard)) { break }
			}

			return(0x00, add(res, 0x40))
		}
	}
}
