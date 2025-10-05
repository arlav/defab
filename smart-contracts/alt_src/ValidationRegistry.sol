// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ValidationRegistry {

    struct Validator {
        address validatorAddress;
        string organizationName;
        string certificationNumber;
        uint256 registeredAt;
        uint256 validationCount;
        uint256 reputationScore;    // 0-1000
        bool isActive;
    }

    struct ValidationRecord {
        uint256 passportTokenId;
        address validator;
        uint256 timestamp;
        bool passed;
        string ipfsReportHash;      // Validation report on IPFS
        bytes signature;
    }

    mapping(address => Validator) public validators;
    mapping(uint256 => ValidationRecord[]) public passportValidations;

    uint256 public constant REQUIRED_VALIDATIONS = 3;

    event ValidatorRegistered(address indexed validator, string organization);
    event ValidationSubmitted(uint256 indexed tokenId, address validator, bool passed);

    function registerValidator(
        string memory _orgName,
        string memory _certNumber
    ) external {
        require(validators[msg.sender].validatorAddress == address(0), "Already registered");

        validators[msg.sender] = Validator({
            validatorAddress: msg.sender,
            organizationName: _orgName,
            certificationNumber: _certNumber,
            registeredAt: block.timestamp,
            validationCount: 0,
            reputationScore: 500,  // Start at median
            isActive: true
        });

        emit ValidatorRegistered(msg.sender, _orgName);
    }

    function submitValidation(
        uint256 _tokenId,
        bool _passed,
        string memory _reportHash,
        bytes memory _signature
    ) external {
        require(validators[msg.sender].isActive, "Not authorized validator");

        passportValidations[_tokenId].push(ValidationRecord({
            passportTokenId: _tokenId,
            validator: msg.sender,
            timestamp: block.timestamp,
            passed: _passed,
            ipfsReportHash: _reportHash,
            signature: _signature
        }));

        validators[msg.sender].validationCount++;

        emit ValidationSubmitted(_tokenId, msg.sender, _passed);
    }

    function getValidationStatus(uint256 _tokenId)
        external
        view
        returns (uint256 totalValidations, uint256 passedValidations)
    {
        ValidationRecord[] memory records = passportValidations[_tokenId];
        totalValidations = records.length;

        for (uint i = 0; i < records.length; i++) {
            if (records[i].passed) {
                passedValidations++;
            }
        }
    }

    function isFullyValidated(uint256 _tokenId) external view returns (bool) {
        (uint256 total, uint256 passed) = this.getValidationStatus(_tokenId);
        return passed >= REQUIRED_VALIDATIONS;
    }
}
