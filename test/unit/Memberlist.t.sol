pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Memberlist} from "src/Memberlist.sol";

contract MemberlistTest is Test {

    Memberlist memberlist;

    function setUp() public {
        memberlist = new Memberlist();
    }

    function test_AddMember_AsOwner_Works() public {
        memberlist.addMember(address(1));
        bool isMember = memberlist.isMember(address(1));
        assertEq(isMember, true);
    }

    function test_AddMember_AsNonOwner_Fails() public {
        vm.expectRevert("Auth/not-authorized");
        vm.prank(address(0));
        memberlist.addMember(address(1));
    }

    function test_RemoveMember_AsOwner_Works() public {
        memberlist.addMember(address(1));
        memberlist.removeMember(address(1));
        bool isMember = memberlist.isMember(address(1));
        assertEq(isMember, false);
    }

    function test_RemoveMember_AsNonOwner_Fails() public {
        memberlist.addMember(address(1));
        vm.expectRevert("Auth/not-authorized");
        vm.prank(address(0));
        memberlist.removeMember(address(1));
    }
}