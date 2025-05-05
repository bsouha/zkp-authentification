// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IAuditTrail.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AuditTrail is IAuditTrail, AccessControl {
    bytes32 public constant LOGGER_ROLE = keccak256("LOGGER_ROLE");

    mapping(uint256 => AuditEntry) private _auditLogs;
    mapping(address => uint256[]) private _actorLogs;
    uint256 private _nextEntryId = 1;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function logEvent(
        EventType eventType,
        address actor,
        bytes32 dataReference
    ) external onlyRole(LOGGER_ROLE) returns (uint256) {
        uint256 entryId = _nextEntryId++;
        _auditLogs[entryId] = AuditEntry({
            actor: actor,
            eventType: eventType,
            timestamp: uint40(block.timestamp),
            dataReference: dataReference
        });
        _actorLogs[actor].push(entryId);
        emit NewAuditEntry(entryId, eventType, actor);
        return entryId;
    }

    // ====================== VIEW FUNCTIONS ======================
    function getAuditLog(uint256 entryId) public view returns (AuditEntry memory) {
        return _auditLogs[entryId];
    }

    function getAuditLogsByActor(address actor) public view returns (uint256[] memory) {
        return _actorLogs[actor];
    }

    function getTotalLogs() public view returns (uint256) {
        return _nextEntryId - 1;
    }
}