describe("AuditTrail (Unit)", function () {
    let auditTrail;
    const EVENT_TYPES = {
      CASE_CREATED: 0,
      DIAGNOSIS_SUBMITTED: 2
    };
  
    before(async () => {
      auditTrail = await ethers.deployContract("AuditTrail");
    });
  
    describe("logEvent()", function () {
      it("Should increment entry counter", async () => {
        await auditTrail.logEvent(
          EVENT_TYPES.CASE_CREATED,
          patient.address,
          ethers.utils.formatBytes32String("case123")
        );
        
        expect(await auditTrail.getTotalLogs()).to.equal(1);
      });
  
      it("Should track actor-specific logs", async () => {
        await auditTrail.logEvent(
          EVENT_TYPES.DIAGNOSIS_SUBMITTED,
          doctor.address,
          ethers.utils.formatBytes32String("diagnosis456")
        );
        
        const logs = await auditTrail.getAuditLogsByActor(doctor.address);
        expect(logs.length).to.equal(1);
      });
    });
  });