// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// @dev Import Ownable for contract ownership and admin functions
import "@openzeppelin/contracts/access/Ownable.sol";
// @dev Import ReentrancyGuard to prevent reentrancy attacks
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TestingRegistry
 * @dev Registry for recording and validating concrete testing data linked to ConcretePassport NFTs
 * @dev Handles mechanical tests, non-destructive tests, and multi-party validation
 */
contract TestingRegistry is Ownable, ReentrancyGuard {

    // @dev Counter for generating unique test result IDs
    uint256 private _testIdCounter;

    /**
     * @dev Enum representing different types of concrete tests
     */
    enum TestType {
        Compression,        // @dev ASTM C39 compression test
        Flexural,          // @dev Flexural strength test
        Tensile,           // @dev Tensile strength test
        Ultrasonic,        // @dev Non-destructive ultrasonic test
        ReboundHammer,     // @dev Non-destructive rebound hammer test
        Durability,        // @dev Long-term durability studies
        Chemical,          // @dev Chemical composition analysis
        Other              // @dev Other test types
    }

    /**
     * @dev Enum representing validation status of test results
     */
    enum ValidationStatus {
        Pending,           // @dev Test submitted, awaiting validation
        Validated,         // @dev Test validated by authorized party
        Disputed,          // @dev Test results disputed
        Rejected           // @dev Test rejected due to issues
    }

    /**
     * @dev Structure containing all test result metadata
     * @param testId Unique identifier for this test result
     * @param passportId ConcretePassport NFT token ID this test is linked to
     * @param testType Type of test performed
     * @param ipfsHash IPFS hash pointing to complete test data package
     * @param labAddress Address of laboratory that performed test
     * @param submittedBy Address that submitted the test results
     * @param submittedAt Block timestamp of submission
     * @param validationStatus Current validation status
     * @param validatedBy Address that validated the test (if validated)
     * @param validatedAt Block timestamp of validation
     * @param testDate Date when physical test was performed (Unix timestamp)
     * @param curingAge Age of concrete when tested (in days)
     * @param resultSummary On-chain summary of key results
     */
    struct TestResult {
        uint256 testId;                 // @dev Unique test ID
        uint256 passportId;             // @dev Linked passport token ID
        TestType testType;              // @dev Type of test
        string ipfsHash;                // @dev IPFS hash for full test data
        address labAddress;             // @dev Lab that performed test
        address submittedBy;            // @dev Submitter address
        uint256 submittedAt;            // @dev Submission timestamp
        ValidationStatus validationStatus;  // @dev Current validation status
        address validatedBy;            // @dev Validator address
        uint256 validatedAt;            // @dev Validation timestamp
        uint256 testDate;               // @dev Physical test date
        uint256 curingAge;              // @dev Concrete age in days
        string resultSummary;           // @dev On-chain summary (e.g., "53.6 MPa avg")
    }

    // @dev Maps test ID to test result data
    mapping(uint256 => TestResult) public testResults;

    // @dev Maps passport ID to array of test IDs
    mapping(uint256 => uint256[]) public passportTests;

    // @dev Maps lab address to authorization status
    mapping(address => bool) public authorizedLabs;

    // @dev Maps lab address to array of test IDs they performed
    mapping(address => uint256[]) public labTests;

    // @dev Maps test type to array of test IDs
    mapping(TestType => uint256[]) public testsByType;

    // @dev Emitted when a new test result is submitted
    event TestResultSubmitted(
        uint256 indexed testId,         // @dev The newly created test ID
        uint256 indexed passportId,     // @dev Linked passport ID
        TestType testType,               // @dev Type of test
        address indexed labAddress,      // @dev Lab that performed test
        string ipfsHash,                 // @dev IPFS hash for test data
        uint256 timestamp                // @dev Submission timestamp
    );

    // @dev Emitted when a test result is validated
    event TestResultValidated(
        uint256 indexed testId,         // @dev Test ID being validated
        address indexed validatedBy,     // @dev Validator address
        ValidationStatus status,         // @dev New validation status
        uint256 timestamp                // @dev Validation timestamp
    );

    // @dev Emitted when a test result is updated
    event TestResultUpdated(
        uint256 indexed testId,         // @dev Test ID being updated
        string newIpfsHash,              // @dev New IPFS hash
        uint256 timestamp                // @dev Update timestamp
    );

    // @dev Emitted when a lab is authorized or deauthorized
    event LabAuthorizationChanged(
        address indexed labAddress,      // @dev Lab address
        bool authorized,                 // @dev Authorization status
        uint256 timestamp                // @dev Change timestamp
    );

    /**
     * @dev Modifier to check if caller is an authorized lab
     */
    modifier onlyAuthorizedLab() {
        require(authorizedLabs[msg.sender], "Not an authorized lab");
        _;
    }

    /**
     * @dev Modifier to check if test exists
     * @param testId The test ID to verify
     */
    modifier testExists(uint256 testId) {
        require(testId > 0 && testId < _testIdCounter, "Test does not exist");
        _;
    }

    /**
     * @dev Constructor initializes the contract
     * @param initialOwner Address that will own the contract
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        _testIdCounter = 1;  // @dev Start test IDs at 1
    }

    /**
     * @dev Authorizes or deauthorizes a laboratory
     * @param labAddress Address of the laboratory
     * @param authorized True to authorize, false to deauthorize
     */
    function setLabAuthorization(address labAddress, bool authorized)
        external
        onlyOwner
    {
        require(labAddress != address(0), "Invalid lab address");
        authorizedLabs[labAddress] = authorized;

        emit LabAuthorizationChanged(labAddress, authorized, block.timestamp);
    }

    /**
     * @dev Submits a new test result to the registry
     * @param passportId ConcretePassport token ID this test relates to
     * @param testType Type of test performed
     * @param ipfsHash IPFS hash pointing to complete test data
     * @param testDate Unix timestamp of when physical test was performed
     * @param curingAge Age of concrete in days when tested
     * @param resultSummary Short on-chain summary of results
     * @return testId The newly created test ID
     */
    function submitTestResult(
        uint256 passportId,
        TestType testType,
        string memory ipfsHash,
        uint256 testDate,
        uint256 curingAge,
        string memory resultSummary
    ) external nonReentrant onlyAuthorizedLab returns (uint256) {
        // @dev Validate inputs
        require(passportId > 0, "Invalid passport ID");
        require(bytes(ipfsHash).length > 0, "IPFS hash required");
        require(testDate <= block.timestamp, "Test date cannot be in future");
        require(bytes(resultSummary).length > 0, "Result summary required");

        // @dev Get next test ID and increment counter
        uint256 testId = _testIdCounter;
        _testIdCounter++;

        // @dev Store test result data
        testResults[testId] = TestResult({
            testId: testId,
            passportId: passportId,
            testType: testType,
            ipfsHash: ipfsHash,
            labAddress: msg.sender,
            submittedBy: msg.sender,
            submittedAt: block.timestamp,
            validationStatus: ValidationStatus.Pending,
            validatedBy: address(0),
            validatedAt: 0,
            testDate: testDate,
            curingAge: curingAge,
            resultSummary: resultSummary
        });

        // @dev Add to passport's test list
        passportTests[passportId].push(testId);

        // @dev Add to lab's test list
        labTests[msg.sender].push(testId);

        // @dev Add to test type index
        testsByType[testType].push(testId);

        // @dev Emit submission event
        emit TestResultSubmitted(
            testId,
            passportId,
            testType,
            msg.sender,
            ipfsHash,
            block.timestamp
        );

        return testId;
    }

    /**
     * @dev Validates a test result
     * @dev Can be called by authorized labs or contract owner
     * @param testId Test ID to validate
     * @param status Validation status to set
     */
    function validateTestResult(uint256 testId, ValidationStatus status)
        external
        testExists(testId)
    {
        // @dev Only authorized labs or owner can validate
        require(
            authorizedLabs[msg.sender] || msg.sender == owner(),
            "Not authorized to validate"
        );

        // @dev Cannot validate your own test
        require(
            testResults[testId].labAddress != msg.sender,
            "Cannot validate own test"
        );

        // @dev Update validation status
        testResults[testId].validationStatus = status;
        testResults[testId].validatedBy = msg.sender;
        testResults[testId].validatedAt = block.timestamp;

        // @dev Emit validation event
        emit TestResultValidated(testId, msg.sender, status, block.timestamp);
    }

    /**
     * @dev Updates the IPFS hash for a test result
     * @dev Only the submitting lab can update before validation
     * @param testId Test ID to update
     * @param newIpfsHash New IPFS hash
     */
    function updateTestResult(uint256 testId, string memory newIpfsHash)
        external
        testExists(testId)
    {
        // @dev Only submitting lab can update
        require(
            testResults[testId].submittedBy == msg.sender,
            "Only submitter can update"
        );

        // @dev Cannot update after validation
        require(
            testResults[testId].validationStatus == ValidationStatus.Pending,
            "Cannot update validated test"
        );

        // @dev Validate new hash
        require(bytes(newIpfsHash).length > 0, "IPFS hash required");

        // @dev Update IPFS hash
        testResults[testId].ipfsHash = newIpfsHash;

        // @dev Emit update event
        emit TestResultUpdated(testId, newIpfsHash, block.timestamp);
    }

    /**
     * @dev Gets complete test result information
     * @param testId Test ID to query
     * @return TestResult Complete test result struct
     */
    function getTestResult(uint256 testId)
        external
        view
        testExists(testId)
        returns (TestResult memory)
    {
        return testResults[testId];
    }

    /**
     * @dev Gets all test IDs for a passport
     * @param passportId Passport ID to query
     * @return Array of test IDs
     */
    function getPassportTests(uint256 passportId)
        external
        view
        returns (uint256[] memory)
    {
        return passportTests[passportId];
    }

    /**
     * @dev Gets all test IDs performed by a lab
     * @param labAddress Lab address to query
     * @return Array of test IDs
     */
    function getLabTests(address labAddress)
        external
        view
        returns (uint256[] memory)
    {
        return labTests[labAddress];
    }

    /**
     * @dev Gets all test IDs of a specific type
     * @param testType Test type to query
     * @return Array of test IDs
     */
    function getTestsByType(TestType testType)
        external
        view
        returns (uint256[] memory)
    {
        return testsByType[testType];
    }

    /**
     * @dev Gets test history for a passport with filtering
     * @param passportId Passport ID to query
     * @param testType Test type to filter by (use Other to get all)
     * @param minCuringAge Minimum curing age filter (0 for no filter)
     * @return filteredTests Array of test results matching criteria
     */
    function getTestHistory(
        uint256 passportId,
        TestType testType,
        uint256 minCuringAge
    ) external view returns (TestResult[] memory filteredTests) {
        uint256[] storage testIds = passportTests[passportId];

        // @dev Count matching tests
        uint256 matchCount = 0;
        for (uint256 i = 0; i < testIds.length; i++) {
            TestResult storage test = testResults[testIds[i]];
            if (_testMatches(test, testType, minCuringAge)) {
                matchCount++;
            }
        }

        // @dev Build filtered results array
        filteredTests = new TestResult[](matchCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < testIds.length; i++) {
            TestResult storage test = testResults[testIds[i]];
            if (_testMatches(test, testType, minCuringAge)) {
                filteredTests[currentIndex] = test;
                currentIndex++;
            }
        }
    }

    /**
     * @dev Internal helper to check if test matches filter criteria
     * @param test Test result to check
     * @param testType Test type filter
     * @param minCuringAge Minimum curing age filter
     * @return Boolean indicating if test matches
     */
    function _testMatches(
        TestResult storage test,
        TestType testType,
        uint256 minCuringAge
    ) private view returns (bool) {
        bool typeMatch = (testType == TestType.Other) || (test.testType == testType);
        bool ageMatch = test.curingAge >= minCuringAge;
        return typeMatch && ageMatch;
    }

    /**
     * @dev Gets total number of tests submitted
     * @return Total test count
     */
    function getTotalTests() external view returns (uint256) {
        // @dev Subtract 1 because counter starts at 1
        return _testIdCounter - 1;
    }

    /**
     * @dev Checks if a lab is authorized
     * @param labAddress Lab address to check
     * @return Boolean indicating authorization status
     */
    function isLabAuthorized(address labAddress) external view returns (bool) {
        return authorizedLabs[labAddress];
    }

    /**
     * @dev Gets validation statistics for a lab
     * @param labAddress Lab address to analyze
     * @return totalTests Total tests submitted by lab
     * @return validatedTests Number of validated tests
     * @return rejectedTests Number of rejected tests
     * @return pendingTests Number of pending tests
     */
    function getLabStatistics(address labAddress)
        external
        view
        returns (
            uint256 totalTests,
            uint256 validatedTests,
            uint256 rejectedTests,
            uint256 pendingTests
        )
    {
        uint256[] memory testIds = labTests[labAddress];
        totalTests = testIds.length;

        for (uint256 i = 0; i < testIds.length; i++) {
            ValidationStatus status = testResults[testIds[i]].validationStatus;
            if (status == ValidationStatus.Validated) {
                validatedTests++;
            } else if (status == ValidationStatus.Rejected) {
                rejectedTests++;
            } else if (status == ValidationStatus.Pending) {
                pendingTests++;
            }
        }

        return (totalTests, validatedTests, rejectedTests, pendingTests);
    }

    /**
     * @dev Gets comprehensive test summary for a passport
     * @param passportId Passport ID to analyze
     * @return totalTests Total number of tests
     * @return validatedTests Number of validated tests
     * @return testTypes Array of unique test types performed
     */
    function getPassportTestSummary(uint256 passportId)
        external
        view
        returns (
            uint256 totalTests,
            uint256 validatedTests,
            TestType[] memory testTypes
        )
    {
        uint256[] memory testIds = passportTests[passportId];
        totalTests = testIds.length;

        // @dev Count validated tests
        for (uint256 i = 0; i < testIds.length; i++) {
            if (testResults[testIds[i]].validationStatus == ValidationStatus.Validated) {
                validatedTests++;
            }
        }

        // @dev Build unique test types array (simplified - returns all types present)
        bool[8] memory typePresent; // @dev Max 8 test types in enum
        uint256 uniqueTypeCount = 0;

        for (uint256 i = 0; i < testIds.length; i++) {
            uint256 typeIndex = uint256(testResults[testIds[i]].testType);
            if (!typePresent[typeIndex]) {
                typePresent[typeIndex] = true;
                uniqueTypeCount++;
            }
        }

        testTypes = new TestType[](uniqueTypeCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < 8; i++) {
            if (typePresent[i]) {
                testTypes[currentIndex] = TestType(i);
                currentIndex++;
            }
        }

        return (totalTests, validatedTests, testTypes);
    }
}
