# TestingRegistry.sol - Implementation Summary

## Overview
`TestingRegistry.sol` is a comprehensive registry for recording and validating concrete testing data linked to ConcretePassport NFTs. It implements data point #11 from the DeSci Data Package Passport.

---

## Core Features

### 1. Test Types Supported
- **Compression** - ASTM C39 compression tests (most common)
- **Flexural** - Flexural strength tests
- **Tensile** - Tensile strength tests
- **Ultrasonic** - Non-destructive ultrasonic testing
- **ReboundHammer** - Non-destructive rebound hammer testing
- **Durability** - Long-term durability studies
- **Chemical** - Chemical composition analysis
- **Other** - Custom test types

### 2. Validation Workflow
1. **Pending** - Test submitted, awaiting validation
2. **Validated** - Test validated by authorized third party
3. **Disputed** - Test results disputed by validator
4. **Rejected** - Test rejected due to quality issues

### 3. Authorization System
- Only authorized laboratories can submit test results
- Contract owner manages lab authorizations
- Peer validation: labs cannot validate their own tests
- Multi-party validation ensures data integrity

---

## Data Structure

### TestResult Struct
```solidity
struct TestResult {
    uint256 testId;              // Unique test identifier
    uint256 passportId;          // Linked ConcretePassport token ID
    TestType testType;           // Type of test performed
    string ipfsHash;             // IPFS hash for complete test data
    address labAddress;          // Lab that performed test
    address submittedBy;         // Submitter address
    uint256 submittedAt;         // Submission timestamp
    ValidationStatus validationStatus;  // Current status
    address validatedBy;         // Validator address
    uint256 validatedAt;         // Validation timestamp
    uint256 testDate;            // Physical test date
    uint256 curingAge;           // Concrete age in days
    string resultSummary;        // On-chain summary (e.g., "53.6 MPa avg")
}
```

### Storage Mappings
```solidity
mapping(uint256 => TestResult) public testResults;           // Test ID → Test data
mapping(uint256 => uint256[]) public passportTests;          // Passport ID → Test IDs
mapping(address => bool) public authorizedLabs;              // Lab → Authorized status
mapping(address => uint256[]) public labTests;               // Lab → Test IDs
mapping(TestType => uint256[]) public testsByType;           // Test type → Test IDs
```

---

## Key Functions

### Administrative Functions

#### `setLabAuthorization(address labAddress, bool authorized)`
- Authorizes or deauthorizes a laboratory
- Only contract owner can call
- Emits `LabAuthorizationChanged` event

### Test Submission Functions

#### `submitTestResult(...)`
```solidity
function submitTestResult(
    uint256 passportId,      // Passport to link test to
    TestType testType,       // Type of test
    string memory ipfsHash,  // IPFS hash for full test data
    uint256 testDate,        // When physical test was performed
    uint256 curingAge,       // Concrete age in days
    string memory resultSummary  // On-chain summary
) external returns (uint256 testId)
```
- Only authorized labs can submit
- Creates new test record with `Pending` status
- Links test to passport
- Returns new test ID
- Emits `TestResultSubmitted` event

#### `updateTestResult(uint256 testId, string memory newIpfsHash)`
- Allows lab to update IPFS hash before validation
- Only submitting lab can update
- Cannot update after validation
- Emits `TestResultUpdated` event

### Validation Functions

#### `validateTestResult(uint256 testId, ValidationStatus status)`
- Validates or rejects a test result
- Authorized labs or owner can validate
- Cannot validate your own test (peer review)
- Updates validation status and validator info
- Emits `TestResultValidated` event

### Query Functions

#### `getTestResult(uint256 testId)`
- Returns complete test result struct

#### `getPassportTests(uint256 passportId)`
- Returns all test IDs for a passport

#### `getLabTests(address labAddress)`
- Returns all test IDs performed by a lab

#### `getTestsByType(TestType testType)`
- Returns all test IDs of a specific type

#### `getTestHistory(uint256 passportId, TestType testType, uint256 minCuringAge)`
- Returns filtered test results for a passport
- Filter by test type (use `Other` for all types)
- Filter by minimum curing age
- Returns array of complete TestResult structs

#### `getTotalTests()`
- Returns total number of tests in registry

#### `isLabAuthorized(address labAddress)`
- Checks if a lab is authorized

### Statistics Functions

#### `getLabStatistics(address labAddress)`
Returns comprehensive lab statistics:
```solidity
returns (
    uint256 totalTests,      // Total tests submitted
    uint256 validatedTests,  // Number validated
    uint256 rejectedTests,   // Number rejected
    uint256 pendingTests     // Number pending
)
```

#### `getPassportTestSummary(uint256 passportId)`
Returns passport test summary:
```solidity
returns (
    uint256 totalTests,           // Total tests for passport
    uint256 validatedTests,       // Number validated
    TestType[] memory testTypes   // Unique test types performed
)
```

