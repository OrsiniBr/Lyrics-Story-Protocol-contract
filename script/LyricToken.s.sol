// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LyricToken} from "../src/LyricToken.sol";

contract LyricTokenScript is Script {
    function run() external {
        // Get the reward distributor address from environment variable
        address rewardDistributor = vm.envAddress("REWARD_DISTRIBUTOR_ADDRESS");
        
        console.log("Deploying LyricToken...");
        console.log("Reward Distributor:", rewardDistributor);
        
        vm.startBroadcast();
        
        // Deploy the token
        LyricToken token = new LyricToken(rewardDistributor);
        
        vm.stopBroadcast();
        
        console.log("LyricToken deployed at:", address(token));
        console.log("Initial supply:", token.totalSupply() / 10**18, "tokens");
        console.log("Max supply:", token.MAX_SUPPLY() / 10**18, "tokens");
        console.log("Owner:", token.owner());
        console.log("Reward Distributor:", token.rewardDistributor());
    }
}