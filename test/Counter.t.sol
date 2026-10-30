// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {DeepFundingPayout} from "../src/DeepFundingPayout.sol";

contract DeepFundingPayoutTest is Test {
    DeepFundingPayout public payout;
    address proposer = address(0xA1);
    address juror1 = address(0xB1);
    address juror2 = address(0xB2);
    address alice = address(0xC1);
    uint256 amount = 1 ether;
    bytes32 leaf;

    function setUp() public {
        address[] memory jurors = new address[](2);
        jurors[0] = juror1;
        jurors[1] = juror2;
        payout = new DeepFundingPayout(proposer, jurors);
        vm.deal(address(this), 2 ether);
        payout.fund{value: 2 ether}();
        leaf = payout.leaf(alice, amount);
        vm.prank(proposer);
        payout.propose(leaf, amount, "ipfs://result");
    }

    function finish() internal {
        vm.warp(block.timestamp + payout.DISPUTE_WINDOW());
        payout.finalize();
    }

    function testWrongAmountFails() public {
        finish();
        vm.expectRevert();
        payout.claim(alice, amount + 1, new bytes32[](0));
    }

    function testEarlyFinalizeFails() public {
        vm.expectRevert();
        payout.finalize();
    }

    function testOpenDisputeBlocksFinalize() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        payout.dispute{value: 0.1 ether}("evidence");
        vm.warp(block.timestamp + payout.DISPUTE_WINDOW());
        vm.expectRevert();
        payout.finalize();
    }

    function testDoubleClaimFails() public {
        finish();
        payout.claim(alice, amount, new bytes32[](0));
        vm.expectRevert();
        payout.claim(alice, amount, new bytes32[](0));
    }

    function testPostFinalizationProposeFails() public {
        finish();
        vm.prank(proposer);
        vm.expectRevert();
        payout.propose(leaf, amount, "new");
    }

    function testMajorityRejectResolves() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        payout.dispute{value: 0.1 ether}("e");
        vm.prank(juror1);
        payout.resolveDispute(false);
        vm.prank(juror2);
        payout.resolveDispute(false);
        assertFalse(payout.disputed());
        assertEq(payout.disputeBond(), 0);
    }

    function testMajorityUpholdDiscardsResult() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        payout.dispute{value: 0.1 ether}("e");
        vm.prank(juror1);
        payout.resolveDispute(true);
        vm.prank(juror2);
        payout.resolveDispute(true);
        assertEq(payout.root(), bytes32(0));
    }
}
