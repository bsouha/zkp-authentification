// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IZKPIdentityRegistry.sol";
import "./ZKPVerifier.sol";

/**
 * @title Zero-Knowledge Proof Identity Registry
 * @notice Manages pseudonymous identities for patients, doctors, and experts
 * @dev Roles: 1=PATIENT, 2=DOCTOR, 3=EXPERT (must match auth.circom)
 */
contract ZKPIdentityRegistry is IZKPIdentityRegistry {
    // Constants match auth.circom
    uint8 public constant PATIENT = 1;
    uint8 public constant DOCTOR = 2;
    uint8 public constant EXPERT = 3;

    ZKPVerifier public immutable verifier;
    mapping(address => Identity) private _identities;
    mapping(bytes32 => bool) private _nullifiers;

    constructor(address _verifier) {
        verifier = ZKPVerifier(_verifier);
    }

    /**
     * @notice Registers an identity with zk-SNARK proof
     * @param a,b,c Groth16 proof components
     * @param input Public inputs [role, attribute]
     * @param nullifier Unique session identifier
     */
    function register(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[2] calldata input,
        bytes32 nullifier,
        bytes calldata /*signature*/
    ) external override {
        // Anti-replay protection
        require(!_nullifiers[nullifier], "Nullifier reused");
        _nullifiers[nullifier] = true;
        emit NullifierUsed(nullifier);

        // Verify proof matches circuit
        require(verifier.verifyProof(a, b, c, input), "Invalid proof");

        uint8 role = uint8(input[0]);
        require(role >= PATIENT && role <= EXPERT, "Invalid role");

        _identities[msg.sender] = Identity({
            role: role,
            attribute: bytes32(input[1]),
            expiry: uint40(block.timestamp + 365 days) // 1-year default
        });

        emit RoleRegistered(msg.sender, role);
    }

    /// @inheritdoc IZKPIdentityRegistry
    function hasRole(address user, uint8 role) public view override returns (bool) {
        Identity memory id = _identities[user];
        return id.role == role && block.timestamp < id.expiry;
    }

    /// @inheritdoc IZKPIdentityRegistry
    function getIdentity(address user) public view override returns (Identity memory) {
        return _identities[user];
    }

    // Gas-optimized view methods
    function isNullifierUsed(bytes32 nullifier) public view returns (bool) {
        return _nullifiers[nullifier];
    }

    function getRole(address user) public view returns (uint8) {
        return _identities[user].role;
    }
}