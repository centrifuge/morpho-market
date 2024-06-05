// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Memberlist} from "src/Memberlist.sol";
import {PermissionedUSDCWrapper, IERC20} from "src/PermissionedUSDCWrapper.sol";

contract DeployScript is Script {

    address USDC = address(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
    address morpho = address(0);
    address bundler = address(0);
    address attestationService = address(0x4200000000000000000000000000000000000021);
    address attestationIndexer = address(0x2c7eE1E5f416dfF40054c27A62f7B357C4E8619C);
    address admin = address(0);

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        Memberlist memberlist = new Memberlist();
        PermissionedUSDCWrapper wrappedUSDC = new PermissionedUSDCWrapper("Attested USDC", "aUSDC", IERC20(USDC), morpho, bundler, attestationService, attestationIndexer, address(memberlist));
        if (admin != msg.sender && admin != address(0)) {
            memberlist.rely(admin);
            wrappedUSDC.rely(admin);
            memberlist.deny(msg.sender);
            wrappedUSDC.deny(msg.sender);
        }
        vm.stopBroadcast();
    }
}
