// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {PermissionedUSDCWrapper, IERC20} from "src/PermissionedUSDCWrapper.sol";
import {ERC20} from "src/ERC20.sol";

contract PermissionedUSDCWrapperTest is Test {
    PermissionedUSDCWrapper wrapper;

    function setUp() public {
        ERC20 token = new ERC20("TEST", "TEST");
        wrapper = new PermissionedUSDCWrapper("WTEST", "WTEST", IERC20(address(token)), address(0), address(1));
    }

    function testWrap() public {}
}
