// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {PermissionedUSDCWrapper, IERC20} from "src/PermissionedUSDCWrapper.sol";
import {ERC20} from "src/ERC20.sol";

contract PermissionedUSDCWrapperTest is Test {
    PermissionedUSDCWrapper wrappedUSDC;

    address userUS;
    address userNonUS1;
    address userNonUS2;
    address userNoAttestation;
    address userVerifiedAccount;
    ERC20 usdc;

    function setUp() public {
        usdc = new ERC20("USDC", "USDC");
        wrappedUSDC = new PermissionedUSDCWrapper("attested USDC", "aUSDC", IERC20(address(usdc)), address(0), address(0), address(0x4200000000000000000000000000000000000021), address(0x2c7eE1E5f416dfF40054c27A62f7B357C4E8619C));

        // unless specified, all addresses have a VERIFIED_ACCOUNT attestation as well.
        userUS = address(0x27CDCb15c9c47D173BEe093Fa3bdDaDF8f00A520);
        userNonUS1 = address(0x7f7C9B77360348559f50BE488Ee15bc514bC7375);
        userNonUS2 = address(0x53753098E2660AbD4834A3eD713D11AC1123421A);
        userNoAttestation = makeAddr("NoAttestation");
        userVerifiedAccount = address(0x67aEAe1Def34ACd37A785949edCb61b745491467);

        vm.label(address(usdc), "Test ERC20");
        vm.label(address(wrappedUSDC), "PermissionedUSDCWrapper");
        vm.label(userUS, "US User");
        vm.label(userNonUS1, "Non-US User 1");
        vm.label(userNonUS2, "Non-US User 2");
        vm.label(userNoAttestation, "No Attestation User");
        vm.label(userVerifiedAccount, "Verified Account User");
    }

    function test_HasPermission_WithNonUSUser_Works() public {
        bool hasPermissionNonUS = wrappedUSDC.hasPermission(userNonUS1);
        assertEq(hasPermissionNonUS, true);
    }

    function test_HasPermission_WithUSUser_Fails() public {
        bool hasPermissionUS = wrappedUSDC.hasPermission(userUS);
        assertEq(hasPermissionUS, false);
    }

    function test_HasPermission_WithoutAttestation_Fails() public {
        vm.expectRevert("USDCWrapper: no attestation found");
        bool hasPermissionNoAttestation = wrappedUSDC.hasPermission(userNoAttestation);
    }

    function test_HasPermission_WithOnlyVerifiedAccountAttestation_Fails() public {
        vm.expectRevert("USDCWrapper: no attestation found");
        bool hasPermissionVerifiedAccount = wrappedUSDC.hasPermission(userVerifiedAccount);
    }

    function test_DepositFor_WithPermissioned_Works() public {
        deal(address(usdc), userNonUS1, 100);
        vm.startPrank(userNonUS1);
        usdc.approve(address(wrappedUSDC), 100);
        wrappedUSDC.depositFor(userNonUS1, 100);
        vm.stopPrank();
        assertEq(wrappedUSDC.balanceOf(userNonUS1), 100);
        assertEq(usdc.balanceOf(address(wrappedUSDC)), 100);
    }

    function test_DepositFor_WithNonPermissioned_Fails() public {
        deal(address(usdc), userUS, 100);
        vm.startPrank(userUS);
        usdc.approve(address(wrappedUSDC), 100);
        vm.expectRevert(abi.encodeWithSelector(PermissionedUSDCWrapper.NoPermission.selector, userUS));
        wrappedUSDC.depositFor(userUS, 100);
        vm.stopPrank();
    }

    function test_DepositFor_FromNonPermissionedToPermissioned_Works() public {
        deal(address(usdc), userUS, 100);
        vm.startPrank(userUS);
        usdc.approve(address(wrappedUSDC), 100);
        wrappedUSDC.depositFor(userNonUS1, 100);
        vm.stopPrank();
        assertEq(wrappedUSDC.balanceOf(userNonUS1), 100);
        assertEq(usdc.balanceOf(address(wrappedUSDC)), 100);
    }

    function test_WithdrawTo_WithPermissioned_Works() public {
        deal(address(wrappedUSDC), userNonUS1, 100);
        deal(address(usdc), address(wrappedUSDC), 100);
        vm.startPrank(userNonUS1);
        wrappedUSDC.approve(address(wrappedUSDC), 100);
        wrappedUSDC.withdrawTo(userNonUS1, 100);
        vm.stopPrank();
        assertEq(wrappedUSDC.balanceOf(userNonUS1), 0);
        assertEq(usdc.balanceOf(userNonUS1), 100);
    }

    function test_WithdrawTo_WithNonPermissioned_Works() public {
        deal(address(wrappedUSDC), userUS, 100);
        deal(address(usdc), address(wrappedUSDC), 100);
        vm.startPrank(userUS);
        wrappedUSDC.approve(address(wrappedUSDC), 100);
        wrappedUSDC.withdrawTo(userUS, 100);
        vm.stopPrank();
        assertEq(wrappedUSDC.balanceOf(userUS), 0);
        assertEq(usdc.balanceOf(userUS), 100);
    }

    function test_WithdrawTo_FromNonPermissionedToPermissioned_Works() public {
        deal(address(wrappedUSDC), userUS, 100);
        deal(address(usdc), address(wrappedUSDC), 100);
        vm.startPrank(userUS);
        wrappedUSDC.approve(address(wrappedUSDC), 100);
        wrappedUSDC.withdrawTo(userNonUS1, 100);
        vm.stopPrank();
        assertEq(wrappedUSDC.balanceOf(userNonUS1), 0);
        assertEq(usdc.balanceOf(userNonUS1), 100);
    }

    function test_transfer_FromPermissionedToPermissioned_Works() public {
        deal(address(wrappedUSDC), userNonUS1, 100);
        vm.prank(userNonUS1);
        wrappedUSDC.transfer(userNonUS2, 100);
        assertEq(wrappedUSDC.balanceOf(userNonUS2), 100);
    }

    function test_transfer_FromPermissionedToNonPermissioned_Fails() public {
        deal(address(wrappedUSDC), userNonUS1, 100);
        vm.expectRevert("USDCWrapper: no permission");
        vm.prank(userNonUS1);
        wrappedUSDC.transfer(userUS, 100);
    }

    function test_transfer_FromNonPermissionedToPermissioned_Works() public {
        deal(address(wrappedUSDC), userUS, 100);
        vm.prank(userUS);
        wrappedUSDC.transfer(userNonUS1, 100);
        assertEq(wrappedUSDC.balanceOf(userNonUS1), 100);
    }
}
