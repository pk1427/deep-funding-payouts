// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {DeepFundingPayout} from "../src/DeepFundingPayout.sol";

contract Deploy is Script {
    DeepFundingPayout public payout;

    function setUp() public {}

    function run() public returns (DeepFundingPayout) {
        address[] memory jurors = new address[](1);
        jurors[0] = vm.envAddress("JUROR_1");
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        payout = new DeepFundingPayout(vm.envAddress("PROPOSER"), jurors);
        vm.stopBroadcast();
        return payout;
    }
}
