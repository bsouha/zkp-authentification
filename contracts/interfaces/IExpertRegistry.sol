// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IExpertRegistry {
    struct Expert {
        uint32 specialty;
        uint40 registrationDate;
        uint40 lastActivity;
        bool isActive;
        uint256 reputationScore;
    }

    event ExpertRegistered(uint256 indexed expertId, address indexed wallet);
    event ExpertStatusChanged(uint256 indexed expertId, bool newStatus);
    event SpecialtyUpdated(uint256 indexed expertId, uint32 newSpecialty);

    function registerExpert(address wallet, uint32 specialty) external returns (uint256);
    function updateSpecialty(uint256 expertId, uint32 newSpecialty) external;
    function setExpertStatus(uint256 expertId, bool active) external;
    function getExpert(uint256 expertId) external view returns (Expert memory);
    function getExpertsBySpecialty(uint32 specialty) external view returns (uint256[] memory);
    function isActiveExpert(uint256 expertId) external view returns (bool);
}