// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title Math
/// @notice Provides functions to handle unsigned math operations

library Math {
	uint256 internal constant WAD = 1e18;
	uint256 internal constant HALF_WAD = 0.5e18;

	function abs(int256 x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(sar(255, x), add(sar(255, x), x))
		}
	}

	function ternary(bool condition, uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(y, mul(xor(x, y), iszero(iszero(condition))))
		}
	}

	function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, y), gt(y, x)))
		}
	}

	function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, y), lt(y, x)))
		}
	}

	function derive(
		uint256 base,
		uint256 quote,
		uint8 baseDecimals,
		uint8 quoteDecimals,
		uint8 decimals
	) internal pure returns (uint256 derived) {
		unchecked {
			if (base != 0 && quote != 0) {
				derived = mulDiv(
					scale(base, baseDecimals, decimals),
					10 ** decimals,
					scale(quote, quoteDecimals, decimals)
				);
			}
		}
	}

	function inverse(uint256 answer, uint8 baseDecimals, uint8 quoteDecimals) internal pure returns (uint256 inversed) {
		assembly ("memory-safe") {
			if iszero(iszero(answer)) {
				inversed := div(exp(10, add(baseDecimals, quoteDecimals)), answer)
			}
		}
	}

	function scale(uint256 answer, uint8 baseDecimals, uint8 quoteDecimals) internal pure returns (uint256 scaled) {
		assembly ("memory-safe") {
			function ternary(condition, a, b) -> c {
				c := xor(b, mul(xor(a, b), iszero(iszero(condition))))
			}

			scaled := ternary(
				and(iszero(iszero(answer)), xor(baseDecimals, quoteDecimals)),
				ternary(
					lt(baseDecimals, quoteDecimals),
					mul(answer, exp(10, sub(quoteDecimals, baseDecimals))),
					div(answer, exp(10, sub(baseDecimals, quoteDecimals)))
				),
				answer
			)
		}
	}

	function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := add(div(x, y), gt(mod(x, y), 0))
		}
	}

	function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			let mm := mulmod(x, y, not(0))
			let p0 := mul(x, y)
			let p1 := sub(sub(mm, p0), lt(mm, p0))

			if iszero(gt(d, p1)) {
				invalid()
			}

			switch iszero(p1)
			case 0x00 {
				let r := mulmod(x, y, d)
				p1 := sub(p1, gt(r, p0))
				p0 := sub(p0, r)

				let t := and(d, sub(0, d))
				d := div(d, t)

				let inv := xor(2, mul(3, d))

				inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
				inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
				inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
				inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
				inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
				inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**256

				z := mul(or(mul(p1, add(div(sub(0, t), t), 1)), div(p0, t)), inv)
			}
			default {
				z := div(p0, d)
			}
		}
	}

	function mulDivRoundingUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
		z = mulDiv(x, y, d);

		assembly ("memory-safe") {
			if mulmod(x, y, d) {
				if iszero(lt(z, sub(shl(256, 1), 1))) {
					invalid()
				}

				z := add(z, 1)
			}
		}
	}

	function wadDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if or(iszero(y), iszero(iszero(gt(x, div(sub(not(0), div(y, 2)), WAD))))) {
				invalid()
			}

			z := div(add(mul(x, WAD), div(y, 2)), y)
		}
	}

	function wadMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if iszero(or(iszero(y), iszero(gt(x, div(sub(not(0), HALF_WAD), y))))) {
				invalid()
			}

			z := div(add(mul(x, y), HALF_WAD), WAD)
		}
	}
}
