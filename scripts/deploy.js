const hre = require("hardhat");

async function main() {
    // Deploy Verifier
    const Verifier = await hre.ethers.getContractFactory("Verifier");
    const verifier = await Verifier.deploy();
    await verifier.deployed();
    console.log("Verifier deployed to:", verifier.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});