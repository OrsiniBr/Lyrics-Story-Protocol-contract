// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ISongFactory {
    function registerSong(uint256 songId, string calldata metadataURI) 
        external returns (uint256 tokenId, address ipId);
    
    function getSong(uint256 songId) external view returns (
        uint256 tokenId,
        address ipId,
        address creator,
        uint256 timestamp
    );
}

interface IStoryDerivative {
    function makeDerivative(
        address childIpId,
        address[] calldata parentIpIds,
        address licenseTemplate,
        uint256 licenseTermsId
    ) external;
}

interface ILyricToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title DerivativeFactory
 * @notice Creates remixes/derivatives and links them to parent songs
 * Story Protocol enforces the 15% royalty automatically
 * Users get instant LYRIC token rewards for creating derivatives!
 */
contract DerivativeFactory is Ownable, ReentrancyGuard {
    ISongFactory public songFactory;
    IStoryDerivative public storyDerivative;
    ILyricToken public lyricToken;
    
    address public licenseTemplate;
    uint256 public licenseTermsId;
    
    uint16 public constant ROYALTY_PERCENTAGE = 15; // 15%
    
    // Reward amount for creating a derivative (adjustable by owner)
    uint256 public derivativeCreationReward = 10 * 10**18; // 10 LYRIC tokens
    
    struct Derivative {
        uint256 parentSongId;
        uint256 childSongId;
        address parentIpId;
        address childIpId;
        string derivativeType;
        uint256 timestamp;
    }
    
    mapping(uint256 => Derivative) public derivatives; // childSongId => Derivative
    mapping(uint256 => uint256[]) public childrenOf; // parentSongId => childSongIds[]
    
    event DerivativeCreated(
        uint256 indexed parentSongId,
        uint256 indexed childSongId,
        address parentIpId,
        address childIpId,
        address creator,
        string derivativeType,
        uint256 rewardAmount
    );
    
    event RewardUpdated(uint256 newReward);
    
    constructor(address _songFactory, address _lyricToken) Ownable(msg.sender) {
        songFactory = ISongFactory(_songFactory);
        lyricToken = ILyricToken(_lyricToken);
    }
    
    function initStoryProtocol(
        address _storyDerivative,
        address _licenseTemplate,
        uint256 _licenseTermsId
    ) external onlyOwner {
        storyDerivative = IStoryDerivative(_storyDerivative);
        licenseTemplate = _licenseTemplate;
        licenseTermsId = _licenseTermsId;
    }
    
    /**
     * @dev Update derivative creation reward amount
     * @param newReward New reward amount in wei
     */
    function updateDerivativeCreationReward(uint256 newReward) external onlyOwner {
        require(newReward > 0 && newReward <= 50 * 10**18, "Reward must be 1-50 tokens");
        derivativeCreationReward = newReward;
        emit RewardUpdated(newReward);
    }
    
    /**
     * @dev Create a derivative/remix (ANYONE can call this)
     * @param parentSongId Original song ID
     * @param childSongId New derivative song ID (must be unique)
     * @param metadataURI IPFS URI for derivative metadata
     * @param derivativeType "Spanish", "Lofi", "Remix", etc.
     * 
     * User gets instant LYRIC token reward!
     * Original creator automatically gets 15% royalty via Story Protocol
     */
    function createDerivative(
        uint256 parentSongId,
        uint256 childSongId,
        string calldata metadataURI,
        string calldata derivativeType
    ) external nonReentrant returns (uint256 childTokenId, address childIpId) {
        require(derivatives[childSongId].timestamp == 0, "Derivative already exists");
        
        address creator = msg.sender;
        
        // 1. Get parent song info
        (,address parentIpId,,) = songFactory.getSong(parentSongId);
        require(parentIpId != address(0), "Parent song not found");
        
        // 2. Register derivative as new song
        (childTokenId, childIpId) = songFactory.registerSong(childSongId, metadataURI);
        
        // 3. Link to parent via Story Protocol
        address[] memory parents = new address[](1);
        parents[0] = parentIpId;
        
        storyDerivative.makeDerivative(
            childIpId,
            parents,
            licenseTemplate,
            licenseTermsId
        );
        
        // 4. Store derivative relationship
        derivatives[childSongId] = Derivative({
            parentSongId: parentSongId,
            childSongId: childSongId,
            parentIpId: parentIpId,
            childIpId: childIpId,
            derivativeType: derivativeType,
            timestamp: block.timestamp
        });
        
        childrenOf[parentSongId].push(childSongId);
        
        // 5. Reward creator with LYRIC tokens
        uint256 contractBalance = lyricToken.balanceOf(address(this));
        if (contractBalance >= derivativeCreationReward) {
            require(
                lyricToken.transfer(creator, derivativeCreationReward),
                "Reward transfer failed"
            );
        }
        
        emit DerivativeCreated(
            parentSongId, 
            childSongId, 
            parentIpId, 
            childIpId, 
            creator,
            derivativeType,
            derivativeCreationReward
        );
        
        return (childTokenId, childIpId);
    }
    
    /**
     * @dev Get all derivatives of a parent song
     */
    function getDerivatives(uint256 parentSongId) external view returns (uint256[] memory) {
        return childrenOf[parentSongId];
    }
    
    /**
     * @dev Get derivative info
     */
    function getDerivativeInfo(uint256 childSongId) external view returns (Derivative memory) {
        require(derivatives[childSongId].timestamp != 0, "Derivative not found");
        return derivatives[childSongId];
    }
    
    /**
     * @dev Check if song is a derivative
     */
    function isDerivative(uint256 songId) external view returns (bool) {
        return derivatives[songId].timestamp != 0;
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