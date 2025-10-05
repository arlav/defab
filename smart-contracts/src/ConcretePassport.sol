// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// @dev Import OpenZeppelin's ERC721 implementation for NFT functionality
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// @dev Import URI storage extension to link tokens to IPFS metadata
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// @dev Import Ownable for contract ownership and admin functions
import "@openzeppelin/contracts/access/Ownable.sol";
// @dev Import ReentrancyGuard to prevent reentrancy attacks on state-changing functions
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ConcretePassport
 * @dev NFT-based digital passport system for tracking concrete formulations and their scientific data
 * @dev Each passport represents a unique concrete material with immutable creation data and updatable metadata
 */
contract ConcretePassport is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    // @dev Counter for generating unique token IDs, starts at 1
    uint256 private _tokenIdCounter;

    /**
     * @dev Structure containing all passport metadata for a concrete formulation and production
     * @param materialId Unique identifier for the concrete material (e.g., "MIX-001-2024")
     * @param ipfsHash Current IPFS content hash pointing to detailed formulation data package
     * @param creator Original address that minted this passport
     * @param createdAt Block timestamp of passport creation (immutable)
     * @param isActive Flag indicating if passport is active (can be deactivated by owner)
     * @param metadata Additional on-chain metadata string for search/filtering
     * @param rawMaterialHashes Array of cryptographic hashes for raw material batch certificates
     * @param gcodeHash Hash of the G-code file used for 3D printing (verifies design intent)
     * @param finalGrade Quality grade assigned after testing (e.g., "M20", "M30", "M40")
     * @param certificationHash Final certification hash that locks the production package
     * @param labAddress Address of the laboratory/facility that produced this concrete
     * @param isFinalized Flag indicating production is complete and certified (immutable after true)
     */
    struct PassportData {
        string materialId;              // @dev Human-readable material identifier
        string ipfsHash;                // @dev Main IPFS hash for off-chain data package (updatable)
        address creator;                // @dev Original creator address (immutable)
        uint256 createdAt;              // @dev Creation timestamp (immutable)
        bool isActive;                  // @dev Active status flag
        string metadata;                // @dev Additional searchable metadata
        string[] rawMaterialHashes;     // @dev Hashes of raw material certificates (cement, aggregates, admixtures)
        string gcodeHash;               // @dev Cryptographic hash of 3D print G-code file
        string finalGrade;              // @dev Quality grade (e.g., "M20", "M30") - set on finalization
        string certificationHash;       // @dev Final certification seal - locks entire package
        address labAddress;             // @dev Lab/facility that produced this element
        bool isFinalized;               // @dev Production complete & certified (prevents further changes)
    }

    // @dev Maps token ID to its passport data
    mapping(uint256 => PassportData) public passports;

    // @dev Maps material ID string to token ID for reverse lookup
    mapping(string => uint256) public materialIdToTokenId;

    // @dev Maps creator address to array of their passport token IDs
    mapping(address => uint256[]) public creatorPassports;

    // @dev Maps lab address to array of passports they produced
    mapping(address => uint256[]) public labPassports;

    // @dev Maps quality grade to array of passport token IDs (e.g., "M30" => [1,5,12])
    mapping(string => uint256[]) public gradeToPassports;

    // @dev Emitted when a new passport is created
    event PassportCreated(
        uint256 indexed tokenId,    // @dev The newly minted token ID
        string materialId,           // @dev Material identifier for the concrete
        address indexed creator,     // @dev Address of the passport creator
        string ipfsHash,             // @dev Initial IPFS hash for metadata
        uint256 timestamp            // @dev Block timestamp of creation
    );

    // @dev Emitted when passport data (IPFS hash) is updated
    event PassportUpdated(
        uint256 indexed tokenId,    // @dev Token ID being updated
        string newIpfsHash,          // @dev New IPFS hash replacing old data
        uint256 timestamp            // @dev Block timestamp of update
    );

    // @dev Emitted when a passport is deactivated by its owner
    event PassportDeactivated(
        uint256 indexed tokenId,    // @dev Token ID being deactivated
        uint256 timestamp            // @dev Block timestamp of deactivation
    );

    // @dev Emitted when raw material hashes are added to a passport
    event RawMaterialsAdded(
        uint256 indexed tokenId,    // @dev Token ID receiving material hashes
        uint256 materialCount,       // @dev Number of material hashes added
        uint256 timestamp            // @dev Block timestamp of addition
    );

    // @dev Emitted when G-code hash is set for a passport
    event GcodeHashSet(
        uint256 indexed tokenId,    // @dev Token ID receiving G-code hash
        string gcodeHash,            // @dev G-code file hash
        uint256 timestamp            // @dev Block timestamp
    );

    // @dev Emitted when a passport is finalized with grade and certification
    event PassportFinalized(
        uint256 indexed tokenId,    // @dev Token ID being finalized
        string finalGrade,           // @dev Quality grade assigned (e.g., "M30")
        string certificationHash,    // @dev Final certification seal
        address indexed labAddress,  // @dev Lab that certified this
        uint256 timestamp            // @dev Block timestamp of finalization
    );

    /**
     * @dev Modifier to check if a passport token exists
     * @param tokenId The token ID to verify
     */
    modifier passportExists(uint256 tokenId) {
        require(_ownerOf(tokenId) != address(0), "Passport does not exist");
        _;
    }

    /**
     * @dev Modifier to check if caller is the owner of the passport
     * @param tokenId The token ID to verify ownership
     */
    modifier onlyPassportOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not passport owner");
        _;
    }

    /**
     * @dev Modifier to check if passport is not yet finalized
     * @param tokenId The token ID to verify finalization status
     */
    modifier notFinalized(uint256 tokenId) {
        require(!passports[tokenId].isFinalized, "Passport already finalized");
        _;
    }

    /**
     * @dev Constructor initializes the ERC721 token with name and symbol
     * @param initialOwner Address that will own the contract (for admin functions)
     */
    constructor(address initialOwner)
        ERC721("ConcretePassport", "CPPT")  // @dev Token name: "ConcretePassport", Symbol: "CPPT"
        Ownable(initialOwner)
    {
        _tokenIdCounter = 1;  // @dev Start token IDs at 1 (0 is reserved for non-existent tokens)
    }

    /**
     * @dev Creates a new concrete passport NFT with associated metadata
     * @param materialId Unique identifier for the concrete material
     * @param ipfsHash IPFS content hash pointing to detailed formulation data
     * @param metadata Additional on-chain metadata for search/filtering
     * @param labAddress Address of the lab/facility producing this concrete (use address(0) if not applicable)
     * @return tokenId The newly minted token ID
     */
    function createPassport(
        string memory materialId,
        string memory ipfsHash,
        string memory metadata,
        address labAddress
    ) external nonReentrant returns (uint256) {
        // @dev Validate required inputs
        require(bytes(materialId).length > 0, "Material ID required");
        require(bytes(ipfsHash).length > 0, "IPFS hash required");
        // @dev Ensure material ID is unique across all passports
        require(materialIdToTokenId[materialId] == 0, "Material ID already exists");

        // @dev Get next token ID and increment counter
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        // @dev Mint NFT to caller's address with safety checks
        _safeMint(msg.sender, tokenId);

        // @dev Store passport data in storage with new production fields initialized empty
        passports[tokenId] = PassportData({
            materialId: materialId,
            ipfsHash: ipfsHash,
            creator: msg.sender,           // @dev Original creator is immutable
            createdAt: block.timestamp,    // @dev Creation time is immutable
            isActive: true,                // @dev New passports start as active
            metadata: metadata,
            rawMaterialHashes: new string[](0),  // @dev Initialize empty array
            gcodeHash: "",                 // @dev Set later during production
            finalGrade: "",                // @dev Set on finalization
            certificationHash: "",         // @dev Set on finalization
            labAddress: labAddress,        // @dev Lab address (can be zero)
            isFinalized: false             // @dev Not finalized until certified
        });

        // @dev Create reverse lookup from material ID to token ID
        materialIdToTokenId[materialId] = tokenId;
        // @dev Add to creator's passport list for easy querying
        creatorPassports[msg.sender].push(tokenId);

        // @dev Add to lab's passport list if lab address provided
        if (labAddress != address(0)) {
            labPassports[labAddress].push(tokenId);
        }

        // @dev Set token URI to IPFS hash for ERC721 metadata standard
        _setTokenURI(tokenId, ipfsHash);

        // @dev Emit creation event for off-chain indexing
        emit PassportCreated(tokenId, materialId, msg.sender, ipfsHash, block.timestamp);

        return tokenId;
    }

    /**
     * @dev Updates the IPFS hash for a passport (e.g., when adding new test data)
     * @dev Only the current owner can update, passport must be active and not finalized
     * @param tokenId The passport token ID to update
     * @param newIpfsHash New IPFS content hash replacing the old data
     */
    function updatePassportData(
        uint256 tokenId,
        string memory newIpfsHash
    ) external passportExists(tokenId) onlyPassportOwner(tokenId) notFinalized(tokenId) {
        // @dev Validate new IPFS hash is not empty
        require(bytes(newIpfsHash).length > 0, "IPFS hash required");
        // @dev Only allow updates on active passports
        require(passports[tokenId].isActive, "Passport is deactivated");

        // @dev Update stored IPFS hash
        passports[tokenId].ipfsHash = newIpfsHash;
        // @dev Update ERC721 token URI to match
        _setTokenURI(tokenId, newIpfsHash);

        // @dev Emit update event for off-chain tracking
        emit PassportUpdated(tokenId, newIpfsHash, block.timestamp);
    }

    /**
     * @dev Adds raw material certificate hashes to a passport
     * @dev Can be called multiple times to add materials incrementally
     * @param tokenId The passport token ID to update
     * @param materialHashes Array of cryptographic hashes for material certificates
     */
    function addRawMaterialHashes(
        uint256 tokenId,
        string[] memory materialHashes
    ) external passportExists(tokenId) onlyPassportOwner(tokenId) notFinalized(tokenId) {
        // @dev Validate at least one hash provided
        require(materialHashes.length > 0, "At least one hash required");
        require(passports[tokenId].isActive, "Passport is deactivated");

        // @dev Append new material hashes to existing array
        for (uint256 i = 0; i < materialHashes.length; i++) {
            require(bytes(materialHashes[i]).length > 0, "Empty hash not allowed");
            passports[tokenId].rawMaterialHashes.push(materialHashes[i]);
        }

        // @dev Emit event for tracking
        emit RawMaterialsAdded(tokenId, materialHashes.length, block.timestamp);
    }

    /**
     * @dev Sets the G-code file hash for a passport
     * @dev Can only be set once per passport
     * @param tokenId The passport token ID to update
     * @param gcodeHash Cryptographic hash of the G-code file
     */
    function setGcodeHash(
        uint256 tokenId,
        string memory gcodeHash
    ) external passportExists(tokenId) onlyPassportOwner(tokenId) notFinalized(tokenId) {
        // @dev Validate hash is not empty
        require(bytes(gcodeHash).length > 0, "G-code hash required");
        require(passports[tokenId].isActive, "Passport is deactivated");
        // @dev Prevent overwriting existing G-code hash
        require(bytes(passports[tokenId].gcodeHash).length == 0, "G-code hash already set");

        // @dev Set G-code hash
        passports[tokenId].gcodeHash = gcodeHash;

        // @dev Emit event for tracking
        emit GcodeHashSet(tokenId, gcodeHash, block.timestamp);
    }

    /**
     * @dev Finalizes a passport with quality grade and certification
     * @dev This is irreversible - passport cannot be modified after finalization
     * @param tokenId The passport token ID to finalize
     * @param finalGrade Quality grade (e.g., "M20", "M30", "M40")
     * @param certificationHash Final certification seal hash
     */
    function finalizePassport(
        uint256 tokenId,
        string memory finalGrade,
        string memory certificationHash
    ) external passportExists(tokenId) onlyPassportOwner(tokenId) notFinalized(tokenId) {
        // @dev Validate required inputs
        require(bytes(finalGrade).length > 0, "Final grade required");
        require(bytes(certificationHash).length > 0, "Certification hash required");
        require(passports[tokenId].isActive, "Passport is deactivated");

        // @dev Set final grade and certification
        passports[tokenId].finalGrade = finalGrade;
        passports[tokenId].certificationHash = certificationHash;
        passports[tokenId].isFinalized = true;

        // @dev Add to grade index for querying
        gradeToPassports[finalGrade].push(tokenId);

        // @dev Emit finalization event
        emit PassportFinalized(
            tokenId,
            finalGrade,
            certificationHash,
            passports[tokenId].labAddress,
            block.timestamp
        );
    }

    /**
     * @dev Deactivates a passport, preventing further updates
     * @dev Useful for marking deprecated or invalidated formulations
     * @param tokenId The passport token ID to deactivate
     */
    function deactivatePassport(uint256 tokenId)
        external
        passportExists(tokenId)
        onlyPassportOwner(tokenId)
    {
        // @dev Prevent double deactivation
        require(passports[tokenId].isActive, "Already deactivated");

        // @dev Set active flag to false (prevents future updates)
        passports[tokenId].isActive = false;

        // @dev Emit deactivation event for off-chain tracking
        emit PassportDeactivated(tokenId, block.timestamp);
    }

    /**
     * @dev Retrieves complete passport data for a given token ID
     * @param tokenId The passport token ID to query
     * @return PassportData Complete passport information struct
     */
    function getPassportInfo(uint256 tokenId)
        external
        view
        passportExists(tokenId)
        returns (PassportData memory)
    {
        return passports[tokenId];
    }

    /**
     * @dev Looks up passport by material ID instead of token ID
     * @param materialId The material identifier to search for
     * @return tokenId The token ID associated with this material
     * @return PassportData Complete passport information struct
     */
    function getPassportByMaterialId(string memory materialId)
        external
        view
        returns (uint256, PassportData memory)
    {
        // @dev Get token ID from reverse lookup mapping
        uint256 tokenId = materialIdToTokenId[materialId];
        // @dev Ensure material ID exists (tokenId 0 = not found)
        require(tokenId != 0, "Material ID not found");

        return (tokenId, passports[tokenId]);
    }

    /**
     * @dev Gets all passport token IDs created by a specific address
     * @param creator The address to query for created passports
     * @return Array of token IDs created by this address
     */
    function getCreatorPassports(address creator)
        external
        view
        returns (uint256[] memory)
    {
        return creatorPassports[creator];
    }

    /**
     * @dev Returns total number of passports minted
     * @return Total passport count
     */
    function getTotalPassports() external view returns (uint256) {
        // @dev Subtract 1 because counter starts at 1
        return _tokenIdCounter - 1;
    }

    /**
     * @dev Checks if a passport is currently active
     * @param tokenId The passport token ID to check
     * @return Boolean indicating active status
     */
    function isPassportActive(uint256 tokenId)
        external
        view
        passportExists(tokenId)
        returns (bool)
    {
        return passports[tokenId].isActive;
    }

    /**
     * @dev Gets all passport token IDs produced by a specific lab
     * @param lab The lab address to query
     * @return Array of token IDs produced by this lab
     */
    function getLabPassports(address lab)
        external
        view
        returns (uint256[] memory)
    {
        return labPassports[lab];
    }

    /**
     * @dev Gets all passport token IDs with a specific quality grade
     * @param grade The quality grade to query (e.g., "M20", "M30", "M40")
     * @return Array of token IDs with this grade
     */
    function getPassportsByGrade(string memory grade)
        external
        view
        returns (uint256[] memory)
    {
        return gradeToPassports[grade];
    }

    /**
     * @dev Gets the raw material hashes for a passport
     * @param tokenId The passport token ID to query
     * @return Array of raw material certificate hashes
     */
    function getRawMaterialHashes(uint256 tokenId)
        external
        view
        passportExists(tokenId)
        returns (string[] memory)
    {
        return passports[tokenId].rawMaterialHashes;
    }

    /**
     * @dev Checks if a passport has been finalized
     * @param tokenId The passport token ID to check
     * @return Boolean indicating finalization status
     */
    function isPassportFinalized(uint256 tokenId)
        external
        view
        passportExists(tokenId)
        returns (bool)
    {
        return passports[tokenId].isFinalized;
    }

    /**
     * @dev Gets production data summary for a passport
     * @param tokenId The passport token ID to query
     * @return gcodeHash G-code file hash
     * @return finalGrade Quality grade assigned
     * @return certificationHash Final certification seal
     * @return labAddress Lab that produced this
     * @return isFinalized Finalization status
     */
    function getProductionData(uint256 tokenId)
        external
        view
        passportExists(tokenId)
        returns (
            string memory gcodeHash,
            string memory finalGrade,
            string memory certificationHash,
            address labAddress,
            bool isFinalized
        )
    {
        PassportData memory passport = passports[tokenId];
        return (
            passport.gcodeHash,
            passport.finalGrade,
            passport.certificationHash,
            passport.labAddress,
            passport.isFinalized
        );
    }

    /**
     * @dev Overrides ERC721 transferFrom to update creator passport tracking
     * @dev Updates both sender and receiver's creatorPassports arrays
     * @param from Current owner address
     * @param to Recipient address
     * @param tokenId Token ID being transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) {
        // @dev Execute standard ERC721 transfer logic
        super.transferFrom(from, to, tokenId);

        // @dev Remove token from sender's creatorPassports array
        uint256[] storage fromPassports = creatorPassports[from];
        for (uint256 i = 0; i < fromPassports.length; i++) {
            if (fromPassports[i] == tokenId) {
                // @dev Swap with last element and pop (gas efficient removal)
                fromPassports[i] = fromPassports[fromPassports.length - 1];
                fromPassports.pop();
                break;
            }
        }

        // @dev Add token to recipient's creatorPassports array
        creatorPassports[to].push(tokenId);
    }

    /**
     * @dev Overrides ERC721 safeTransferFrom to update creator passport tracking
     * @dev Same as transferFrom but with safety checks for recipient contracts
     * @param from Current owner address
     * @param to Recipient address
     * @param tokenId Token ID being transferred
     * @param data Additional data to pass to recipient if it's a contract
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(IERC721, ERC721) {
        // @dev Execute standard ERC721 safe transfer logic
        super.safeTransferFrom(from, to, tokenId, data);

        // @dev Remove token from sender's creatorPassports array
        uint256[] storage fromPassports = creatorPassports[from];
        for (uint256 i = 0; i < fromPassports.length; i++) {
            if (fromPassports[i] == tokenId) {
                // @dev Swap with last element and pop (gas efficient removal)
                fromPassports[i] = fromPassports[fromPassports.length - 1];
                fromPassports.pop();
                break;
            }
        }

        // @dev Add token to recipient's creatorPassports array
        creatorPassports[to].push(tokenId);
    }

    /**
     * @dev Returns the token URI (IPFS hash) for a given token
     * @dev Overrides required for multiple inheritance (ERC721 + ERC721URIStorage)
     * @param tokenId Token ID to get URI for
     * @return IPFS URI string for the token metadata
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Returns true if this contract implements the interface defined by interfaceId
     * @dev Overrides required for multiple inheritance (ERC721 + ERC721URIStorage)
     * @param interfaceId The interface identifier to check
     * @return Boolean indicating interface support
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}