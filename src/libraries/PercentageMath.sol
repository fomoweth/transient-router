// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title PercentageMath
/// @dev Implementation from https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/math/PercentageMath.sol

library PercentageMath {
	uint256 internal constant PERCENTAGE_FACTOR = 10000;
	uint256 internal constant HALF_PERCENTAGE_FACTOR = 5000;

	function percentMul(uint256 x, uint256 percentage) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if iszero(or(iszero(percentage), iszero(gt(x, div(sub(not(0), HALF_PERCENTAGE_FACTOR), percentage))))) {
				invalid()
			}

			z := div(add(mul(x, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
		}
	}

	function percentDiv(uint256 x, uint256 percentage) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if or(iszero(percentage), iszero(iszero(gt(x, div(sub(not(0), div(percentage, 2)), PERCENTAGE_FACTOR))))) {
				invalid()
			}

			z := div(add(mul(x, PERCENTAGE_FACTOR), div(percentage, 2)), percentage)
		}
	}
}