---

## Events

### `TestResultSubmitted`
```solidity
event TestResultSubmitted(
    uint256 indexed testId,
    uint256 indexed passportId,
    TestType testType,
    address indexed labAddress,
    string ipfsHash,
    uint256 timestamp
)
```

### `TestResultValidated`
```solidity
event TestResultValidated(
    uint256 indexed testId,
    address indexed validatedBy,
    ValidationStatus status,
    uint256 timestamp
)
```

### `TestResultUpdated`
```solidity
event TestResultUpdated(
    uint256 indexed testId,
    string newIpfsHash,
    uint256 timestamp
)
```

### `LabAuthorizationChanged`
```solidity
event LabAuthorizationChanged(
    address indexed labAddress,
    bool authorized,
    uint256 timestamp
)
```

---

## Integration with IPFS

### On-Chain Data:
- Test metadata (type, dates, addresses)
- Validation status and validator
- Result summary string (e.g., "53.6 MPa average compression")
- IPFS hash for verification

### Off-Chain Data (IPFS):
- Complete test reports with all specimens
- Test photos (before/after)
- Raw measurement data
- Lab certificates and calibration records
- Detailed analysis and calculations

### Example IPFS Structure:
```json
{
  "testId": 1,
  "testStandard": "ASTM C39",
  "testDate": "2024-10-12T09:00:00Z",
  "curingAge": 7,
  "laboratory": {
    "name": "Materials Testing Lab Inc.",
    "certificationNumber": "CERT-MTL-2024"
  },
  "specimens": [
    {
      "specimenId": "SPEC-001",
      "compressiveStrength": 53.6,
      "failureMode": "Cone and split",
      "images": {
        "before": "ipfs://QmSpecBefore001...",
        "after": "ipfs://QmSpecAfter001..."
      }
    }
  ],
  "summary": {
    "averageStrength": 53.6,
    "standardDeviation": 0.8
  }
}
```

---

## Workflow Example

```solidity
// 1. Contract owner authorizes lab
setLabAuthorization(labAddress, true);

// 2. Lab performs physical compression test at 7 days
// (Off-chain: Lab tests concrete, records results, uploads to IPFS)

// 3. Lab submits test result on-chain
uint256 testId = submitTestResult(
    passportId,
    TestType.Compression,
    "QmTestResultHash...",
    1696838400,  // Test date timestamp
    7,           // 7 days curing age
    "53.6 MPa average compression strength"
);

// 4. Another authorized lab validates the result
validateTestResult(testId, ValidationStatus.Validated);

// 5. Anyone can query the test results
TestResult memory result = getTestResult(testId);

// 6. Get all compression tests for a passport
TestResult[] memory compressionTests = getTestHistory(
    passportId,
    TestType.Compression,
    0  // All ages
);

// 7. Check lab statistics
(uint256 total, uint256 validated, uint256 rejected, uint256 pending) =
    getLabStatistics(labAddress);
```

---

## Security Features

1. **Authorization System** - Only approved labs can submit tests
2. **Peer Validation** - Labs cannot validate their own tests
3. **Immutability After Validation** - Tests cannot be changed after validation
4. **ReentrancyGuard** - Protection against reentrancy attacks
5. **Owner Controls** - Admin functions restricted to contract owner
6. **Event Logging** - All actions emit events for transparency

---

## Gas Optimization

- Uses `via_ir` compilation for stack depth optimization
- Storage pointers used in loops to reduce copies
- Separate helper function `_testMatches` to reduce stack depth
- Efficient array iteration with counting pass + building pass

---

## Integration with ConcretePassport.sol

### Relationship:
- **TestingRegistry** links to **ConcretePassport** via `passportId`
- Each test result references a passport token ID
- Multiple tests can be linked to one passport
- Tests track concrete performance over time (7-day, 28-day, etc.)

### Combined Workflow:
1. Create ConcretePassport NFT with formulation data
2. Add raw material hashes to passport
3. Set G-code hash for production
4. **Submit test results to TestingRegistry** (7-day tests)
5. **Submit more test results** (28-day tests)
6. Validate all test results
7. Finalize passport with final grade based on test data

---

## Next Steps

1. ✅ TestingRegistry.sol - Completed
2. ⏳ ManufacturingTracker.sol - Next contract
3. ⏳ DataMarketplace.sol - Future contract
4. ⏳ Integration tests for all contracts
5. ⏳ Frontend components for test submission/viewing
6. ⏳ Backend API for IPFS integration

---

## Compilation Status

✅ Successfully compiled with Solc 0.8.30
✅ Via-IR optimization enabled
✅ No syntax errors
✅ Ready for testing

---

This contract provides a robust, transparent, and secure system for managing concrete testing data on-chain while maintaining scientific rigor through peer validation and comprehensive audit trails.
