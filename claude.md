# DeSci DeFab: Phase 1 Implementation Plan

## Project Overview
**DeSci: Decentralized Scientific Data Passport System for 3D Concrete**

A blockchain-based system for tracking, verifying, and managing scientific data related to 3D concrete printing and fabrication processes. This system creates immutable data passports for concrete formulations, testing results, and manufacturing processes.

## Phase 1 Goals
- Deploy 4 core smart contracts
- Build web frontend with IPFS integration
- Use web3.py for backend interactions
- Deploy on free testnet infrastructure

---

## Smart Contract Architecture (4 Contracts)

### 1. **ConcretePassport.sol**
```solidity
// Core identity and metadata contract
Contract Functions:
- createPassport(materialId, ipfsHash, metadata)
- updatePassportData(passportId, newIpfsHash)
- getPassportInfo(passportId)
- transferOwnership(passportId, newOwner)
```

**Purpose**: Creates unique digital identities for concrete formulations
**Key Features**:
- ERC-721 based NFT passport system
- Links to IPFS metadata (formulation, properties)
- Ownership and transfer capabilities
- Immutable creation timestamp and creator

### 2. **TestingRegistry.sol**
```solidity
// Scientific testing and validation
Contract Functions:
- submitTestResults(passportId, testType, ipfsDataHash, labAddress)
- validateTestResults(resultId, validatorAddress)
- getTestHistory(passportId)
- addAuthorizedLab(labAddress)
```

**Purpose**: Records and validates concrete testing data
**Key Features**:
- Links test results to concrete passports
- Authorized laboratory system
- Peer validation mechanism
- Historical test data tracking

### 3. **ManufacturingTracker.sol**
```solidity
// Production and fabrication tracking
Contract Functions:
- recordManufacturingEvent(passportId, processData, location, operator)
- addQualityCheck(eventId, checkType, result, inspector)
- getManufacturingHistory(passportId)
- certifyProcess(eventId, certifierAddress)
```

**Purpose**: Tracks 3D printing and manufacturing processes
**Key Features**:
- Process parameter recording
- Quality checkpoint system
- Location and operator tracking
- Process certification

### 4. **DataMarketplace.sol**
```solidity
// Data licensing and access control
Contract Functions:
- listDataForLicense(passportId, price, licenseTerms)
- purchaseDataAccess(listingId)
- grantAccess(buyerAddress, passportId, duration)
- withdrawEarnings()
```

**Purpose**: Monetize and control access to concrete data
**Key Features**:
- Data licensing marketplace
- Access control and permissions
- Revenue sharing for data owners
- Temporary access grants

---

## Frontend Architecture

### Technology Stack
- **Framework**: React with TypeScript
- **Blockchain**: web3.py backend API + REST endpoints
- **Storage**: IPFS via Pinata or Infura
- **Styling**: Tailwind CSS
- **State Management**: Zustand
- **Wallet**: MetaMask integration

### Frontend Structure
```
src/
├── components/
│   ├── passport/
│   │   ├── PassportCreator.tsx
│   │   ├── PassportViewer.tsx
│   │   └── PassportList.tsx
│   ├── testing/
│   │   ├── TestResultUpload.tsx
│   │   ├── TestHistory.tsx
│   │   └── LabVerification.tsx
│   ├── manufacturing/
│   │   ├── ProcessRecorder.tsx
│   │   ├── QualityChecker.tsx
│   │   └── ManufacturingDashboard.tsx
│   ├── marketplace/
│   │   ├── DataListings.tsx
│   │   ├── PurchaseInterface.tsx
│   │   └── EarningsDashboard.tsx
│   └── common/
│       ├── WalletConnector.tsx
│       ├── IPFSUploader.tsx
│       └── TransactionStatus.tsx
├── services/
│   ├── web3Service.ts
│   ├── ipfsService.ts
│   └── apiService.ts
├── stores/
│   ├── walletStore.ts
│   ├── passportStore.ts
│   └── userStore.ts
└── types/
    ├── contracts.ts
    ├── passport.ts
    └── testing.ts
```

### Key Frontend Features
1. **Passport Creation Wizard**: Step-by-step concrete formulation entry
2. **Scientific Data Uploader**: IPFS integration for test results and documents
3. **Real-time Manufacturing Tracker**: Live process monitoring dashboard
4. **Data Marketplace**: Browse and purchase concrete data
5. **Wallet Integration**: MetaMask connection and transaction management

