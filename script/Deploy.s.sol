// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Memberlist} from "src/Memberlist.sol";
import {PermissionedERC20Wrapper, IERC20} from "src/PermissionedERC20Wrapper.sol";

contract DeployScript is Script {
    address USDC = vm.envAddress("UNDERLYING_TOKEN");
    address morpho = vm.envAddress("MORPHO");
    address bundler = vm.envAddress("BUNDLER");
    address attestationService = vm.envAddress("ATTESTATION_SERVICE");
    address attestationIndexer = vm.envAddress("ATTESTATION_INDEXER");
    address admin = vm.envAddress("ADMIN");

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        Memberlist memberlist = new Memberlist();
        PermissionedERC20Wrapper wrappedUSDC = new PermissionedERC20Wrapper(
            "Attested USDC",
            "aUSDC",
            IERC20(USDC),
            morpho,
            bundler,
            attestationService,
            attestationIndexer,
            address(memberlist)
        );
        if (admin != msg.sender && admin != address(0)) {
            memberlist.rely(admin);
            wrappedUSDC.rely(admin);
            memberlist.deny(msg.sender);
            wrappedUSDC.deny(msg.sender);
        }
        vm.stopBroadcast();
    }
}
