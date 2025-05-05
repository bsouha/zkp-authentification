// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IConsultation {
    struct Diagnosis {
        bytes32 ipfsHash;
        uint40 submittedAt;
        address submittedBy;
    }

    event ExpertAssigned(uint256 indexed caseId, uint256 indexed expertId);
    event DiagnosisSubmitted(uint256 indexed caseId, address indexed by);

    function assignExpert(
        uint256 caseId,
        uint256 expertId,
        uint256 minReputation
    ) external;

    function submitDiagnosis(
        uint256 caseId,
        bytes32 diagnosisHash,
        bytes32 zkpProof
    ) external;

    function getDiagnosisHistory(uint256 caseId) external view returns (Diagnosis[] memory);
}