// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {LyricToken} from "../src/LyricToken.sol";

contract LyricTokenScript is Script {
    LyricToken public counter;
    address public rewardDistributor = 0x379bef16d52ec8b2b033497287ec911a777a1917;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        counter = new LyricToken(rewardDistributor);

        vm.stopBroadcast();
    }
}
