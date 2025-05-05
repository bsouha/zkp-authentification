// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ZKP Identity Registry Interface
 * @notice Standardizes role-based access control using zk-SNARKs
 * @dev Roles must match auth.circom enum values (1=PATIENT, 2=DOCTOR, 3=EXPERT)
 */
interface IZKPIdentityRegistry {
    event RoleRegistered(address indexed user, uint8 role);
    event NullifierUsed(bytes32 indexed nullifier);
    
    struct Identity {
        uint8 role;
        bytes32 attribute; // specialty (experts) or age hash (patients)
        uint40 expiry;    // timestamp when role expires
    }

    /// @notice Registers a pseudonymous identity with ZKP proof
    function register(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[2] calldata input, // [role, attribute]
        bytes32 nullifier,
        bytes calldata signature
    ) external;

    /// @notice Checks if user has a specific active role
    function hasRole(address user, uint8 role) external view returns (bool);

    /// @notice Returns full identity data
    function getIdentity(address user) external view returns (Identity memory);
}