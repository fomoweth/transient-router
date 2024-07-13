// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAggregator {
	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	function getRoundData(
		uint80 rid
	)
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	function latestRoundData()
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	function latestAnswer() external view returns (int256 answer);

	function latestTimestamp() external view returns (uint256 timestamp);

	function latestRound() external view returns (uint256 roundId);

	function getAnswer(uint256 roundId) external view returns (int256 answer);

	function getTimestamp(uint256 roundId) external view returns (uint256 timestamp);
}
