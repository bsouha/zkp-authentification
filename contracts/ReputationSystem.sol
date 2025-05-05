// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IExpertRegistry.sol";

/**
 * @title Medical Expert Reputation System
 * @notice Manages time-decayed reputation scores with anti-Sybil protections
 * @dev Features:
 * - Time-based exponential reputation decay (1% per month)
 * - Sqrt-weighted reputation to prevent gaming
 * - Governance-controlled slashing
 * - Activity-based decay pauses
 */
contract ReputationSystem is AccessControl {
    bytes32 public constant CASE_CONTRACT_ROLE = keccak256("CASE_CONTRACT_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    IExpertRegistry public immutable expertRegistry;

    // Reputation parameters (compressed into single storage slots)
    struct ReputationParams {
        uint40 lastUpdate;      // Last activity timestamp
        uint16 decayPeriod;     // Days between decay (30)
        uint16 decayFactor;     // 99 = 1% decay (99/100)
        uint32 maxReputation;   // 10,000 points
        uint32 minReputation;   // 100 points floor
    }
    
    ReputationParams public params;
    mapping(uint256 => uint256) private _reputationScores;

    constructor(address _expertRegistry) {
        expertRegistry = IExpertRegistry(_expertRegistry);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
        params = ReputationParams({
            lastUpdate: 0,
            decayPeriod: 30 days,
            decayFactor: 99, // 1% decay
            maxReputation: 10000,
            minReputation: 100
        });
    }

    /**
     * @notice Updates reputation with decay applied
     * @param expertId Expert ID from ExpertRegistry
     * @param delta Positive/negative reputation change
     * @dev Callable only by whitelisted case contracts
     */
    function updateReputation(uint256 expertId, int256 delta) 
        external 
        onlyRole(CASE_CONTRACT_ROLE) 
    {
        _applyDecay(expertId);
        uint256 currentScore = _reputationScores[expertId];
        
        if (delta > 0) {
            currentScore = _min(currentScore + uint256(delta), params.maxReputation);
        } else {
            currentScore = currentScore > uint256(-delta) 
                ? currentScore - uint256(-delta) 
                : params.minReputation;
        }
        
        _reputationScores[expertId] = currentScore;
        expertRegistry.recordActivity(expertId);
    }

    /**
     * @notice Governance-triggered reputation slashing
     * @param expertId Expert ID to penalize
     * @param amount Points to deduct
     */
    function slashReputation(uint256 expertId, uint256 amount) 
        external 
        onlyRole(GOVERNANCE_ROLE) 
    {
        _applyDecay(expertId);
        uint256 currentScore = _reputationScores[expertId];
        
        _reputationScores[expertId] = currentScore > amount 
            ? currentScore - amount 
            : params.minReputation;
        
        expertRegistry.recordActivity(expertId);
    }

    /**
     * @dev Applies time-based decay to reputation score
     */
    function _applyDecay(uint256 expertId) internal {
        (uint256 score, uint256 lastUpdate) = _getExpertData(expertId);
        if (lastUpdate == 0) return;

        uint256 periods = (block.timestamp - lastUpdate) / params.decayPeriod;
        if (periods == 0) return;

        // Apply exponential decay: score * (decayFactor/100)^periods
        for (uint256 i = 0; i < periods; i++) {
            score = (score * params.decayFactor) / 100;
            if (score < params.minReputation) {
                score = params.minReputation;
                break;
            }
        }

        _reputationScores[expertId] = score;
        expertRegistry.recordActivity(expertId);
    }

    // ====================== VIEW FUNCTIONS ======================
    
    /**
     * @notice Gets raw reputation score with decay calculated
     */
    function getReputation(uint256 expertId) public view returns (uint256) {
        (uint256 score, uint256 lastUpdate) = _getExpertData(expertId);
        if (lastUpdate == 0) return 0;

        uint256 periods = (block.timestamp - lastUpdate) / params.decayPeriod;
        for (uint256 i = 0; i < periods; i++) {
            score = (score * params.decayFactor) / 100;
            if (score < params.minReputation) return params.minReputation;
        }
        return score;
    }

    /**
     * @notice Gets sqrt-weighted reputation to prevent linear gaming
     * @return Weighted score scaled by 1e18 for precision
     */
    function getWeightedReputation(uint256 expertId) public view returns (uint256) {
        uint256 score = getReputation(expertId);
        return _sqrt(score * 1e18);
    }

    // ====================== INTERNAL HELPERS ======================
    
    function _getExpertData(uint256 expertId) internal view returns (uint256 score, uint256 lastUpdate) {
        IExpertRegistry.Expert memory expert = expertRegistry.getExpert(expertId);
        return (_reputationScores[expertId], expert.lastActivity);
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Babylonian square root implementation
     */
    function _sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}