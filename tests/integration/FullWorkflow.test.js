const { expect } = require("chai");
const { ethers } = require("hardhat");
const { groth16 } = require("snarkjs");
const { buildPoseidon } = require("circomlibjs");

describe("Healthcare System (End-to-End)", function () {
  // Contracts
  let verifier, registry, expertRegistry, reputation, medicalCase, consultation, ipfsStorage;

  // Roles
  let admin, patient, doctor, expert;
  
  // Test Data
  const PATIENT_ROLE = 1;
  const DOCTOR_ROLE = 2;
  const EXPERT_ROLE = 3;
  const CARDIOLOGY = 1;
  const HIGH_URGENCY = 2;

  before(async function () {
    [admin, patient, doctor, expert] = await ethers.getSigners();

    // ========== Deploy Contracts ==========
    // 1. Verifier
    const Verifier = await ethers.getContractFactory("Groth16Verifier");
    verifier = await Verifier.deploy();

    // 2. Core System
    const Registry = await ethers.getContractFactory("ZKPIdentityRegistry");
    registry = await Registry.deploy(verifier.address);

    const ExpertRegistry = await ethers.getContractFactory("ExpertRegistry");
    expertRegistry = await ExpertRegistry.deploy();

    const Reputation = await ethers.getContractFactory("ReputationSystem");
    reputation = await Reputation.deploy(expertRegistry.address);

    const MedicalCase = await ethers.getContractFactory("MedicalCase");
    medicalCase = await MedicalCase.deploy(registry.address, expertRegistry.address);

    const Consultation = await ethers.getContractFactory("Consultation");
    consultation = await Consultation.deploy(
      medicalCase.address,
      reputation.address,
      registry.address
    );

    const IPFSStorage = await ethers.getContractFactory("IPFSStorage");
    ipfsStorage = await IPFSStorage.deploy(registry.address);

    // ========== Setup Roles ==========
    // Grant GOVERNANCE_ROLE to admin
    await expertRegistry.connect(admin).grantRole(
      await expertRegistry.GOVERNANCE_ROLE(),
      admin.address
    );

    // Register expert
    await expertRegistry.connect(admin).registerExpert(expert.address, CARDIOLOGY);
  });

  it("Should complete full patient-to-diagnosis workflow", async function () {
    // ========== 1. Patient Registration ==========
    const poseidon = await buildPoseidon();
    const secret = 12345;
    const nullifier = 67890;
    const hash = poseidon.F.toString(poseidon([PATIENT_ROLE, secret, nullifier]));

    // Mock proof (replace with real proof in production)
    const proof = {
      a: [ethers.BigNumber.from("0x123"), ethers.BigNumber.from("0x456")],
      b: [
        [ethers.BigNumber.from("0x789"), ethers.BigNumber.from("0xabc")],
        [ethers.BigNumber.from("0xdef"), ethers.BigNumber.from("0x101")]
      ],
      c: [ethers.BigNumber.from("0x112"), ethers.BigNumber.from("0x131")],
      input: [PATIENT_ROLE, hash]
    };

    await registry.connect(patient).register(
      proof.a, proof.b, proof.c, 
      proof.input,
      ethers.utils.keccak256(ethers.utils.toUtf8Bytes(nullifier.toString())),
      "0x"
    );

    // ========== 2. Create Medical Case ==========
    const createTx = await medicalCase.connect(patient).createCase(
      ethers.utils.formatBytes32String("QmPatientData"),
      ethers.utils.formatBytes32String("consentProof123"),
      CARDIOLOGY,
      HIGH_URGENCY
    );

    const createReceipt = await createTx.wait();
    const caseId = createReceipt.events[0].args.caseId;

    // ========== 3. Assign Expert ==========
    const expertId = await expertRegistry.getExpertId(expert.address);
    await consultation.connect(doctor).assignExpert(
      caseId,
      expertId,
      500 // Min reputation
    );

    // ========== 4. Submit Diagnosis ==========
    const initialRep = await reputation.getReputation(expertId);
    
    await consultation.connect(expert).submitDiagnosis(
      caseId,
      ethers.utils.formatBytes32String("QmDiagnosisData"),
      ethers.utils.formatBytes32String("zkpProof456")
    );

    // ========== 5. Verify Outcomes ==========
    // Check case status
    const caseData = await medicalCase.getCase(caseId);
    expect(caseData.status).to.equal(2); // ASSIGNED -> DIAGNOSIS_SUBMITTED

    // Check reputation update
    const newRep = await reputation.getReputation(expertId);
    expect(newRep).to.be.gt(initialRep);

    // Check audit trail
    const auditLogs = await auditTrail.getAuditLogsByActor(expert.address);
    expect(auditLogs.length).to.be.gt(0);
  });

  it("Should enforce access control throughout workflow", async function () {
    // Attempt unauthorized case creation
    await expect(
      medicalCase.connect(doctor).createCase(
        ethers.utils.formatBytes32String("QmInvalid"),
        ethers.utils.formatBytes32String("badProof"),
        CARDIOLOGY,
        HIGH_URGENCY
      )
    ).to.be.revertedWith("Not a patient");
  });
});