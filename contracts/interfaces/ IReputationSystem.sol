// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IReputationSystem {
    event ReputationUpdated(uint256 indexed expertId, int256 delta);
    event ReputationDecayed(uint256 indexed expertId, uint256 newScore);

    function updateReputation(uint256 expertId, int256 delta) external;
    function slashReputation(uint256 expertId, uint256 amount) external;
    function getReputation(uint256 expertId) external view returns (uint256);
    function getWeightedReputation(uint256 expertId) external view returns (uint256);
}