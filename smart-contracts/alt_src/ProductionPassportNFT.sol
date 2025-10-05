// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ProductionPassportNFT is ERC721 {

    struct ProductionPassport {
        uint256 tokenId;                    // NFT ID
        string packageId;                   // Human-readable ID (e.g., "PROD-2024-001")
        string materialId;                  // Mix design ID
        address labAddress;                 // Creating laboratory
        uint256 createdAt;                  // Block timestamp
        string ipfsManifestHash;            // Main IPFS CID
        bytes32 gcodeHash;                  // G-code verification hash
        bytes32 certificationHash;          // Final certification hash
        uint8 qualityGrade;                 // Final grade (e.g., M40 = 40)
        bool isFinalized;                   // Locked after certification
        uint8 version;                      // Manifest version
    }

    mapping(uint256 => ProductionPassport) public passports;
    mapping(string => uint256) public packageIdToToken;
    uint256 private _tokenIdCounter;

    event PassportCreated(uint256 indexed tokenId, string packageId, address lab);
    event PassportUpdated(uint256 indexed tokenId, string newIpfsHash, uint8 version);
    event PassportFinalized(uint256 indexed tokenId, bytes32 certHash, uint8 grade);

    function createPassport(
        string memory _packageId,
        string memory _materialId,
        string memory _ipfsManifestHash
    ) external returns (uint256) {
        require(packageIdToToken[_packageId] == 0, "Package ID exists");

        uint256 newTokenId = ++_tokenIdCounter;

        passports[newTokenId] = ProductionPassport({
            tokenId: newTokenId,
            packageId: _packageId,
            materialId: _materialId,
            labAddress: msg.sender,
            createdAt: block.timestamp,
            ipfsManifestHash: _ipfsManifestHash,
            gcodeHash: bytes32(0),
            certificationHash: bytes32(0),
            qualityGrade: 0,
            isFinalized: false,
            version: 1
        });

        packageIdToToken[_packageId] = newTokenId;
        _safeMint(msg.sender, newTokenId);

        emit PassportCreated(newTokenId, _packageId, msg.sender);
        return newTokenId;
    }

    function updatePassportData(
        uint256 _tokenId,
        string memory _newIpfsHash
    ) external {
        require(ownerOf(_tokenId) == msg.sender, "Not owner");
        require(!passports[_tokenId].isFinalized, "Passport finalized");

        passports[_tokenId].ipfsManifestHash = _newIpfsHash;
        passports[_tokenId].version++;

        emit PassportUpdated(_tokenId, _newIpfsHash, passports[_tokenId].version);
    }

    function finalizePassport(
        uint256 _tokenId,
        bytes32 _certificationHash,
        uint8 _qualityGrade
    ) external {
        require(ownerOf(_tokenId) == msg.sender, "Not owner");
        require(!passports[_tokenId].isFinalized, "Already finalized");
        // Additional validation checks from ValidationRegistry could be added here

        passports[_tokenId].certificationHash = _certificationHash;
        passports[_tokenId].qualityGrade = _qualityGrade;
        passports[_tokenId].isFinalized = true;

        emit PassportFinalized(_tokenId, _certificationHash, _qualityGrade);
    }

    function getPassportInfo(uint256 _tokenId)
        external
        view
        returns (ProductionPassport memory)
    {
        require(_exists(_tokenId), "Token does not exist");
        return passports[_tokenId];
    }

    function verifyDataIntegrity(
        uint256 _tokenId,
        bytes32 _providedHash
    ) external view returns (bool) {
        return passports[_tokenId].certificationHash == _providedHash;
    }
}
