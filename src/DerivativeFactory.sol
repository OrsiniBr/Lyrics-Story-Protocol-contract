// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ISongFactory {
    function registerSong(address creator, uint256 songId, string calldata metadataURI) 
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

/**
 * @title DerivativeFactory
 * @notice Creates remixes/derivatives and links them to parent songs
 * Story Protocol enforces the 15% royalty automatically
 */
contract DerivativeFactory is Ownable, ReentrancyGuard {
    ISongFactory public songFactory;
    IStoryDerivative public storyDerivative;
    
    address public licenseTemplate;
    uint256 public licenseTermsId;
    address public backend;
    
    uint16 public constant ROYALTY_PERCENTAGE = 15; // 15%
    
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
        string derivativeType
    );
    
    constructor(address _songFactory, address _backend) Ownable(msg.sender) {
        songFactory = ISongFactory(_songFactory);
        backend = _backend;
    }
    
    modifier onlyBackend() {
        require(msg.sender == backend || msg.sender == owner(), "Not authorized");
        _;
    }
    
    function setBackend(address _backend) external onlyOwner {
        backend = _backend;
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
     * @dev Create a derivative/remix
     * @param parentSongId Original song ID
     * @param childSongId New derivative song ID
     * @param creator Remix creator's wallet
     * @param metadataURI IPFS URI for derivative
     * @param derivativeType "Spanish", "Lofi", "Remix", etc.
     */
    function createDerivative(
        uint256 parentSongId,
        uint256 childSongId,
        address creator,
        string calldata metadataURI,
        string calldata derivativeType
    ) external onlyBackend nonReentrant returns (uint256 childTokenId, address childIpId) {
        require(derivatives[childSongId].timestamp == 0, "Derivative exists");
        
        // Get parent info
        (,address parentIpId,,) = songFactory.getSong(parentSongId);
        require(parentIpId != address(0), "Parent not found");
        
        // 1. Register derivative as new song
        (childTokenId, childIpId) = songFactory.registerSong(creator, childSongId, metadataURI);
        
        // 2. Link to parent via Story Protocol
        address[] memory parents = new address[](1);
        parents[0] = parentIpId;
        
        storyDerivative.makeDerivative(
            childIpId,
            parents,
            licenseTemplate,
            licenseTermsId
        );
        
        // Store relationship
        derivatives[childSongId] = Derivative({
            parentSongId: parentSongId,
            childSongId: childSongId,
            parentIpId: parentIpId,
            childIpId: childIpId,
            derivativeType: derivativeType,
            timestamp: block.timestamp
        });
        
        childrenOf[parentSongId].push(childSongId);
        
        emit DerivativeCreated(parentSongId, childSongId, parentIpId, childIpId, derivativeType);
        
        return (childTokenId, childIpId);
    }
    
    function getDerivative(uint256 childSongId) external view returns (Derivative memory) {
        return derivatives[childSongId];
    }
    
    function getChildren(uint256 parentSongId) external view returns (uint256[] memory) {
        return childrenOf[parentSongId];
    }
}