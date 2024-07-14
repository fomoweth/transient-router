# Transient-Router

The Transient Router is an enhanced swap router designed for Uniswap V2 and V3 protocols, utilizing transient storage opcodes `TSTORE` and `TLOAD` to optimize gas efficiency during swap operations.

## Contract Overview

#### [TransientState.sol](https://github.com/fomoweth/transient-router/blob/main/src/libraries/TransientState.sol)

Provides functions for reading and writing of data in bytes32 format to specific storage slots.

```solidity
library TransientState {
	function cache(bytes32 slot, bytes32 value) internal {
		assembly ("memory-safe") {
			tstore(slot, value)
		}
	}

	function clear(bytes32 slot) internal {
		assembly ("memory-safe") {
			if iszero(iszero(tload(slot))) {
				tstore(slot, 0x00)
			}
		}
	}

	function read(bytes32 slot) internal view returns (bytes32 value) {
		assembly ("memory-safe") {
			value := tload(slot)
		}
	}

	function isEmpty(bytes32 slot) internal view returns (bool b) {
		assembly ("memory-safe") {
			b := iszero(tload(slot))
		}
	}

	function derive(bytes32 slot, bytes32 key) internal pure returns (bytes32 derivedSlot) {
		assembly ("memory-safe") {
			mstore(0x00, key)
			mstore(0x20, slot)
			derivedSlot := keccak256(0x00, 0x40)
		}
	}
}
```

### Usage in V3 Routing

- Caching Payer Address: The address of the `payer` can be cached in transient storage, avoiding repeated retrieval from call data.
- Optimizing Amount Inputs: `amountIn` or `amountInMax` values can be cached in transient storage instead of maintaining them as state variables.
- Callback Validation: The address of the `pool` and the function `signature` of the callback are cached in transient storage for validation purposes.

#### [Routing.sol](https://github.com/fomoweth/transient-router/blob/main/src/Routing.sol)

```solidity
function cachePayer(address payer) internal {
	required(payer != address(0), INVALID_PAYER_ERROR);
	PAYER_CACHED_SLOT.cache(payer.asBytes32());
}

function clearPayerCached() internal {
	required(!PAYER_CACHED_SLOT.isEmpty(), SLOT_EMPTY_ERROR);
	PAYER_CACHED_SLOT.clear();
}

function payerCached() internal view returns (address payer) {
	return PAYER_CACHED_SLOT.read().asAddress();
}

function cacheAmountIn(uint256 amountIn) internal {
	AMOUNT_IN_CACHED_SLOT.cache(amountIn.asBytes32());
}

function clearAmountInCached() internal {
	required(!AMOUNT_IN_CACHED_SLOT.isEmpty(), SLOT_EMPTY_ERROR);
	AMOUNT_IN_CACHED_SLOT.clear();
}

function amountInCached() internal view returns (uint256 amountIn) {
	return AMOUNT_IN_CACHED_SLOT.read().asUint256();
}
```

#### [CallbackValidation.sol](https://github.com/fomoweth/transient-router/blob/main/src/libraries/CallbackValidation.sol)

Provides validation for callbacks executed to this contract

