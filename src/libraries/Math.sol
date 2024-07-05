// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title Math
/// @notice Provides functions to handle unsigned math operations

library Math {
	function ternary(bool condition, uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(y, mul(xor(x, y), iszero(iszero(condition))))
		}
	}

	function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := add(and(x, y), div(xor(x, y), 2))
		}
	}

	function bound(uint256 x, uint256 low, uint256 high) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, low), gt(low, x)))
			z := xor(z, mul(xor(z, high), lt(high, z)))
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

	function log2(uint256 x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if iszero(x) {
				invalid()
			}

			z := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
			z := or(z, shl(6, lt(0xffffffffffffffff, shr(z, x))))
			z := or(z, shl(5, lt(0xffffffff, shr(z, x))))

			x := shr(z, x)
			x := or(x, shr(1, x))
			x := or(x, shr(2, x))
			x := or(x, shr(4, x))
			x := or(x, shr(8, x))
			x := or(x, shr(16, x))

			z := or(
				z,
				byte(
					shr(251, mul(x, shl(224, 0x07c4acdd))),
					0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f
				)
			)
		}
	}

	function log10(uint256 x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if iszero(lt(x, exp(10, 64))) {
				x := div(x, exp(10, 64))
				z := add(z, 64)
			}

			if iszero(lt(x, exp(10, 32))) {
				x := div(x, exp(10, 32))
				z := add(z, 32)
			}

			if iszero(lt(x, exp(10, 16))) {
				x := div(x, exp(10, 16))
				z := add(z, 16)
			}

			if iszero(lt(x, exp(10, 8))) {
				x := div(x, exp(10, 8))
				z := add(z, 8)
			}

			if iszero(lt(x, exp(10, 4))) {
				x := div(x, exp(10, 4))
				z := add(z, 4)
			}

			if iszero(lt(x, exp(10, 2))) {
				x := div(x, exp(10, 2))
				z := add(z, 2)
			}

			if iszero(lt(x, 10)) {
				z := add(z, 1)
			}
		}
	}

	function rpow(uint256 x, uint256 y, uint256 b) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			switch x
			case 0 {
				z := mul(b, iszero(y))
			}
			default {
				z := xor(b, mul(xor(b, x), and(y, 1)))
				let half := shr(1, b)

				// prettier-ignore
				for { y := shr(1, y) } y { y := shr(1, y) } {
					let xx := mul(x, x)
					let xxRound := add(xx, half)

					if or(lt(xxRound, xx), shr(128, x)) {
						mstore(0x00, 0x35278d12) // Overflow()
						revert(0x1c, 0x04)
					}

					x := div(xxRound, b)

					if and(y, 1) {
						let zx := mul(z, x)
						let zxRound := add(zx, half)

						if or(xor(div(zx, x), z), lt(zxRound, zx)) {
							if iszero(iszero(x)) {
								mstore(0x00, 0x35278d12) // Overflow()
								revert(0x1c, 0x04)
							}
						}

						z := div(zxRound, b)
					}
				}
			}
		}
	}

	function sqrt(uint256 x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := 181

			let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
			r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
			r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
			r := or(r, shl(4, lt(0xffffff, shr(r, x))))
			z := shl(shr(1, r), z)

			z := shr(18, mul(z, add(shr(r, x), 65536)))

			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))

			z := sub(z, lt(div(x, z), z))
		}
	}
}
