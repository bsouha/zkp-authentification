describe("Consultation (Unit)", function () {
    let consultation, medicalCase, reputation;
    let doctor, expert;
  
    before(async () => {
      [doctor, expert] = await ethers.getSigners();
      
      medicalCase = await deployMockContract(admin, [
        "function getCase(uint256) returns (address,address,uint32,uint40,uint40,uint8,uint8,bytes32,bytes32)"
      ]);
      
      reputation = await deployMockContract(admin, [
        "function updateReputation(uint256,int256)"
      ]);
      
      consultation = await ethers.deployContract("Consultation", [
        medicalCase.address,
        reputation.address,
        ethers.constants.AddressZero // registry mock
      ]);
    });
  
    describe("submitDiagnosis()", function () {
      it("Should reward reputation on successful diagnosis", async () => {
        await medicalCase.mock.getCase.returns(
          patient.address, 
          doctor.address, 
          1, // specialty
          Date.now(), 
          Date.now() + 86400, 
          2, // HIGH urgency
          1, // ASSIGNED status
          "0x", 
          "0x"
        );
        
        await consultation.submitDiagnosis(
          1, 
          ethers.utils.formatBytes32String("diagnosis123"),
          ethers.utils.formatBytes32String("proof")
        );
        
        expect(reputation.updateReputation).to.have.been.calledWith(1, 5); // Expert reward
      });
    });
  });