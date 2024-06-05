// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import {Auth} from "./utils/Auth.sol";

contract Memberlist is Auth {

    mapping(address => uint) public members;

    // --- Events ---

    event MemberAdded(address member);
    event MemberRemoved(address member);

    constructor() {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Memberlist Management

    function addMember(address member) external auth {
        require(members[member] == 0, "Memberlist: member already exists");
        members[member] = 1;
        emit MemberAdded(member);
    }

    function removeMember(address member) external auth {
        require(members[member] == 1, "Memberlist: member does not exist");
        members[member] = 0;
        emit MemberRemoved(member);
    }

    function isMember(address member) external view returns (bool) {
        return members[member] == 1;
    }
}