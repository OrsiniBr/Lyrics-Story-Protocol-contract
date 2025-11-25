// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SongNFT
 * @notice Each song = 1 NFT. This represents ownership of the song IP.
 */
contract SongNFT is ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;
    address public factory;
    
    // Maps your database songId to NFT tokenId
    mapping(uint256 => uint256) public songIdToTokenId;
    mapping(uint256 => uint256) public tokenIdToSongId;
    
    event SongMinted(uint256 indexed tokenId, uint256 indexed songId, address indexed creator);
    
    constructor() ERC721("Song IP", "SONG") Ownable(msg.sender) {
        _tokenIdCounter = 1;
    }
    
    function setFactory(address _factory) external onlyOwner {
        factory = _factory;
    }
    
    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory");
        _;
    }
    
    /**
     * @dev Mint a new song NFT
     * @param to The creator's wallet
     * @param songId Your database ID
     * @param uri IPFS metadata URI
     */
    function mint(address to, uint256 songId, string memory uri) 
        external 
        onlyFactory 
        returns (uint256) 
    {
        uint256 tokenId = _tokenIdCounter++;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        
        songIdToTokenId[songId] = tokenId;
        tokenIdToSongId[tokenId] = songId;
        
        emit SongMinted(tokenId, songId, to);
        
        return tokenId;
    }
}