// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {PermissionedUSDCWrapper} from "src/PermissionedUSDCWrapper.sol";
import {ERC20} from "src/ERC20.sol";

contract USDCWrapperTest is Test {
    USDCWrapper wrapper;

    function setUp() public {
        ERC20 token = new ERC20("TEST", "TEST");
        wrapper = new USDCWrapper("WTEST", "WTEST", token);
    }

    function testWrap() public {}
}
