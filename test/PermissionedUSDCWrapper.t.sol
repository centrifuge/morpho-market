// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "src/PermissionedUSDCWrapper.sol";
import {ERC20} from "src/ERC20.sol";

contract PermissionedUSDCWrapperTest is Test {
    PermissionedUSDCWrapper wrapper;

    address userUS;
    address userNonUS;
    address userNoAttestation;
    address userVerifiedAccount;
    ERC20 token;

    function setUp() public {
        token = new ERC20("TEST", "TEST");
        wrapper = new PermissionedUSDCWrapper("WTEST", "WTEST", IERC20(address(token)), address(0), address(1));
        wrapper.file("service", 0x4200000000000000000000000000000000000021);
        wrapper.file("indexer", 0x2c7eE1E5f416dfF40054c27A62f7B357C4E8619C);

        // unless specified, all addresses have a VERIFIED_ACCOUNT attestation as well.
        userUS = address(0x27CDCb15c9c47D173BEe093Fa3bdDaDF8f00A520);
        userNonUS = address(0x7f7C9B77360348559f50BE488Ee15bc514bC7375);
        userNoAttestation = makeAddr("NoAttestation");
        userVerifiedAccount = address(0x67aEAe1Def34ACd37A785949edCb61b745491467);

        vm.label(address(token), "Test ERC20");
        vm.label(address(wrapper), "PermissionedUSDCWrapper");
        vm.label(userUS, "US User");
        vm.label(userNonUS, "Non-US User");
        vm.label(userNoAttestation, "No Attestation User");
        vm.label(userVerifiedAccount, "Verified Account User");
    }

    function test_HasPermission_WithNonUSUser_Works() public {
        bool hasPermissionNonUS = wrapper.hasPermission(userNonUS);
        assertEq(hasPermissionNonUS, true);
    }

    function test_HasPermission_WithUSUser_Fails() public {
        bool hasPermissionUS = wrapper.hasPermission(userUS);
        assertEq(hasPermissionUS, false);
    }

    function test_HasPermission_WithoutAttestation_Fails() public {
        vm.expectRevert("USDCWrapper: no attestation found");
        bool hasPermissionNoAttestation = wrapper.hasPermission(userNoAttestation);
    }

    function test_HasPermission_WithOnlyVerifiedAccountAttestation_Fails() public {
        vm.expectRevert("USDCWrapper: no attestation found");
        bool hasPermissionVerifiedAccount = wrapper.hasPermission(userVerifiedAccount);
    }


    function test_DepositFor_WithNonUSUser_Works() public {
        deal(address(token), userNonUS, 100);
        vm.startPrank(userNonUS);
        token.approve(address(wrapper), 100);
        wrapper.depositFor(userNonUS, 100);
        assertEq(wrapper.balanceOf(userNonUS), 100);
        assertEq(token.balanceOf(address(wrapper)), 100);
    }

    function test_withdrawTo_WithNonUSUSer_Works() public {
        deal(address(wrapper), userNonUS, 100);
        deal(address(token), address(wrapper), 100);
        vm.startPrank(userNonUS);
        wrapper.approve(address(wrapper), 100);
        wrapper.withdrawTo(userNonUS, 100);
        assertEq(wrapper.balanceOf(userNonUS), 0);
        assertEq(token.balanceOf(userNonUS), 100);
    }
}
