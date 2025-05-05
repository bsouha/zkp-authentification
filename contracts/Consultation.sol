// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IConsultation.sol";
import "./interfaces/IMedicalCase.sol";
import "./interfaces/IReputationSystem.sol";
import "./interfaces/IZKPIdentityRegistry.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Consultation is IConsultation, AccessControl {
    bytes32 public constant CASE_CONTRACT_ROLE = keccak256("CASE_CONTRACT_ROLE");

    IMedicalCase public immutable medicalCase;
    IReputationSystem public immutable reputationSystem;
    IZKPIdentityRegistry public immutable identityRegistry;

    mapping(uint256 => Diagnosis[]) private _diagnosisHistory;
    mapping(uint256 => uint256) private _caseToExpert;

    constructor(
        address _medicalCase,
        address _reputationSystem,
        address _identityRegistry
    ) {
        medicalCase = IMedicalCase(_medicalCase);
        reputationSystem = IReputationSystem(_reputationSystem);
        identityRegistry = IZKPIdentityRegistry(_identityRegistry);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function assignExpert(
        uint256 caseId,
        uint256 expertId,
        uint256 minReputation
    ) external {
        IMedicalCase.CaseData memory caseData = medicalCase.getCase(caseId);
        require(caseData.status == IMedicalCase.CaseStatus.CREATED, "Invalid case status");
        require(identityRegistry.hasRole(msg.sender, IZKPIdentityRegistry.Role.DOCTOR), "Only doctors");

        uint256 reputation = reputationSystem.getWeightedReputation(expertId);
        require(reputation >= minReputation, "Reputation too low");

        _caseToExpert[caseId] = expertId;
        medicalCase.assignExpert(caseId, msg.sender);
        emit ExpertAssigned(caseId, expertId);
    }

    function submitDiagnosis(
        uint256 caseId,
        bytes32 diagnosisHash,
        bytes32 zkpProof
    ) external {
        IMedicalCase.CaseData memory caseData = medicalCase.getCase(caseId);
        require(caseData.status == IMedicalCase.CaseStatus.ASSIGNED, "Case not active");
        require(
            msg.sender == caseData.doctor || 
            _caseToExpert[caseId] == expertRegistry.getExpertId(msg.sender),
            "Unauthorized"
        );

        medicalCase.submitDiagnosis(caseId, diagnosisHash);
        _diagnosisHistory[caseId].push(Diagnosis({
            ipfsHash: diagnosisHash,
            submittedAt: uint40(block.timestamp),
            submittedBy: msg.sender
        }));

        // Update reputation
        int256 repChange = msg.sender == caseData.doctor ? 10 : 5;
        reputationSystem.updateReputation(
            expertRegistry.getExpertId(msg.sender),
            repChange
        );

        emit DiagnosisSubmitted(caseId, msg.sender);
    }

    function getDiagnosisHistory(uint256 caseId) public view returns (Diagnosis[] memory) {
        return _diagnosisHistory[caseId];
    }
}