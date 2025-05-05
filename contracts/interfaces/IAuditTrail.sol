// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAuditTrail {
    enum EventType {
        CASE_CREATED,
        EXPERT_ASSIGNED,
        DIAGNOSIS_SUBMITTED,
        DATA_ACCESSED
    }

    struct AuditEntry {
        address actor;
        EventType eventType;
        uint40 timestamp;
        bytes32 dataReference;
    }

    event NewAuditEntry(uint256 indexed entryId, EventType eventType, address indexed actor);

    function logEvent(
        EventType eventType,
        address actor,
        bytes32 dataReference
    ) external returns (uint256);

    function getAuditLog(uint256 entryId) external view returns (AuditEntry memory);
    function getAuditLogsByActor(address actor) external view returns (uint256[] memory);
}