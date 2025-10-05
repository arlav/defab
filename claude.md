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
```
IPFS Structure:
├── /concrete-formulations/
│   ├── material-composition.json
│   ├── mixing-ratios.json
│   └── additive-specifications.json
├── /test-results/
│   ├── compression-tests/
│   ├── tensile-strength/
│   └── durability-studies/
├── /manufacturing-data/
│   ├── 3d-printing-parameters/
│   ├── environmental-conditions/
│   └── quality-images/
└── /certifications/
    ├── lab-reports.pdf
    ├── compliance-docs.pdf
    └── inspection-photos/
```

### IPFS Services
1. **Pinata**: Free tier (1GB storage) for development
2. **Infura IPFS**: Reliable gateway and pinning service
3. **Local IPFS Node**: For testing and development

### Implementation
```python
import ipfshttpclient

class IPFSService:
    def __init__(self):
        self.client = ipfshttpclient.connect('/dns/localhost/tcp/5001/http')

    def upload_json(self, data):
        return self.client.add_json(data)

    def upload_file(self, file_path):
        return self.client.add(file_path)

    def get_data(self, ipfs_hash):
        return self.client.get_json(ipfs_hash)
```

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