---

## Backend API (web3.py)

### Python Backend Structure
```
backend/
├── app/
│   ├── contracts/
│   │   ├── concrete_passport.py
│   │   ├── testing_registry.py
│   │   ├── manufacturing_tracker.py
│   │   └── data_marketplace.py
│   ├── services/
│   │   ├── web3_service.py
│   │   ├── ipfs_service.py
│   │   └── validation_service.py
│   ├── api/
│   │   ├── passport_routes.py
│   │   ├── testing_routes.py
│   │   ├── manufacturing_routes.py
│   │   └── marketplace_routes.py
│   └── models/
│       ├── passport_model.py
│       └── test_result_model.py
├── requirements.txt
└── config.py
```

### Web3.py Integration
```python
# Example service structure
class ConcretePassportService:
    def __init__(self, web3_provider, contract_address, private_key):
        self.w3 = Web3(Web3.HTTPProvider(web3_provider))
        self.contract = self.w3.eth.contract(address=contract_address, abi=CONTRACT_ABI)
        self.account = self.w3.eth.account.from_key(private_key)

    def create_passport(self, material_id, ipfs_hash, metadata):
        # Smart contract interaction logic

    def get_passport_data(self, passport_id):
        # Retrieve passport information
```

---

## IPFS Integration Strategy

### Data Storage Architecture

Based on the 13-point DeSci Data Package Passport, our IPFS structure separates on-chain verification hashes from off-chain bulk data:

```
ipfs://QmMainManifest/
├── manifest.json                           # Main manifest with all sub-hashes
├── /raw-materials/
│   ├── material-001-certificate.json       # Cement batch certificate
│   ├── material-002-certificate.json       # Aggregate batch certificate
│   ├── material-003-certificate.json       # Admixture batch certificate
│   └── supplier-certifications.pdf         # Supporting documents
├── /formulation/
│   ├── mix-design.json                     # Target mix design (#3)
│   ├── rheological-properties.json         # Target rheology specs (#4)
│   └── formulation-metadata.json           # Additional specs
├── /production/
│   ├── gcode-file.gcode                    # Full G-code file (#5)
│   ├── gcode-metadata.json                 # G-code analysis
│   ├── environmental-targets.json          # Target ambient conditions (#6)
│   └── production-plan.json                # Process planning data
├── /process-data/
│   ├── sensor-data/
│   │   ├── pressure-timeseries.json        # Time-series pressure data (#7)
│   │   ├── flow-rate-timeseries.json       # Flow rate measurements (#7)
│   │   ├── rheology-inline.json            # In-line rheometer data (#7)
│   │   └── environmental-actual.json       # Actual temp/humidity (#7)
│   ├── vision-data/
│   │   ├── layer-images/                   # Per-layer photos (#8)
│   │   ├── scan-data/                      # 3D scan point clouds (#8)
│   │   ├── deviation-heatmaps/             # Quality deviation maps (#8)
│   │   └── vision-summary.json             # Vision analysis summary
│   └── mllm-logs/
│       ├── prompts/                        # mLLM prompts by timestamp (#9)
│       ├── responses/                      # mLLM JSON responses (#9)
│       └── compensatory-gcode/             # AI-generated corrections (#10)
├── /testing/
│   ├── mechanical-tests/
│   │   ├── compression-test-results.json   # ASTM C39 compression (#11)
│   │   ├── flexural-test-results.json      # Flexural strength (#11)
│   │   ├── tensile-test-results.json       # Tensile strength (#11)
│   │   └── test-specimen-photos/
│   ├── non-destructive/
│   │   ├── ultrasonic-tests.json
│   │   ├── rebound-hammer.json
│   │   └── ndt-images/
│   └── test-reports/
│       ├── lab-report-final.pdf
│       ├── astm-compliance-docs.pdf
│       └── quality-certification.pdf
└── /certification/
    ├── final-grade-report.json             # Grade assignment details (#12)
    ├── certification-metadata.json         # Certification context (#13)
    ├── inspector-signatures.json           # Digital signatures
    └── compliance-documents/
        ├── building-code-compliance.pdf
        └── structural-certification.pdf
```

### On-Chain vs Off-Chain Data Split

**On-Chain (Smart Contract):**
- Production Package ID (Token ID) → `#1`
- Raw Material Hashes → `#2`
- G-code Hash → `#5`
- Final Quality Grade → `#12`
- Final Certification Hash → `#13`
- Lab Address & Timestamps
- Finalization Status

