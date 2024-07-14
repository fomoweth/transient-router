// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {CommonBase} from "forge-std/Base.sol";
import {SwapRouter, ImmutableState} from "src/SwapRouter.sol";
import {Create3} from "src/libraries/Create3.sol";
import {Constants} from "./Constants.sol";

abstract contract Deployer is CommonBase, Constants {
	SwapRouter router;

	function deployRouter() internal {
		ImmutableState memory params = ImmutableState({
			weth9: WETH,
			v3Factory: UNISWAP_V3_FACTORY,
			poolInitCodeHash: UNISWAP_V3_POOL_INIT_CODE_HASH,
			v2Factory: UNISWAP_V2_FACTORY,
			pairInitCodeHash: UNISWAP_V2_PAIR_INIT_CODE_HASH
		});

		bytes32 id = "SwapRouterV1";
		bytes32 salt = encodeSalt(id, address(this));

		bytes memory creationCode = type(SwapRouter).creationCode;
		bytes memory bytecode = abi.encodePacked(creationCode, abi.encode(params));

		router = SwapRouter(payable(create3("SwapRouter", salt, bytecode)));
	}

	function create3(string memory label, bytes32 salt, bytes memory creationCode) internal returns (address deployed) {
		vm.label((deployed = Create3.create3(salt, creationCode)), label);
	}

	function encodeSalt(bytes32 salt, address deployer) private pure returns (bytes32) {
		return keccak256(abi.encodePacked(deployer, salt));
	}
}
