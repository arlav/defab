// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DataProvenance {

    struct MaterialBatch {
        string batchNumber;
        string materialType;
        string supplierName;
        bytes32 certificateHash;
        uint256 receivedDate;
        uint256 expiryDate;
    }

    struct ProcessEvent {
        uint256 passportTokenId;
        string eventType;           // "mixing", "printing", "testing"
        address operator;
        uint256 timestamp;
        string ipfsDataHash;        // Detailed process data
        bytes32 parametersHash;     // Hash of critical parameters
    }

    mapping(uint256 => MaterialBatch[]) public passportMaterials;
    mapping(uint256 => ProcessEvent[]) public processHistory;

    event MaterialAdded(uint256 indexed tokenId, string batchNumber, string materialType);
    event ProcessRecorded(uint256 indexed tokenId, string eventType, address operator);

    function addMaterialBatch(
        uint256 _tokenId,
        string memory _batchNumber,
        string memory _materialType,
        string memory _supplier,
        bytes32 _certHash,
        uint256 _expiryDate
    ) external {
        passportMaterials[_tokenId].push(MaterialBatch({
            batchNumber: _batchNumber,
            materialType: _materialType,
            supplierName: _supplier,
            certificateHash: _certHash,
            receivedDate: block.timestamp,
            expiryDate: _expiryDate
        }));

        emit MaterialAdded(_tokenId, _batchNumber, _materialType);
    }

    function recordProcessEvent(
        uint256 _tokenId,
        string memory _eventType,
        string memory _ipfsDataHash,
        bytes32 _parametersHash
    ) external {
        processHistory[_tokenId].push(ProcessEvent({
            passportTokenId: _tokenId,
            eventType: _eventType,
            operator: msg.sender,
            timestamp: block.timestamp,
            ipfsDataHash: _ipfsDataHash,
            parametersHash: _parametersHash
        }));

        emit ProcessRecorded(_tokenId, _eventType, msg.sender);
    }

    function getProcessHistory(uint256 _tokenId)
        external
        view
        returns (ProcessEvent[] memory)
    {
        return processHistory[_tokenId];
    }
}
