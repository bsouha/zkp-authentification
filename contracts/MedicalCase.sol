// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IMedicalCase.sol";
import "./interfaces/IZKPIdentityRegistry.sol";
import "./interfaces/IExpertRegistry.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MedicalCase is IMedicalCase, AccessControl {
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");
    bytes32 public constant EXPERT_ROLE = keccak256("EXPERT_ROLE");

    IZKPIdentityRegistry public immutable identityRegistry;
    IExpertRegistry public immutable expertRegistry;
    
    mapping(uint256 => CaseData) private _cases;
    mapping(bytes32 => bool) private _usedConsentProofs;
    uint256 private _nextCaseId = 1;

    constructor(address _identityRegistry, address _expertRegistry) {
        identityRegistry = IZKPIdentityRegistry(_identityRegistry);
        expertRegistry = IExpertRegistry(_expertRegistry);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createCase(
        bytes32 ipfsHash,
        bytes32 consentProof,
        uint32 specialty,
        UrgencyLevel urgency
    ) external returns (uint256) {
        require(identityRegistry.hasRole(msg.sender, IZKPIdentityRegistry.Role.PATIENT), "Not a patient");
        require(!_usedConsentProofs[consentProof], "Consent proof reused");

        uint256 caseId = _nextCaseId++;
        uint40 expiry = _calculateExpiry(urgency);

        _cases[caseId] = CaseData({
            patient: msg.sender,
            doctor: address(0),
            specialtyRequired: specialty,
            createdAt: uint40(block.timestamp),
            expiresAt: expiry,
            urgency: urgency,
            status: CaseStatus.CREATED,
            ipfsHash: ipfsHash,
            consentProof: consentProof
        });

        _usedConsentProofs[consentProof] = true;
        emit CaseCreated(caseId, msg.sender);
        return caseId;
    }

    function assignExpert(uint256 caseId, address expert) external {
        require(_cases[caseId].status == CaseStatus.CREATED, "Invalid case status");
        require(identityRegistry.hasRole(msg.sender, IZKPIdentityRegistry.Role.DOCTOR), "Only doctors");
        
        uint256 expertId = expertRegistry.getExpertId(expert);
        require(expertRegistry.isActiveExpert(expertId), "Expert inactive");
        require(expertRegistry.getExpert(expertId).specialty == _cases[caseId].specialtyRequired, "Specialty mismatch");

        _cases[caseId].doctor = msg.sender;
        _cases[caseId].status = CaseStatus.ASSIGNED;
        emit CaseAssigned(caseId, expert);
    }

    function submitDiagnosis(uint256 caseId, bytes32 diagnosisHash) external {
        require(_cases[caseId].status == CaseStatus.ASSIGNED, "Case not assigned");
        require(msg.sender == _cases[caseId].doctor, "Only assigned doctor");
        require(block.timestamp < _cases[caseId].expiresAt, "Case expired");

        _cases[caseId].ipfsHash = diagnosisHash;
    }

    function closeCase(uint256 caseId) external {
        require(
            msg.sender == _cases[caseId].patient || 
            msg.sender == _cases[caseId].doctor,
            "Unauthorized"
        );
        require(_cases[caseId].status != CaseStatus.CLOSED, "Already closed");

        _cases[caseId].status = CaseStatus.CLOSED;
        emit CaseClosed(caseId, _cases[caseId].ipfsHash);
    }

    // ====================== VIEW FUNCTIONS ======================
    function getCase(uint256 caseId) public view returns (CaseData memory) {
        return _cases[caseId];
    }

    function verifyConsent(bytes32 proof) public view returns (bool) {
        return _usedConsentProofs[proof];
    }

    // ====================== INTERNAL HELPERS ======================
    function _calculateExpiry(UrgencyLevel urgency) internal view returns (uint40) {
        if (urgency == UrgencyLevel.HIGH) return uint40(block.timestamp + 3 days);
        if (urgency == UrgencyLevel.MEDIUM) return uint40(block.timestamp + 7 days);
        return uint40(block.timestamp + 14 days); // LOW urgency
    }
}