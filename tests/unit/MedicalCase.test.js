const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MedicalCase (Unit Tests)", function () {
  let medicalCase, registry, expertRegistry;
  let admin, patient, doctor;
  const CARDIOLOGY = 1;
  const HIGH_URGENCY = 2;

  before(async function () {
    [admin, patient, doctor] = await ethers.getSigners();
    
    // Mock registry
    const Registry = await ethers.getContractFactory("ZKPIdentityRegistry");
    registry = await Registry.deploy(ethers.constants.AddressZero);
    
    // Mock expert registry
    const ExpertRegistry = await ethers.getContractFactory("ExpertRegistry");
    expertRegistry = await ExpertRegistry.deploy();
    
    // Deploy MedicalCase
    const MedicalCase = await ethers.getContractFactory("MedicalCase");
    medicalCase = await MedicalCase.deploy(registry.address, expertRegistry.address);
  });

  describe("createCase()", function () {
    it("Should create a new medical case", async function () {
      await expect(
        medicalCase.connect(patient).createCase(
          ethers.utils.formatBytes32String("ipfsHash123"),
          ethers.utils.formatBytes32String("consentProof"),
          CARDIOLOGY,
          HIGH_URGENCY
        )
      )
        .to.emit(medicalCase, "CaseCreated")
        .withArgs(1, patient.address);
    });

    it("Should reject non-patients", async function () {
      await expect(
        medicalCase.connect(doctor).createCase(
          ethers.utils.formatBytes32String("ipfsHash123"),
          ethers.utils.formatBytes32String("consentProof"),
          CARDIOLOGY,
          HIGH_URGENCY
        )
      ).to.be.revertedWith("Not a patient");
    });
  });

  describe("assignExpert()", function () {
    beforeEach(async function () {
      await medicalCase.connect(patient).createCase(
        ethers.utils.formatBytes32String("ipfsHash123"),
        ethers.utils.formatBytes32String("consentProof"),
        CARDIOLOGY,
        HIGH_URGENCY
      );
    });

    it("Should assign an expert to a case", async function () {
      // Register expert first
      await expertRegistry.registerExpert(doctor.address, CARDIOLOGY);
      
      await expect(
        medicalCase.connect(doctor).assignExpert(1, doctor.address)
      )
        .to.emit(medicalCase, "CaseAssigned")
        .withArgs(1, doctor.address);
    });
  });
});