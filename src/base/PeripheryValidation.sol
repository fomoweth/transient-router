// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Reverter} from "src/libraries/Reverter.sol";

/// @title PeripheryValidation
/// @dev Modified from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/PeripheryValidation.sol

abstract contract PeripheryValidation {
	modifier checkDeadline(uint256 deadline) {
		_checkDeadline(deadline);
		_;
	}

	function _checkDeadline(uint256 deadline) private view {
		required(_blockTimestamp() <= deadline, 0x1ab7da6b); // DeadlineExpired()
	}

	function _blockTimestamp() internal view returns (uint48 bts) {
		assembly ("memory-safe") {
			bts := timestamp()
		}
	}

	function required(bool condition, bytes4 exception, address value) internal pure virtual {
		if (!condition) Reverter.revertWith(exception, value);
	}

	function required(bool condition, bytes4 exception, bytes32 value) internal pure virtual {
		if (!condition) Reverter.revertWith(exception, value);
	}

	function required(bool condition, bytes4 exception, uint256 value) internal pure virtual {
		if (!condition) Reverter.revertWith(exception, value);
	}

	function required(bool condition, bytes4 exception) internal pure virtual {
		if (!condition) Reverter.revertWith(exception);
	}
}
