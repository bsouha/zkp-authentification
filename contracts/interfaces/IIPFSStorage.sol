// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IIPFSStorage {
    enum AccessLevel { NONE, READ, WRITE, OWNER }

    struct StoredData {
        bytes32 ipfsHash;
        uint40 storedAt;
        uint40 expiresAt;
        bool encrypted;
        address owner;
    }

    event DataStored(uint256 indexed contentId, address indexed owner);
    event AccessGranted(uint256 indexed contentId, address indexed grantee, AccessLevel level);
    event DataExpired(uint256 indexed contentId);

    function storeData(
        bytes32 ipfsHash,
        bool encrypted,
        uint40 expiryDuration
    ) external returns (uint256);

    function grantAccess(
        uint256 contentId,
        address grantee,
        AccessLevel level
    ) external;

    function retrieveHash(uint256 contentId) external view returns (bytes32);
    function verifyAccess(uint256 contentId, address user) external view returns (AccessLevel);
    function cleanupExpired(uint256 contentId) external;
}