// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {StdAssertions} from "forge-std/StdAssertions.sol";
import {Math} from "src/libraries/Math.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";
import {Currency} from "src/types/Currency.sol";

abstract contract Assertion is StdAssertions {
	using PercentageMath for uint256;

	function assertZero(uint256 value) internal pure {
		assertTrue(value == 0);
	}

	function assertZero(uint256 value, string memory err) internal pure {
		assertTrue(value == 0, err);
	}

	function assertNotZero(uint256 value) internal pure {
		assertTrue(value != 0);
	}

	function assertNotZero(uint256 value, string memory err) internal pure {
		assertTrue(value != 0, err);
	}

	function assertEq(Currency result, Currency expected) internal pure {
		assertEq(Currency.unwrap(result), Currency.unwrap(expected));
	}

	function assertEq(Currency result, Currency expected, string memory err) internal pure {
		assertEq(Currency.unwrap(result), Currency.unwrap(expected), err);
	}

	function assertEq(Currency[] memory result, Currency[] memory expected) internal pure {
		assertEq(result, expected, "");
	}

	function assertEq(Currency[] memory result, Currency[] memory expected, string memory err) internal pure {
		address[] memory unwrappedResult;
		address[] memory unwrappedExpected;

		assembly ("memory-safe") {
			unwrappedResult := result
			unwrappedExpected := expected
		}

		assertEq(unwrappedResult, unwrappedExpected, err);
	}

	function assertCloseTo(uint256 result, uint256 expected) internal pure {
		assertCloseTo(result, expected, 100);
	}

	function assertCloseTo(uint256 result, uint256 expected, string memory err) internal pure {
		assertCloseTo(result, expected, 100, err);
	}

	function assertCloseTo(uint256 result, uint256 expected, uint256 percentage) internal pure {
		assertTrue(closeTo(result, expected, percentage));
	}

	function assertCloseTo(uint256 result, uint256 expected, uint256 percentage, string memory err) internal pure {
		assertTrue(closeTo(result, expected, percentage), err);
	}

	function closeTo(uint256 x, uint256 y, uint256 percentage) private pure returns (bool) {
		if (x != y) {
			uint256 precision = x.percentMul(percentage);
			uint256 delta = Math.abs(int256(x) - int256(y));

			return precision >= delta;
		}

		return true;
	}
}
