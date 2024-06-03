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
    ERC20 token;

    function setUp() public {
        token = new ERC20("TEST", "TEST");
        wrapper = new PermissionedUSDCWrapper("WTEST", "WTEST", IERC20(address(token)), address(0), address(1));
        wrapper.file("service", 0x4200000000000000000000000000000000000021);
        wrapper.file("indexer", 0x2c7eE1E5f416dfF40054c27A62f7B357C4E8619C);
        userUS = address(0x27CDCb15c9c47D173BEe093Fa3bdDaDF8f00A520);
        vm.label(userUS, "US User");
        userNonUS = address(0x7f7C9B77360348559f50BE488Ee15bc514bC7375);
        vm.label(userNonUS, "Non-US User");
        userNoCountryAttestation = makeAddr("NoCountry");
        vm.label(userNoCountryAttestation, "No Country Attestation User");
    }

    function testHasPermission() public {
        bool hasPermissionUS = wrapper.hasPermission(userUS);
        assertEq(hasPermissionUS, false);
        bool hasPermissionNonUS = wrapper.hasPermission(userNonUS);
        assertEq(hasPermissionNonUS, true);
    }

    function testWrap() public {
        deal(address(token), userNonUS, 100);
        vm.startPrank(userNonUS);
        token.approve(address(wrapper), 100);
        wrapper.depositFor(userNonUS, 100);
        assertEq(wrapper.balanceOf(userNonUS), 100);
        assertEq(token.balanceOf(address(wrapper)), 100);
    }

    function testWrapToUSUserFails() public {
        deal(address(token), userUS, 100);
        vm.startPrank(userUS);
        token.approve(address(wrapper), 100);
        vm.expectRevert("USDCWrapper: no permission");
        wrapper.depositFor(userUS, 100);
    }

    function testWrapToUnattestedUserFails() public {
        deal(address(token), userNoCountryAttestation, 100);
        vm.startPrank(userNoCountryAttestation);
        token.approve(address(wrapper), 100);
        vm.expectRevert("USDCWrapper: no attestation found");
        wrapper.depositFor(userNoCountryAttestation, 100);
    }

    function testUnwrap() public {
        deal(address(wrapper), userNonUS, 100);
        deal(address(token), address(wrapper), 100);
        vm.startPrank(userNonUS);
        wrapper.approve(address(wrapper), 100);
        wrapper.withdrawTo(userNonUS, 100);
        assertEq(wrapper.balanceOf(userNonUS), 0);
        assertEq(token.balanceOf(userNonUS), 100);
    }

    function testUnwrapToUSUserFails() public {
        deal(address(wrapper), userNonUS, 100);
        deal(address(token), address(wrapper), 100);
        vm.startPrank(userUS);
        wrapper.approve(address(wrapper), 100);
        vm.expectRevert("USDCWrapper: no permission");
        wrapper.withdrawTo(userUS, 100);
    }

    function testUnwrapToUnattestedUserFails() public {
        deal(address(wrapper), userNonUS, 100);
        deal(address(token), address(wrapper), 100);
        vm.startPrank(userNoCountryAttestation);
        wrapper.approve(address(wrapper), 100);
        vm.expectRevert("USDCWrapper: no attestation found");
        wrapper.withdrawTo(userNoCountryAttestation, 100);
    }
}
