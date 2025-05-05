const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("IPFSStorage (Unit Tests)", function () {
  let ipfsStorage, registry;
  let admin, patient, doctor;
  const IPFS_HASH = ethers.utils.formatBytes32String("QmXyz...");

  before(async function () {
    [admin, patient, doctor] = await ethers.getSigners();
    
    // Mock registry
    const Registry = await ethers.getContractFactory("ZKPIdentityRegistry");
    registry = await Registry.deploy(ethers.constants.AddressZero);
    
    // Deploy IPFSStorage
    const IPFSStorage = await ethers.getContractFactory("IPFSStorage");
    ipfsStorage = await IPFSStorage.deploy(registry.address);
  });

  describe("storeData()", function () {
    it("Should store data with IPFS hash", async function () {
      await expect(
        ipfsStorage.connect(patient).storeData(
          IPFS_HASH,
          true, // encrypted
          86400 // 1 day expiry
        )
      )
        .to.emit(ipfsStorage, "DataStored")
        .withArgs(1, patient.address);
    });
  });

  describe("grantAccess()", function () {
    beforeEach(async function () {
      await ipfsStorage.connect(patient).storeData(IPFS_HASH, true, 86400);
    });

    it("Should grant access to doctors", async function () {
      await expect(
        ipfsStorage.connect(patient).grantAccess(
          1, // contentId
          doctor.address,
          1 // READ access
        )
      )
        .to.emit(ipfsStorage, "AccessGranted")
        .withArgs(1, doctor.address, 1);
    });
  });
});