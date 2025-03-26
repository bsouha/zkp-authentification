const { buildPoseidon } = require("circomlibjs");
const fs = require("fs");

// Convert string to numeric array (for license hashing)
function stringToArray(str) {
    return Array.from(str).map(c => c.charCodeAt(0));
}

async function main() {
    const poseidon = await buildPoseidon();
    
    // Values from your input.json
    const testValues = {
        role: 2,
        password: "123",
        license: "MD-12345"
    };

    // Compute hashes
    const computed = {
        roleHash: poseidon.F.toString(poseidon([testValues.role])),
        pwdHash: poseidon.F.toString(poseidon(stringToArray(testValues.password))),
        licenseHash: poseidon.F.toString(poseidon(stringToArray(testValues.license)))
    };

    // Compare with input.json
    const input = JSON.parse(fs.readFileSync("input.json"));
    
    console.log("========= HASH VERIFICATION =========");
    console.log("Role Hash (2):");
    console.log("  Computed:", computed.roleHash);
    console.log("  Input:   ", input.storedRoleHash);
    
    console.log("\nPassword Hash ('123'):");
    console.log("  Computed:", computed.pwdHash);
    console.log("  Input:   ", input.storedPwdHash);
    
    console.log("\nLicense Hash ('MD-12345'):");
    console.log("  Computed:", computed.licenseHash);
    console.log("  Input:   ", input.storedLicenseHash);
    
    console.log("\nNote: If hashes don't match, use the computed values in input.json");
}

main().catch(console.error);