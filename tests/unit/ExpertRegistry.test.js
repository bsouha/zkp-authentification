const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ExpertRegistry (Unit Tests)", function () {
  let expertRegistry;
  let admin, expert1, expert2;
  const CARDIOLOGY = 1;
  const NEUROLOGY = 2;

  before(async function () {
    [admin, expert1, expert2] = await ethers.getSigners();
    
    const ExpertRegistry = await ethers.getContractFactory("ExpertRegistry");
    expertRegistry = await ExpertRegistry.deploy();
    
    // Grant governance role to admin
    const GOVERNANCE_ROLE = await expertRegistry.GOVERNANCE_ROLE();
    await expertRegistry.grantRole(GOVERNANCE_ROLE, admin.address);
  });

  describe("registerExpert()", function () {
    it("Should register a new expert", async function () {
      await expect(
        expertRegistry.connect(admin).registerExpert(expert1.address, CARDIOLOGY)
      )
        .to.emit(expertRegistry, "ExpertRegistered")
        .withArgs(1, expert1.address);
    });

    it("Should prevent duplicate expert registration", async function () {
      await expertRegistry.connect(admin).registerExpert(expert1.address, CARDIOLOGY);
      await expect(
        expertRegistry.connect(admin).registerExpert(expert1.address, NEUROLOGY)
      ).to.be.revertedWith("Expert already registered");
    });
  });

  describe("updateSpecialty()", function () {
    beforeEach(async function () {
      await expertRegistry.connect(admin).registerExpert(expert1.address, CARDIOLOGY);
    });

    it("Should update expert specialty", async function () {
      await expect(
        expertRegistry.connect(admin).updateSpecialty(1, NEUROLOGY)
      )
        .to.emit(expertRegistry, "SpecialtyUpdated")
        .withArgs(1, NEUROLOGY);
    });

    it("Should maintain correct specialty lists", async function () {
      await expertRegistry.connect(admin).updateSpecialty(1, NEUROLOGY);
      const experts = await expertRegistry.getExpertsBySpecialty(NEUROLOGY);
      expect(experts).to.deep.equal([ethers.BigNumber.from("1")]);
    });
  });

  describe("setExpertStatus()", function () {
    it("Should toggle expert active status", async function () {
      await expertRegistry.connect(admin).registerExpert(expert1.address, CARDIOLOGY);
      
      await expect(
        expertRegistry.connect(admin).setExpertStatus(1, false)
      )
        .to.emit(expertRegistry, "ExpertStatusChanged")
        .withArgs(1, false);
      
      expect(await expertRegistry.isActiveExpert(1)).to.be.false;
    });
  });
});