**Off-Chain (IPFS):**
- Mix Design → `#3`
- Rheological Properties → `#4`
- Environmental Targets → `#6`
- Sensor Time-Series Data → `#7`
- Vision & Scan Data → `#8`
- mLLM Logs → `#9`
- Compensatory G-code → `#10`
- Mechanical Test Results → `#11`

### Key JSON Schemas

#### Main Manifest (`manifest.json`)
```json
{
  "version": "1.0.0",
  "packageId": "PROD-2024-001",
  "materialId": "MIX-001-2024",
  "createdAt": "2024-10-05T12:00:00Z",
  "labPublicKey": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "dataPackageType": "3D-Concrete-Production",
  "ipfsHashes": {
    "rawMaterials": { "material001": "QmHash1...", "material002": "QmHash2..." },
    "formulation": { "mixDesign": "QmHash4...", "rheology": "QmHash5..." },
    "production": { "gcode": "QmHash6...", "environmentalTargets": "QmHash7..." },
    "processData": { "sensorData": "QmHash8...", "visionData": "QmHash9...", "mllmLogs": "QmHash10..." },
    "testing": { "mechanicalTests": "QmHash11...", "finalReports": "QmHash12..." },
    "certification": { "finalGrade": "QmHash13...", "certificationDocs": "QmHash14..." }
  },
  "cryptographicProofs": {
    "manifestHash": "0xabcdef...",
    "gcodeHash": "0x123456...",
    "certificationHash": "0x789abc..."
  }
}
```

#### Sensor Time-Series Data Example
```json
{
  "sensor": { "type": "Pressure Transducer", "model": "Omega PX409-030GI", "location": "Extruder Inlet" },
  "dataPoints": [
    { "timestamp": "2024-10-05T10:00:00.000Z", "value": 1.45, "quality": "good" },
    { "timestamp": "2024-10-05T10:00:00.100Z", "value": 1.47, "quality": "good" }
  ],
  "statistics": { "mean": 1.52, "stdDev": 0.08, "outOfSpecCount": 3 }
}
```

#### mLLM Prompt/Response Example
```json
{
  "timestamp": "2024-10-05T12:00:00.000Z",
  "prompt": {
    "type": "defect-analysis",
    "context": "Layer 23 - Bead deformation detected",
    "inputs": { "visionImage": "ipfs://QmLayerImage023...", "sensorData": {...} }
  },
  "response": {
    "diagnosis": "Material flow inconsistency due to ambient temperature increase",
    "recommendations": { "immediate": ["Reduce print speed by 15%"], "compensatoryGcode": ["M220 S85"] }
  }
}
```

### IPFS Services
1. **Pinata**: Free tier (1GB storage) for development
2. **Infura IPFS**: Reliable gateway and pinning service
3. **Local IPFS Node**: For testing and development

### IPFS Pinning Strategy

**Critical Data (Always Pin):**
- Main manifest
- Material certificates
- Mix design & rheology specs
- G-code metadata
- Final test results
- Certification documents

**Optional Pinning:**
- Full sensor time-series (archive after 2 years)
- Layer images (archive after 1 year)
- 3D scan data (on-demand retrieval)

### Implementation
```python
import ipfshttpclient
import json
import hashlib

class DeSciIPFSService:
    def __init__(self, ipfs_endpoint='/dns/localhost/tcp/5001/http'):
        self.client = ipfshttpclient.connect(ipfs_endpoint)

    def upload_manifest(self, production_data):
        """Upload complete production data package"""
        manifest = self._create_manifest(production_data)
        manifest_hash = self.client.add_json(manifest)
        return manifest_hash

    def upload_sensor_data(self, sensor_readings):
        """Upload time-series sensor data"""
        return self.client.add_json(sensor_readings)

    def upload_file(self, file_path):
        """Upload binary file (images, PDFs, G-code)"""
        return self.client.add(file_path)

    def get_manifest(self, ipfs_hash):
        """Retrieve manifest from IPFS"""
        return self.client.get_json(ipfs_hash)

    def verify_hash(self, ipfs_hash, expected_hash):
        """Verify data integrity against on-chain hash"""
        data = self.client.cat(ipfs_hash)
        actual_hash = hashlib.sha256(data).hexdigest()
        return actual_hash == expected_hash

    def pin_critical_data(self, ipfs_hash):
        """Pin critical data permanently"""
        return self.client.pin.add(ipfs_hash)

    def _create_manifest(self, production_data):
        """Create manifest JSON with all IPFS hashes"""
        return {
            "version": "1.0.0",
            "packageId": production_data.get("packageId"),
            "materialId": production_data.get("materialId"),
            "ipfsHashes": production_data.get("ipfsHashes"),
            "cryptographicProofs": production_data.get("cryptographicProofs")
        }
```

