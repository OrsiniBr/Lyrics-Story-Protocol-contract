// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SongFactory} from "../src/SongFactory.sol";

contract SongFactoryScript is Script {
    function run() external {
        // Get the reward distributor address from environment variable
        address NFT = vm.envAddress("NFT");
        address LYRIC_TOKEN_ADDRESS = vm.envAddress("LYRIC_TOKEN_ADDRESS");
        
     
        vm.startBroadcast();
        
        SongFactory songFactory = new SongFactory(NFT, LYRIC_TOKEN_ADDRESS);
        
        vm.stopBroadcast();
        
    }
}