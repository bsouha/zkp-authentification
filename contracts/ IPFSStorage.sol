// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IIPFSStorage.sol";
import "./interfaces/IZKPIdentityRegistry.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract IPFSStorage is IIPFSStorage, AccessControl {
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");

    IZKPIdentityRegistry public immutable identityRegistry;
    
    mapping(uint256 => StoredData) private _storedData;
    mapping(uint256 => mapping(address => AccessLevel)) private _accessControls;
    uint256 private _nextContentId = 1;

    constructor(address _identityRegistry) {
        identityRegistry = IZKPIdentityRegistry(_identityRegistry);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function storeData(
        bytes32 ipfsHash,
        bool encrypted,
        uint40 expiryDuration
    ) external returns (uint256) {
        require(identityRegistry.hasRole(msg.sender, IZKPIdentityRegistry.Role.PATIENT), "Only patients");

        uint256 contentId = _nextContentId++;
        uint40 expiry = expiryDuration > 0 ? 
            uint40(block.timestamp) + expiryDuration : 
            uint40(0);

        _storedData[contentId] = StoredData({
            ipfsHash: ipfsHash,
            storedAt: uint40(block.timestamp),
            expiresAt: expiry,
            encrypted: encrypted,
            owner: msg.sender
        });

        _accessControls[contentId][msg.sender] = AccessLevel.OWNER;
        emit DataStored(contentId, msg.sender);
        return contentId;
    }

    function grantAccess(
        uint256 contentId,
        address grantee,
        AccessLevel level
    ) external {
        require(_accessControls[contentId][msg.sender] >= AccessLevel.OWNER, "Not owner");
        require(identityRegistry.hasRole(grantee, IZKPIdentityRegistry.Role.DOCTOR), "Only doctors");

        _accessControls[contentId][grantee] = level;
        emit AccessGranted(contentId, grantee, level);
    }

    function retrieveHash(uint256 contentId) external view returns (bytes32) {
        require(_verifyAccess(contentId, msg.sender) >= AccessLevel.READ, "No access");
        require(!_isExpired(contentId), "Data expired");
        return _storedData[contentId].ipfsHash;
    }

    function cleanupExpired(uint256 contentId) external {
        require(_isExpired(contentId), "Not expired");
        delete _storedData[contentId];
        emit DataExpired(contentId);
    }

    // ====================== VIEW FUNCTIONS ======================
    function verifyAccess(uint256 contentId, address user) public view returns (AccessLevel) {
        return _verifyAccess(contentId, user);
    }

    function getDataInfo(uint256 contentId) public view returns (StoredData memory) {
        return _storedData[contentId];
    }

    // ====================== INTERNAL HELPERS ======================
    function _verifyAccess(uint256 contentId, address user) internal view returns (AccessLevel) {
        if (_accessControls[contentId][user] != AccessLevel.NONE) {
            return _accessControls[contentId][user];
        }
        return AccessLevel.NONE;
    }

    function _isExpired(uint256 contentId) internal view returns (bool) {
        return _storedData[contentId].expiresAt > 0 && 
               block.timestamp > _storedData[contentId].expiresAt;
    }
}