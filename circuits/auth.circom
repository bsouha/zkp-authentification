pragma circom 2.1.6;

include "circomlib/circuits/poseidon.circom";
include "circomlib/circuits/comparators.circom";

/* ============== ROLE CONSTANTS ============== */
function ROLE_PATIENT() { return 1; }
function ROLE_DOCTOR() { return 2; }
function ROLE_EXPERT() { return 3; }
/* =========================================== */

template RoleEquality() {
    signal input in[2];
    signal output out;
    component isz = IsZero();
    in[1] - in[0] ==> isz.in;
    isz.out ==> out;
}

template Auth() {
    // Public inputs
    signal input requiredSpecialty;
    signal input requiredMinAge;
    
    // Private inputs
    signal input role;
    signal input password;
    signal input secretLicense;
    signal input age;
    signal input expertSpecialty;
    
    // Stored hashes
    signal input storedRoleHash;
    signal input storedPwdHash;
    signal input storedLicenseHash;

    // Outputs
    signal output isAuthenticated;
    signal output isDoctor;
    signal output isExpert;
    signal output canRequestExpert;
    signal output isAdultPatient;

    // Hash computations
    component roleHasher = Poseidon(1);
    roleHasher.inputs[0] <== role;
    
    component pwdHasher = Poseidon(1);
    pwdHasher.inputs[0] <== password;
    
    component licenseHasher = Poseidon(1);
    licenseHasher.inputs[0] <== secretLicense;

    // Role equality checks
    component checkDoctor = RoleEquality();
    checkDoctor.in[0] <== role;
    checkDoctor.in[1] <== ROLE_DOCTOR();
    isDoctor <== checkDoctor.out;

    component checkExpert = RoleEquality();
    checkExpert.in[0] <== role;
    checkExpert.in[1] <== ROLE_EXPERT();
    isExpert <== checkExpert.out;

    component checkPatient = RoleEquality();
    checkPatient.in[0] <== role;
    checkPatient.in[1] <== ROLE_PATIENT();
    signal isPatient <== checkPatient.out;

    // License verification
    component checkLicense = RoleEquality();
    checkLicense.in[0] <== licenseHasher.out;
    checkLicense.in[1] <== storedLicenseHash;
    signal licenseValid <== checkLicense.out;
    signal isLicensed <== isDoctor * licenseValid;

    // Age verification
    component ageCheck = LessThan(32);
    ageCheck.in[0] <== requiredMinAge - 1;
    ageCheck.in[1] <== age;
    isAdultPatient <== isPatient * ageCheck.out;
    // Expert request verification
    component checkSpecialty = RoleEquality();
    checkSpecialty.in[0] <== expertSpecialty;
    checkSpecialty.in[1] <== requiredSpecialty;
    canRequestExpert <== isLicensed * checkSpecialty.out;

    // Final authentication broken into quadratic steps
    component checkRoleHash = RoleEquality();
    checkRoleHash.in[0] <== roleHasher.out;
    checkRoleHash.in[1] <== storedRoleHash;
    
    component checkPwdHash = RoleEquality();
    checkPwdHash.in[0] <== pwdHasher.out;
    checkPwdHash.in[1] <== storedPwdHash;

    // Quadratic constraints only
    signal rolePwdValid <== checkRoleHash.out * checkPwdHash.out;
    signal doctorCheck <== 1 - isDoctor + isLicensed;
    isAuthenticated <== rolePwdValid * doctorCheck;
}

component main { public [requiredSpecialty, requiredMinAge] } = Auth();