### File Size Estimates

| Data Type | Size | Storage Strategy |
|-----------|------|------------------|
| Manifest JSON | 5-10 KB | IPFS (pinned) |
| Material Certificates | 10-50 KB each | IPFS (pinned) |
| Sensor Time-Series | 500 KB - 5 MB each | IPFS (optional) |
| Layer Images | 200 KB - 2 MB each | IPFS (optional) |
| 3D Scans | 5-50 MB each | IPFS (optional) |
| mLLM Logs | 1-10 MB total | IPFS (pinned) |
| Test Reports | 1-5 MB | IPFS (pinned) |

**Total Package Size:** 100-500 MB per production run

---

## Free Hosting & Deployment Strategy

### Blockchain Networks (Free)
1. **Polygon Mumbai** (Recommended)
   - Free testnet MATIC from faucet
   - Low gas fees
   - Ethereum compatibility
   - Good tooling support

2. **Goerli Ethereum Testnet**
   - Free ETH from faucets
   - Full Ethereum compatibility
   - Extensive tooling

3. **Avalanche Fuji Testnet**
   - Fast transactions
   - Low fees
   - Good for testing

### Frontend Hosting
1. **Vercel** (Recommended)
   - Free tier: unlimited static sites
   - Git integration
   - Custom domains
   - Automatic deployments

2. **Netlify**
   - Free tier: 100GB bandwidth
   - Form handling
   - Serverless functions

### Backend API Hosting
1. **Railway** (Recommended)
   - Free tier: 500 hours/month
   - Supports Python/Flask
   - Database included
   - Easy deployment

2. **Render**
   - Free tier with limitations
   - Auto-deploy from Git
   - Supports web3.py

### IPFS Hosting
1. **Pinata** (Free Tier)
   - 1GB storage
   - 100GB bandwidth
   - Easy API integration

2. **Infura IPFS**
   - Free tier available
   - Reliable gateways
   - Good for production

---

## Development Roadmap

### Week 1-2: Smart Contract Development
- [ ] Set up development environment (Hardhat/Foundry)
- [ ] Implement ConcretePassport.sol
- [ ] Implement TestingRegistry.sol
- [ ] Write comprehensive tests
- [ ] Deploy to Mumbai testnet

### Week 3-4: Backend API
- [ ] Set up Flask/FastAPI backend
- [ ] Implement web3.py services
- [ ] Create REST API endpoints
- [ ] Set up IPFS integration
- [ ] Deploy to Railway

### Week 5-6: Frontend Development
- [ ] Set up React TypeScript project
- [ ] Implement wallet connection
- [ ] Create passport creation flow
- [ ] Build testing data interface
- [ ] Deploy to Vercel

### Week 7-8: Integration & Testing
- [ ] Connect frontend to backend
- [ ] End-to-end testing
- [ ] User experience optimization
- [ ] Documentation
- [ ] Final deployment

---

## Cost Estimates (Free Tier Limits)

### Monthly Costs (Free Tiers)
- **Blockchain**: $0 (testnets)
- **Frontend Hosting**: $0 (Vercel free tier)
- **Backend Hosting**: $0 (Railway free tier - 500 hours)
- **IPFS Storage**: $0 (Pinata 1GB free)
- **Total Monthly Cost**: $0

### Scaling Considerations
- When ready for mainnet: ~$50-100/month
- Production IPFS: ~$20-50/month
- Backend scaling: ~$25-75/month

---

## Security Considerations

### Smart Contract Security
- Use OpenZeppelin libraries
- Implement access controls
- Add reentrancy guards
- Comprehensive testing
- Consider audit for mainnet

### Data Protection
- IPFS content addressing (immutable)
- Private data encryption before upload
- Access control through smart contracts
- Secure API key management

### Frontend Security
- Input validation and sanitization
- Secure wallet integration
- HTTPS enforcement
- CSP headers

This plan provides a comprehensive roadmap for building the DeSci concrete data passport system using free infrastructure while maintaining professional development standards.