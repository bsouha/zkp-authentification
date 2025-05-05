// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMedicalCase {
    enum CaseStatus { CREATED, ASSIGNED, CLOSED }
    enum UrgencyLevel { LOW, MEDIUM, HIGH }

    struct CaseData {
        address patient;
        address doctor;
        uint32 specialtyRequired;
        uint40 createdAt;
        uint40 expiresAt;
        UrgencyLevel urgency;
        CaseStatus status;
        bytes32 ipfsHash;
        bytes32 consentProof;
    }

    event CaseCreated(uint256 indexed caseId, address indexed patient);
    event CaseAssigned(uint256 indexed caseId, address indexed expert);
    event CaseClosed(uint256 indexed caseId, bytes32 finalDiagnosisHash);

    function createCase(
        bytes32 ipfsHash,
        bytes32 consentProof,
        uint32 specialty,
        UrgencyLevel urgency
    ) external returns (uint256);

    function assignExpert(uint256 caseId, address expert) external;
    function submitDiagnosis(uint256 caseId, bytes32 diagnosisHash) external;
    function closeCase(uint256 caseId) external;
    function getCase(uint256 caseId) external view returns (CaseData memory);
    function verifyConsent(bytes32 proof) external view returns (bool);
}