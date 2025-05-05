const { expect } = require("chai");

describe("ReputationSystem (Unit)", function () {
  let reputation, expertRegistry;
  let admin, expert;

  before(async () => {
    [admin, expert] = await ethers.getSigners();
    
    expertRegistry = await deployMockContract(admin, [
      "function getExpert(uint256) returns (uint32,uint40,uint40,bool,uint256)"
    ]);
    
    reputation = await ethers.deployContract("ReputationSystem", [expertRegistry.address]);
  });

  describe("updateReputation()", function () {
    it("Should increase reputation for positive delta", async () => {
      await expertRegistry.mock.getExpert.returns(0, 0, Date.now(), true, 1000);
      await reputation.updateReputation(1, 50);
      expect(await reputation.getReputation(1)).to.equal(1050);
    });

    it("Should enforce minimum reputation", async () => {
      await expertRegistry.mock.getExpert.returns(0, 0, Date.now(), true, 100);
      await reputation.updateReputation(1, -200);
      expect(await reputation.getReputation(1)).to.equal(100); // Minimum
    });
  });

  describe("decayReputation()", function () {
    it("Should apply time-based decay", async () => {
      const oldTimestamp = Math.floor(Date.now() / 1000) - 60 * 86400; // 60 days ago
      await expertRegistry.mock.getExpert.returns(0, 0, oldTimestamp, true, 1000);
      
      // With 1% monthly decay, expect ~12.25% decay over 60 days
      expect(await reputation.getReputation(1)).to.be.approximately(878, 2); 
    });
  });
});