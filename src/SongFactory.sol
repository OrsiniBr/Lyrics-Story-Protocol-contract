// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ISongNFT {
    function mint(address to, uint256 songId, string memory uri) external returns (uint256);
}

interface IStoryProtocol {
    function register(uint256 chainId, address tokenContract, uint256 tokenId) 
        external returns (address ipId);
}

interface ILicensing {
    function attachLicenseTerms(address ipId, address licenseTemplate, uint256 licenseTermsId) 
        external;
}

/**
 * @title SongFactory
 * @notice ONE-CLICK song registration:
 * 1. Mint NFT
 * 2. Register with Story Protocol
 * 3. Attach license (allows derivatives with royalty)
 */
contract SongFactory is Ownable, ReentrancyGuard {
    ISongNFT public songNFT;
    IStoryProtocol public storyRegistry;
    ILicensing public licensing;
    
    address public licenseTemplate;
    uint256 public licenseTermsId;
    address public backend; // Your backend wallet
    
    struct Song {
        uint256 tokenId;
        address ipId;
        address creator;
        uint256 timestamp;
    }
    
    mapping(uint256 => Song) public songs; // songId => Song
    
    event SongRegistered(
        uint256 indexed songId,
        uint256 tokenId,
        address ipId,
        address creator
    );
    
    constructor(address _songNFT, address _backend) Ownable(msg.sender) {
        songNFT = ISongNFT(_songNFT);
        backend = _backend;
    }
    
    modifier onlyBackend() {
        require(msg.sender == backend || msg.sender == owner(), "Not authorized");
        _;
    }
    
    function setBackend(address _backend) external onlyOwner {
        backend = _backend;
    }
    
    /**
     * @dev Initialize Story Protocol contracts
     */
    function initStoryProtocol(
        address _storyRegistry,
        address _licensing,
        address _licenseTemplate,
        uint256 _licenseTermsId
    ) external onlyOwner {
        storyRegistry = IStoryProtocol(_storyRegistry);
        licensing = ILicensing(_licensing);
        licenseTemplate = _licenseTemplate;
        licenseTermsId = _licenseTermsId;
    }
    
    /**
     * @dev Register a new song (backend calls this)
     * @param creator User's wallet
     * @param songId Your database ID
     * @param metadataURI IPFS URI
     */
    function registerSong(
        address creator,
        uint256 songId,
        string calldata metadataURI
    ) external onlyBackend nonReentrant returns (uint256 tokenId, address ipId) {
        require(songs[songId].timestamp == 0, "Song exists");
        
        // 1. Mint NFT
        tokenId = songNFT.mint(creator, songId, metadataURI);
        
        // 2. Register with Story Protocol
        ipId = storyRegistry.register(block.chainid, address(songNFT), tokenId);
        
        // 3. Attach license
        licensing.attachLicenseTerms(ipId, licenseTemplate, licenseTermsId);
        
        // Store
        songs[songId] = Song({
            tokenId: tokenId,
            ipId: ipId,
            creator: creator,
            timestamp: block.timestamp
        });
        
        emit SongRegistered(songId, tokenId, ipId, creator);
        
        return (tokenId, ipId);
    }
    
    function getSong(uint256 songId) external view returns (Song memory) {
        return songs[songId];
    }
}