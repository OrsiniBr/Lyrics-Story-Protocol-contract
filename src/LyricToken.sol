// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract LyricToken is ERC20, Ownable {
    address public rewardDistributor;
    
    event RewardDistributed(address indexed user, uint256 amount, string reason);
    event DistributorUpdated(address indexed newDistributor);
    
    constructor(address _rewardDistributor) ERC20("Lyric Token", "LYRIC") Ownable(msg.sender) {
        rewardDistributor = _rewardDistributor;
        _mint(_rewardDistributor, 500_000_000 * 10**18);
        _mint(msg.sender, 500_000_000 * 10**18);
    }
    
    modifier onlyDistributor() {
        require(msg.sender == rewardDistributor, "Only distributor");
        _;
    }
    
    function updateDistributor(address newDistributor) external onlyOwner {
        rewardDistributor = newDistributor;
        emit DistributorUpdated(newDistributor);
    }
    
    function distributeReward(
        address to, 
        uint256 amount, 
        string calldata reason
    ) external onlyDistributor {
        _transfer(rewardDistributor, to, amount);
        emit RewardDistributed(to, amount, reason);
    }
    
    function batchDistributeRewards(
        address[] calldata recipients,
        uint256[] calldata amounts,
        string calldata reason
    ) external onlyDistributor {
        require(recipients.length == amounts.length, "Length mismatch");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(rewardDistributor, recipients[i], amounts[i]);
            emit RewardDistributed(recipients[i], amounts[i], reason);
        }
    }
}