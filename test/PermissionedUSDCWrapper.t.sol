// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "src/PermissionedUSDCWrapper.sol";
import {ERC20} from "src/ERC20.sol";

contract PermissionedUSDCWrapperTest is Test {
    PermissionedUSDCWrapper wrapper;

    address userUS;
    address userNonUS;
    address userNoCountryAttestation;

    function setUp() public {
        ERC20 token = new ERC20("TEST", "TEST");
        wrapper = new PermissionedUSDCWrapper("WTEST", "WTEST", IERC20(address(token)), address(0), address(1));
        wrapper.file("service", 0x4200000000000000000000000000000000000021);
        wrapper.file("indexer", 0x2c7eE1E5f416dfF40054c27A62f7B357C4E8619C);
        userUS = address(0x27CDCb15c9c47D173BEe093Fa3bdDaDF8f00A520);
        userNonUS = address(0x7f7C9B77360348559f50BE488Ee15bc514bC7375);
        userNoCountryAttestation = address(1);
    }

    function testHasPermission() public {
        bool hasPermissionUS = wrapper.hasPermission(userUS);
        assertEq(hasPermissionUS, false);
        bool hasPermissionNonUS = wrapper.hasPermission(userNonUS);
        assertEq(hasPermissionNonUS, true);
    }
}
