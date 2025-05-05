const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying contracts with account: ${deployer.address}`);

  // ======================
  // 1. Deploy Verifier
  // ======================
  console.log("Deploying Groth16Verifier...");
  const Verifier = await ethers.getContractFactory("Groth16Verifier");
  const verifier = await Verifier.deploy();
  await verifier.deployed();
  console.log(`Verifier deployed to: ${verifier.address}`);

  // ======================
  // 2. Deploy ZKP Identity Registry
  // ======================
  console.log("Deploying ZKPIdentityRegistry...");
  const ZKPIdentityRegistry = await ethers.getContractFactory("ZKPIdentityRegistry");
  const registry = await ZKPIdentityRegistry.deploy(verifier.address);
  await registry.deployed();
  console.log(`Registry deployed to: ${registry.address}`);

  // ======================
  // 3. Deploy Expert Registry
  // ======================
  console.log("Deploying ExpertRegistry...");
  const ExpertRegistry = await ethers.getContractFactory("ExpertRegistry");
  const expertRegistry = await ExpertRegistry.deploy();
  await expertRegistry.deployed();
  console.log(`ExpertRegistry deployed to: ${expertRegistry.address}`);

  // ======================
  // 4. Deploy Reputation System
  // ======================
  console.log("Deploying ReputationSystem...");
  const ReputationSystem = await ethers.getContractFactory("ReputationSystem");
  const reputationSystem = await ReputationSystem.deploy(expertRegistry.address);
  await reputationSystem.deployed();
  console.log(`ReputationSystem deployed to: ${reputationSystem.address}`);

  // ======================
  // 5. Deploy Medical Case
  // ======================
  console.log("Deploying MedicalCase...");
  const MedicalCase = await ethers.getContractFactory("MedicalCase");
  const medicalCase = await MedicalCase.deploy(registry.address, expertRegistry.address);
  await medicalCase.deployed();
  console.log(`MedicalCase deployed to: ${medicalCase.address}`);

  // ======================
  // 6. Deploy Consultation
  // ======================
  console.log("Deploying Consultation...");
  const Consultation = await ethers.getContractFactory("Consultation");
  const consultation = await Consultation.deploy(
    medicalCase.address,
    reputationSystem.address,
    registry.address
  );
  await consultation.deployed();
  console.log(`Consultation deployed to: ${consultation.address}`);

  // ======================
  // 7. Deploy IPFS Storage
  // ======================
  console.log("Deploying IPFSStorage...");
  const IPFSStorage = await ethers.getContractFactory("IPFSStorage");
  const ipfsStorage = await IPFSStorage.deploy(registry.address);
  await ipfsStorage.deployed();
  console.log(`IPFSStorage deployed to: ${ipfsStorage.address}`);

  // ======================
  // 8. Deploy Audit Trail
  // ======================
  console.log("Deploying AuditTrail...");
  const AuditTrail = await ethers.getContractFactory("AuditTrail");
  const auditTrail = await AuditTrail.deploy();
  await auditTrail.deployed();
  console.log(`AuditTrail deployed to: ${auditTrail.address}`);

  // ======================
  // 9. Initialize System
  // ======================
  console.log("Initializing system roles...");
  
  // Grant GOVERNANCE_ROLE to deployer
  const GOVERNANCE_ROLE = await expertRegistry.GOVERNANCE_ROLE();
  await expertRegistry.grantRole(GOVERNANCE_ROLE, deployer.address);
  
  // Grant LOGGER_ROLE to consultation contract
  const LOGGER_ROLE = await auditTrail.LOGGER_ROLE();
  await auditTrail.grantRole(LOGGER_ROLE, consultation.address);

  // ======================
  // 10. Save Deployment Data
  // ======================
  const deploymentData = {
    timestamp: new Date().toISOString(),
    network: network.name,
    deployer: deployer.address,
    contracts: {
      verifier: verifier.address,
      zkpIdentityRegistry: registry.address,
      expertRegistry: expertRegistry.address,
      reputationSystem: reputationSystem.address,
      medicalCase: medicalCase.address,
      consultation: consultation.address,
      ipfsStorage: ipfsStorage.address,
      auditTrail: auditTrail.address
    }
  };

  const deploymentsDir = path.join(__dirname, "../deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir);
  }

  fs.writeFileSync(
    path.join(deploymentsDir, `${network.name}.json`),
    JSON.stringify(deploymentData, null, 2)
  );

  console.log("Deployment data saved to deployments/ directory");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });