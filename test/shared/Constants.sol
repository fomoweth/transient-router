// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IFeedRegistry} from "src/interfaces/external/ChainLink/IFeedRegistry.sol";
import {Currency} from "src/types/Currency.sol";

abstract contract Constants {
	uint256 constant MAX_UINT256 = (1 << 256) - 1;

	uint256 constant DEADLINE = (1 << 48) - 1;

	// Uniswap Constants

	bytes32 constant UNISWAP_V2_PAIR_INIT_CODE_HASH =
		0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;

	address constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

	address constant AAVE_ETH_V2 = 0xDFC14d2Af169B0D36C4EFF567Ada9b2E0CAE044f;
	address constant DAI_ETH_V2 = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;
	address constant DAI_MKR_V2 = 0x517F9dD285e75b599234F7221227339478d0FcC8;
	address constant MKR_ETH_V2 = 0xC2aDdA861F89bBB333c90c492cB837741916A225;
	address constant UNI_ETH_V2 = 0xd3d2E2692501A5c9Ca623199D38826e513033a17;

	bytes32 constant UNISWAP_V3_POOL_INIT_CODE_HASH =
		0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

	address constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

	address constant UNISWAP_V3_QUOTER = 0x5e55C9e631FAE526cd4B0526C4818D6e0a9eF0e3;

	address constant AAVE_ETH_3000 = 0x5aB53EE1d50eeF2C1DD3d5402789cd27bB52c1bB;
	address constant AAVE_COMP_10000 = 0xCEee866d0893EA3c0Cc7d1bE290D53f8B8fE2596;

	address constant COMP_ETH_3000 = 0xea4Ba4CE14fdd287f380b55419B1C5b6c3f22ab6;
	address constant COMP_ETH_10000 = 0x5598931BfBb43EEC686fa4b5b92B5152ebADC2f6;

	address constant WBTC_ETH_500 = 0x4585FE77225b41b697C938B018E2Ac67Ac5a20c0;
	address constant WBTC_ETH_3000 = 0xCBCdF9626bC03E24f779434178A73a0B4bad62eD;

	address constant USDC_ETH_500 = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
	address constant USDC_ETH_3000 = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;

	uint24 constant FEE_LOWEST = 100;
	uint24 constant FEE_LOW = 500;
	uint24 constant FEE_MEDIUM = 3000;
	uint24 constant FEE_HIGH = 10000;

	// Denominations

	address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	address constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
	address constant USD = 0x0000000000000000000000000000000000000348;

	// Currencies

	Currency constant ZERO_CURRENCY = Currency.wrap(0x0000000000000000000000000000000000000000);
	Currency constant NATIVE = Currency.wrap(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
	Currency constant WETH = Currency.wrap(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	Currency constant STETH = Currency.wrap(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
	Currency constant WSTETH = Currency.wrap(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
	Currency constant AAVE = Currency.wrap(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
	Currency constant COMP = Currency.wrap(0xc00e94Cb662C3520282E6f5717214004A7f26888);
	Currency constant DAI = Currency.wrap(0x6B175474E89094C44Da98b954EedeAC495271d0F);
	Currency constant LINK = Currency.wrap(0x514910771AF9Ca656af840dff83E8264EcF986CA);
	Currency constant MKR = Currency.wrap(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
	Currency constant UNI = Currency.wrap(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
	Currency constant USDC = Currency.wrap(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
	Currency constant USDT = Currency.wrap(0xdAC17F958D2ee523a2206206994597C13D831ec7);
	Currency constant WBTC = Currency.wrap(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

	IFeedRegistry constant FEED_REGISTRY = IFeedRegistry(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf);
}
