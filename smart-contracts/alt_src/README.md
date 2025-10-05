# Alternative Smart Contract Architecture

This directory contains an alternative smart contract architecture extracted from `DeSci_DeFab.md`.

## Contracts

### 1. ProductionPassportNFT.sol
**Purpose:** Core NFT-based production passport system

**Key Features:**
- ERC-721 NFT for each production run
- IPFS manifest hash storage
- Version control for data updates
- Finalization with quality grade assignment
- Data integrity verification

**Main Functions:**
- `createPassport(packageId, materialId, ipfsHash)` - Mint new production passport
- `updatePassportData(tokenId, newIpfsHash)` - Update manifest (before finalization)
- `finalizePassport(tokenId, certHash, grade)` - Lock passport with final grade
- `getPassportInfo(tokenId)` - Retrieve passport details
- `verifyDataIntegrity(tokenId, hash)` - Verify certification hash

### 2. ValidationRegistry.sol
**Purpose:** Manages authorized validators and validation records

**Key Features:**
- Validator registration with credentials
- Multi-validator consensus (3 required validations)
- Reputation scoring system (0-1000)
- IPFS-stored validation reports
- Digital signature support

**Main Functions:**
- `registerValidator(orgName, certNumber)` - Register as validator
- `submitValidation(tokenId, passed, reportHash, signature)` - Submit validation
- `getValidationStatus(tokenId)` - Get validation counts
- `isFullyValidated(tokenId)` - Check if passport has 3+ validations

### 3. DataProvenance.sol
**Purpose:** Track complete chain of custody for materials and processes

**Key Features:**
- Material batch certification tracking
- Process event recording (mixing, printing, testing)
- Operator and timestamp tracking
- Parameter hash verification

**Main Functions:**
- `addMaterialBatch(tokenId, batchNum, type, supplier, certHash, expiry)` - Record material
- `recordProcessEvent(tokenId, eventType, ipfsHash, paramsHash)` - Log process step
- `getProcessHistory(tokenId)` - Retrieve complete event history

## Comparison with Main Contracts (`../src/`)

| Feature | Main (`src/`) | Alternative (`alt_src/`) |
|---------|--------------|-------------------------|
| **Focus** | Testing & Manufacturing | Validation & Provenance |
| **Passport Contract** | ConcretePassport.sol | ProductionPassportNFT.sol |
| **Validation** | TestingRegistry.sol (lab-focused) | ValidationRegistry.sol (multi-validator) |
| **Tracking** | ManufacturingTracker.sol | DataProvenance.sol |
| **Marketplace** | DataMarketplace.sol | Not included (Phase 2) |
| **Governance** | Not included | GovernanceToken.sol (planned) |

## Key Architectural Differences

**Main Architecture (CLAUDE.md):**
- 4 contracts: ConcretePassport, TestingRegistry, ManufacturingTracker, DataMarketplace
- Focuses on testing workflows and manufacturing tracking
- Includes immediate marketplace functionality
- Lab authorization model

**Alternative Architecture (DeSci_DeFab.md):**
- 4 contracts: ProductionPassportNFT, ValidationRegistry, DataProvenance, GovernanceToken
- Focuses on decentralized validation and provenance
- Multi-validator consensus model
- Planned governance token for DeSci ecosystem
- Emphasizes chain-of-custody and material traceability

## Integration Notes

Both architectures can potentially be merged:
- Use **ProductionPassportNFT** as the core (more feature-rich than ConcretePassport)
- Combine **ValidationRegistry** + **TestingRegistry** for comprehensive validation
- Keep **DataProvenance** for material tracking
- Keep **ManufacturingTracker** for process tracking
- Keep **DataMarketplace** for commercial functionality
- Add **GovernanceToken** for Phase 2 DeSci features

## Deployment Status

⚠️ **These contracts are reference implementations only**

For active development, see:
- `/src/ConcretePassport.sol` (deployed and tested)
- `/src/TestingRegistry.sol` (deployed and tested)

## Next Steps

1. Review both architectures with stakeholders
2. Decide on unified contract architecture
3. Merge best features from both approaches
4. Update deployment scripts accordingly
5. Conduct comprehensive testing

---

**Reference:** See `DeSci_DeFab.md` Section 2 for full architectural context.
