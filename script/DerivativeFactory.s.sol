// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DerivativeFactory} from "../src/DerivativeFactory.sol";

contract DerivativeFactoryScript is Script {
    function run() external {
        // Get the reward distributor address from environment variable
        address _songFactory = vm.envAddress("SF");
        address LYRIC_TOKEN_ADDRESS = vm.envAddress("LYRIC_TOKEN_ADDRESS");
        
     
        vm.startBroadcast();
        
        DerivativeFactory derivativeFactory = new DerivativeFactory(_songFactory, LYRIC_TOKEN_ADDRESS);
        
        vm.stopBroadcast();
        
    }
}