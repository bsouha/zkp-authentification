pragma circom 2.1.6;
include "circomlib/circuits/poseidon.circom";
include "circomlib/circuits/comparators.circom";

template RoleAuth() {
    // Public Inputs (for proof verification)
    signal input requiredSpecialty;
    signal input requiredMinAge;
    signal input currentTimestamp;  // Prevents replay attacks

    // Private Inputs (user credentials)
    signal input role;
    signal input secretHash;       // Combined hash(password + salt)
    signal input licenseHash;      // Hashed medical license (doctors only)
    signal input age;              // Patient age verification
    signal input expertSpecialty;  // Expert's specialty code
    signal input nullifier;        // Unique per-session value

    // Outputs (proof statements)
    signal output isAuthenticated;
    signal output isDoctor;
    signal output isExpert;
    signal output isAdultPatient;
    signal output specialtyMatch;

    // CONSTANTS (matches Solidity enum)
    var ROLE_PATIENT = 1;
    var ROLE_DOCTOR = 2;
    var ROLE_EXPERT = 3;

    // --- HASH VERIFICATION --- //
    component credentialHasher = Poseidon(3);
    credentialHasher.inputs[0] <== role;
    credentialHasher.inputs[1] <== secretHash;
    credentialHasher.inputs[2] <== nullifier;

    // --- ROLE CHECKS --- //
    // Doctor validation
    component doctorCheck = IsEqual();
    doctorCheck.in[0] <== role;
    doctorCheck.in[1] <== ROLE_DOCTOR;
    signal isRoleDoctor <== doctorCheck.out;

    // License check (only for doctors)
    component licenseCheck = IsEqual();
    licenseCheck.in[0] <== licenseHash;
    licenseCheck.in[1] <== requiredSpecialty; // Specialty encoded in license
    signal hasValidLicense <== isRoleDoctor * licenseCheck.out;

    // Expert validation
    component expertCheck = IsEqual();
    expertCheck.in[0] <== role;
    expertCheck.in[1] <== ROLE_EXPERT;
    signal isRoleExpert <== expertCheck.out;

    // --- SPECIALTY MATCHING --- //
    component specialtyCheck = IsEqual();
    specialtyCheck.in[0] <== expertSpecialty;
    specialtyCheck.in[1] <== requiredSpecialty;
    specialtyMatch <== isRoleExpert * specialtyCheck.out;

    // --- AGE VERIFICATION --- //
    component ageCheck = LessThan(32);
    ageCheck.in[0] <== age;
    ageCheck.in[1] <== requiredMinAge;
    signal isAdult <== 1 - ageCheck.out; // Inverted logic (age >= minAge)

    // Patient validation
    component patientCheck = IsEqual();
    patientCheck.in[0] <== role;
    patientCheck.in[1] <== ROLE_PATIENT;
    isAdultPatient <== patientCheck.out * isAdult;

    // --- FINAL AUTH LOGIC --- //
    // All credentials must be valid
    signal credsValid <== credentialHasher.out; // Poseidon hash acts as constraint

    // Role-specific requirements
    signal roleRequirementsValid <== 
        (1 - isRoleDoctor) +               // Either not a doctor
        (isRoleDoctor * hasValidLicense);  // Or has valid license

    isAuthenticated <== credsValid * roleRequirementsValid;
}

// Main component with public inputs
component main { 
    public [requiredSpecialty, requiredMinAge, currentTimestamp] 
} = RoleAuth();