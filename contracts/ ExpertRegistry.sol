// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IExpertRegistry.sol";
import "./interfaces/IReputationSystem.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ExpertRegistry is IExpertRegistry, AccessControl {
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    
    IReputationSystem public immutable reputationSystem;

    mapping(uint256 => Expert) private _experts;
    mapping(uint32 => uint256[]) private _specialtyExperts;
    mapping(address => uint256) private _walletToExpertId;
    uint256 private _nextExpertId = 1;

    constructor(address reputationSystemAddress) {
        reputationSystem = IReputationSystem(reputationSystemAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function registerExpert(address wallet, uint32 specialty) 
        external 
        onlyRole(GOVERNANCE_ROLE)
        returns (uint256) 
    {
        require(_walletToExpertId[wallet] == 0, "Expert already registered");
        
        uint256 expertId = _nextExpertId++;
        _experts[expertId] = Expert({
            specialty: specialty,
            registrationDate: uint40(block.timestamp),
            lastActivity: uint40(block.timestamp),
            isActive: true,
            reputationScore: 1000 // Initial score
        });
        
        _specialtyExperts[specialty].push(expertId);
        _walletToExpertId[wallet] = expertId;

        emit ExpertRegistered(expertId, wallet);
        return expertId;
    }

    function updateSpecialty(uint256 expertId, uint32 newSpecialty) 
        external 
        onlyRole(GOVERNANCE_ROLE) 
    {
        require(_experts[expertId].registrationDate > 0, "Invalid expert ID");
        
        // Remove from old specialty list
        uint32 oldSpecialty = _experts[expertId].specialty;
        uint256[] storage oldList = _specialtyExperts[oldSpecialty];
        for (uint256 i = 0; i < oldList.length; i++) {
            if (oldList[i] == expertId) {
                oldList[i] = oldList[oldList.length - 1];
                oldList.pop();
                break;
            }
        }
        
        // Add to new specialty
        _experts[expertId].specialty = newSpecialty;
        _specialtyExperts[newSpecialty].push(expertId);
        
        emit SpecialtyUpdated(expertId, newSpecialty);
    }

    function setExpertStatus(uint256 expertId, bool active) 
        external 
        onlyRole(GOVERNANCE_ROLE) 
    {
        require(_experts[expertId].registrationDate > 0, "Invalid expert ID");
        _experts[expertId].isActive = active;
        emit ExpertStatusChanged(expertId, active);
    }

    function recordActivity(uint256 expertId) external {
        require(msg.sender == address(reputationSystem), "Unauthorized");
        _experts[expertId].lastActivity = uint40(block.timestamp);
    }

    // View functions
    function getExpert(uint256 expertId) public view returns (Expert memory) {
        return _experts[expertId];
    }

    function getExpertsBySpecialty(uint32 specialty) public view returns (uint256[] memory) {
        return _specialtyExperts[specialty];
    }

    function isActiveExpert(uint256 expertId) public view returns (bool) {
        return _experts[expertId].isActive && 
               _experts[expertId].registrationDate > 0;
    }

    function getExpertId(address wallet) public view returns (uint256) {
        return _walletToExpertId[wallet];
    }
}