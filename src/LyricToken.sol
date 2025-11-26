// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LyricToken
 * @notice $LYRIC ERC-20 token for rewarding users who create songs
 * @dev Owner can mint additional tokens up to MAX_SUPPLY
 */
contract LyricToken is ERC20, Ownable {
    address public rewardDistributor;
    
    // Maximum supply cap - can never exceed this
    uint256 public constant MAX_SUPPLY = 10_000_000_000 * 10**18; // 10 billion tokens
    
    event RewardDistributed(address indexed user, uint256 amount, string reason);
    event DistributorUpdated(address indexed oldDistributor, address indexed newDistributor);
    event TokensMinted(address indexed to, uint256 amount);
    
    /**
     * @param _rewardDistributor Backend wallet that can distribute rewards
     */
    constructor(address _rewardDistributor) ERC20("Lyric Token", "LYRIC") Ownable(msg.sender) {
        require(_rewardDistributor != address(0), "Invalid distributor");
        
        rewardDistributor = _rewardDistributor;
        
        // Initial mint: 1 billion tokens
        _mint(_rewardDistributor, 500_000_000 * 10**18); // 500M for rewards
        _mint(msg.sender, 500_000_000 * 10**18);         // 500M for team/liquidity
    }
    
    modifier onlyDistributor() {
        require(msg.sender == rewardDistributor, "Only distributor can call");
        _;
    }
    
    /**
     * @dev Update the reward distributor address
     * @param newDistributor New backend wallet address
     */
    function updateDistributor(address newDistributor) external onlyOwner {
        require(newDistributor != address(0), "Invalid address");
        
        address oldDistributor = rewardDistributor;
        rewardDistributor = newDistributor;
        
        emit DistributorUpdated(oldDistributor, newDistributor);
    }
    
    /**
     * @dev Distribute rewards to a single user
     * @param to Recipient address
     * @param amount Amount of LYRIC tokens (in wei)
     * @param reason Reason for reward
     */
    function distributeReward(
        address to, 
        uint256 amount, 
        string calldata reason
    ) external onlyDistributor {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be > 0");
        require(balanceOf(rewardDistributor) >= amount, "Insufficient balance");
        
        _transfer(rewardDistributor, to, amount);
        emit RewardDistributed(to, amount, reason);
    }
    
    /**
     * @dev Batch distribute rewards (gas efficient)
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts
     * @param reason Reason for batch reward
     */
    function batchDistributeRewards(
        address[] calldata recipients,
        uint256[] calldata amounts,
        string calldata reason
    ) external onlyDistributor {
        require(recipients.length == amounts.length, "Length mismatch");
        require(recipients.length > 0, "Empty arrays");
        require(recipients.length <= 100, "Too many recipients");
        
        uint256 totalAmount = 0;
        
        // Calculate total first
        for (uint256 i = 0; i < amounts.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            require(amounts[i] > 0, "Amount must be > 0");
            totalAmount += amounts[i];
        }
        
        // Check balance once
        require(balanceOf(rewardDistributor) >= totalAmount, "Insufficient balance");
        
        // Distribute
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(rewardDistributor, recipients[i], amounts[i]);
            emit RewardDistributed(recipients[i], amounts[i], reason);
        }
    }
    
    /**
     * @dev Mint additional tokens (only owner)
     * @param to Address to receive minted tokens
     * @param amount Amount to mint
     * 
     * NOTE: Total supply can never exceed MAX_SUPPLY (10 billion)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount must be > 0");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }
    
    /**
     * @dev Burn tokens from caller's balance (deflationary mechanism)
     * @param amount Amount to burn
     */
    function burn(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        _burn(msg.sender, amount);
    }
    
    /**
     * @dev Get remaining tokens that can be minted
     */
    function remainingMintable() external view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }
}