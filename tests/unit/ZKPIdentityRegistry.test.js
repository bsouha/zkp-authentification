const { expect } = require("chai");
const { ethers } = require("hardhat");
const { groth16 } = require("snarkjs");
const { buildPoseidon } = require("circomlibjs");

describe("ZKPIdentityRegistry (Unit Tests)", function () {
  let registry, verifier;
  let admin, patient, doctor;
  const PATIENT_ROLE = 1;
  const DOCTOR_ROLE = 2;

  // Test ZKP inputs
  const secret = "123456";
  const nullifier = "789012";
  let poseidon;

  before(async function () {
    [admin, patient, doctor] = await ethers.getSigners();
    
    // Initialize Poseidon hash
    poseidon = await buildPoseidon();

    // Deploy Verifier
    const Verifier = await ethers.getContractFactory("Groth16Verifier");
    verifier = await Verifier.deploy();

    // Deploy Registry
    const Registry = await ethers.getContractFactory("ZKPIdentityRegistry");
    registry = await Registry.deploy(verifier.address);
  });

  // Helper function to generate mock proof
  async function generateMockProof(role) {
    const hash = poseidon.F.toString(poseidon([role, secret, nullifier]));
    return {
      a: [ethers.BigNumber.from("0x123"), ethers.BigNumber.from("0x456")],
      b: [
        [ethers.BigNumber.from("0x789"), ethers.BigNumber.from("0xabc")],
        [ethers.BigNumber.from("0xdef"), ethers.BigNumber.from("0x101")]
      ],
      c: [ethers.BigNumber.from("0x112"), ethers.BigNumber.from("0x131")],
      input: [role, hash]
    };
  }

  describe("register()", function () {
    it("Should register a patient with valid proof", async function () {
      const { a, b, c, input } = await generateMockProof(PATIENT_ROLE);
      
      await expect(
        registry.connect(patient).register(
          a, b, c, input,
          ethers.utils.keccak256(ethers.utils.toUtf8Bytes(nullifier)),
          "0x"
        )
      ).to.emit(registry, "RoleRegistered");
    });

    it("Should reject invalid role codes", async function () {
      const { a, b, c, input } = await generateMockProof(99); // Invalid role
      
      await expect(
        registry.connect(patient).register(
          a, b, c, input,
          ethers.utils.keccak256(ethers.utils.toUtf8Bytes("different-nullifier")),
          "0x"
        )
      ).to.be.revertedWith("Invalid role");
    });

    it("Should prevent nullifier reuse", async function () {
      const { a, b, c, input } = await generateMockProof(PATIENT_ROLE);
      const nullifierHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(nullifier));
      
      // First registration (should succeed)
      await registry.connect(patient).register(a, b, c, input, nullifierHash, "0x");
      
      // Attempt reuse (should fail)
      await expect(
        registry.connect(doctor).register(a, b, c, input, nullifierHash, "0x")
      ).to.be.revertedWith("Nullifier reused");
    });
  });

  describe("hasRole()", function () {
    it("Should correctly verify patient role", async function () {
      const { a, b, c, input } = await generateMockProof(PATIENT_ROLE);
      await registry.connect(patient).register(
        a, b, c, input,
        ethers.utils.keccak256(ethers.utils.toUtf8Bytes("new-nullifier")),
        "0x"
      );
      
      expect(await registry.hasRole(patient.address, PATIENT_ROLE)).to.be.true;
      expect(await registry.hasRole(patient.address, DOCTOR_ROLE)).to.be.false;
    });
  });
});