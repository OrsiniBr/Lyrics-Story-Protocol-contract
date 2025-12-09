// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SongNFT} from "../src/SongNFT.sol";

contract SongNFTScript is Script {
    function run() external {
        
        
        vm.startBroadcast();
        
        SongNFT NFT = new SongNFT();
        
        vm.stopBroadcast();
        
        console.log("NFT deployed at:", address(NFT));
        console.log("Owner:", NFT.owner());
    }
}