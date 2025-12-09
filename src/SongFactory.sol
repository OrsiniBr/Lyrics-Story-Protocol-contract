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

interface ILyricToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title SongFactory
 * @notice ONE-CLICK song registration for Web3 dApp:
 * 1. Mint NFT
 * 2. Register with Story Protocol
 * 3. Attach license (allows derivatives with royalty)
 * 4. Reward creator with LYRIC tokens
 * 
 * Users call this directly from their wallets and get instant rewards!
 */
contract SongFactory is Ownable, ReentrancyGuard {
    ISongNFT public songNFT;
    IStoryProtocol public storyRegistry;
    ILicensing public licensing;
    ILyricToken public lyricToken;
    
    address public licenseTemplate;
    uint256 public licenseTermsId;
    
    // Reward amount for creating a song (adjustable by owner)
    uint256 public songCreationReward = 10 * 10**18; // 10 LYRIC tokens
    
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
        address creator,
        uint256 rewardAmount
    );
    
    event RewardUpdated(uint256 newReward);
    
    constructor(address _songNFT, address _lyricToken) Ownable(msg.sender) {
        songNFT = ISongNFT(_songNFT);
        lyricToken = ILyricToken(_lyricToken);
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
     * @dev Update song creation reward amount
     * @param newReward New reward amount in wei (e.g., 50 * 10**18 = 50 tokens)
     */
    function updateSongCreationReward(uint256 newReward) external onlyOwner {
        require(newReward > 0 && newReward <= 50 * 10**18, "Reward must be 1-50 tokens");
        songCreationReward = newReward;
        emit RewardUpdated(newReward);
    }
    
    /**
     * @dev Register a new song (ANYONE can call this for themselves)
     * @param songId Unique ID for the song
     * @param metadataURI IPFS URI with song metadata
     * 
     * User gets instant LYRIC token reward!
     */
    function registerSong(
        uint256 songId,
        string calldata metadataURI
    ) external nonReentrant returns (uint256 tokenId, address ipId) {
        require(songs[songId].timestamp == 0, "Song already registered");
        
        address creator = msg.sender;
        
        // 1. Mint NFT to caller
        tokenId = songNFT.mint(creator, songId, metadataURI);
        
        // 2. Register with Story Protocol
        ipId = storyRegistry.register(block.chainid, address(songNFT), tokenId);
        
        // 3. Attach license (allows derivatives with 15% royalty)
        licensing.attachLicenseTerms(ipId, licenseTemplate, licenseTermsId);
        
        // 4. Store song data
        songs[songId] = Song({
            tokenId: tokenId,
            ipId: ipId,
            creator: creator,
            timestamp: block.timestamp
        });
        
        // 5. Reward creator with LYRIC tokens
        uint256 contractBalance = lyricToken.balanceOf(address(this));
        if (contractBalance >= songCreationReward) {
            require(
                lyricToken.transfer(creator, songCreationReward),
                "Reward transfer failed"
            );
        }
        
        emit SongRegistered(songId, tokenId, ipId, creator, songCreationReward);
        
        return (tokenId, ipId);
    }
    
    /**
     * @dev Get song details
     */
    function getSong(uint256 songId) external view returns (Song memory) {
        require(songs[songId].timestamp != 0, "Song not found");
        return songs[songId];
    }
    
    /**
     * @dev Check contract's LYRIC token balance (for monitoring)
     */
    function getRewardBalance() external view returns (uint256) {
        return lyricToken.balanceOf(address(this));
    }
    
    /**
     * @dev Owner can withdraw LYRIC tokens if needed
     */
    function withdrawTokens(uint256 amount) external onlyOwner {
        require(lyricToken.transfer(owner(), amount), "Withdraw failed");
    }
    
    /**
     * @dev Owner can deposit LYRIC tokens to fund rewards
     */
    function fundRewards(uint256 amount) external {
        require(
            lyricToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
    }
}