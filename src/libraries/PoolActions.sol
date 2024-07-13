// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title PoolActions
/// @notice Provides functions for invoking Uniswap V2 & V3 pool actions

library PoolActions {
	function swap(
		address pool,
		address recipient,
		bool zeroForOne,
		int256 amountSpecified,
		uint160 sqrtPriceLimitX96,
		bytes calldata data
	) internal returns (int256 amount0Delta, int256 amount1Delta) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x128acb0800000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), recipient)
			mstore(add(ptr, 0x24), zeroForOne)
			mstore(add(ptr, 0x44), amountSpecified)
			mstore(add(ptr, 0x64), sqrtPriceLimitX96)
			mstore(add(ptr, 0x84), 0xa0)
			mstore(add(ptr, 0xa4), data.length)
			calldatacopy(add(ptr, 0xc4), data.offset, data.length)

			if iszero(call(gas(), pool, 0x00, ptr, add(0xc4, data.length), 0x00, 0x40)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			amount0Delta := mload(0x00)
			amount1Delta := mload(0x20)
		}
	}

	function swap(address pair, bool zeroForOne, uint256 amountOut, address recipient, bytes calldata data) internal {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x022c0d9f00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), mul(iszero(zeroForOne), amountOut))
			mstore(add(ptr, 0x24), mul(iszero(iszero(zeroForOne)), amountOut))
			mstore(add(ptr, 0x44), recipient)
			mstore(add(ptr, 0x64), 0x80)
			mstore(add(ptr, 0x84), data.length)
			calldatacopy(add(ptr, 0xa4), data.offset, data.length)

			if iszero(call(gas(), pair, 0x00, ptr, add(0xa4, data.length), 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}
		}
	}
}