```solidity
function setCallback(address expectedCaller, bytes4 expectedSig) internal {
	assembly ("memory-safe") {
		// verify that the slot is empty
		if iszero(iszero(tload(SLOT))) {
			mstore(0x00, 0x55b9fb08) // SlotNotEmpty()
			revert(0x1c, 0x04)
		}

		// verify that the expected caller is not zero
		if iszero(expectedCaller) {
			mstore(0x00, 0x48f5c3ed) // InvalidCaller()
			revert(0x1c, 0x04)
		}

		// verify that the expected signature is not zero
		if iszero(expectedSig) {
			mstore(0x00, 0x8baa579f) // InvalidSignature()
			revert(0x1c, 0x04)
		}

		// store the expected caller and signature in the slot
		tstore(SLOT, add(expectedSig, expectedCaller))
	}
}

function verifyCallback() internal {
	assembly ("memory-safe") {
		function format(data, offset, direction) -> ret {
			switch direction
			case 0x00 {
				ret := shl(offset, shr(offset, data))
			}
			default {
				ret := shr(offset, shl(offset, data))
			}
		}

		let cached := tload(SLOT)

		// verify that the slot is not empty
		if iszero(cached) {
			mstore(0x00, 0xce174065) // SlotEmpty()
			revert(0x1c, 0x04)
		}

		// verify that the caller is equal to the expected caller
		if xor(caller(), format(cached, 0x60, 0x01)) {
			mstore(0x00, 0x48f5c3ed) // InvalidCaller()
			revert(0x1c, 0x04)
		}

		// verify that the signature is equal to the expected signature
		if xor(format(calldataload(0x00), 0xe0, 0x00), format(cached, 0xe0, 0x00)) {
			mstore(0x00, 0x8baa579f) // InvalidSignature()
			revert(0x1c, 0x04)
		}

		// clear the slot
		tstore(SLOT, 0x00)
	}
}
```

### Callback Setup and Validation

Before executing a swap, the expected function signature of the callback and the calling pool's address are stored in a slot. After the callback executes, its state is decoded, validated against msg.sender and msg.sig, and the slot is cleared.

#### [V3SwapRouter.sol](https://github.com/fomoweth/transient-router/blob/main/src/V3SwapRouter.sol)

```solidity
function v3Swap(
	bool isExactInput,
	int256 amountSpecified,
	address recipient,
	bytes calldata path
) private returns (int256 amount0Delta, int256 amount1Delta, bool zeroForOne) {
	(Currency currencyIn, Currency currencyOut, uint24 fee) = path.decodeFirstPool();

	address pool = getPool(currencyIn, currencyOut, fee);

	CallbackValidation.setCallback(pool, UNISWAP_V3_SWAP_CALLBACK_SELECTOR);

	(amount0Delta, amount1Delta) = pool.swap(
		recipient,
		(zeroForOne = isExactInput ? currencyIn < currencyOut : currencyOut < currencyIn),
		amountSpecified,
		(zeroForOne ? MIN_SQRT_PRICE_LIMIT : MAX_SQRT_PRICE_LIMIT),
		path
	);
}

function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata path) external {
	required(amount0Delta > 0 || amount1Delta > 0, INVALID_SWAP_ERROR);

	CallbackValidation.verifyCallback();

	(Currency currencyIn, Currency currencyOut, ) = path.decodeFirstPool();

	(bool isExactInput, uint256 amountToPay) = amount0Delta > 0
		? (currencyIn < currencyOut, uint256(amount0Delta))
		: (currencyOut < currencyIn, uint256(amount1Delta));

	if (isExactInput) {
		pay(currencyIn, payerCached(), msg.sender, amountToPay);
	} else {
		if (path.hasMultiplePools()) {
			v3Swap(false, -amountToPay.toInt256(), msg.sender, path.skipCurrency());
		} else {
			uint256 amountInMaxCached = amountInCached();
			required(amountInMaxCached >= amountToPay, INSUFFICIENT_AMOUNT_IN_ERROR);

			pay(currencyOut, payerCached(), msg.sender, amountToPay);

			cacheAmountIn(amountToPay);
		}
	}
}
```

## Usage

Create `.env` file with the following content:

```text
INFURA_API_KEY="YOUR_INFURA_API_KEY"
RPC_ETHEREUM="https://mainnet.infura.io/v3/${INFURA_API_KEY}"

ETHERSCAN_API_KEY_ETHEREUM="YOUR_ETHERSCAN_API_KEY"
ETHERSCAN_URL_ETHEREUM="https://api.etherscan.io/api"

# Optional

FORK_BLOCK_ETHEREUM=20247317
```

**The test environment will be forked at the latest block if `FORK_BLOCK_ETHEREUM` is not defined.**

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```
