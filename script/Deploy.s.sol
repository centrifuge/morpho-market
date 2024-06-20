// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Memberlist} from "src/Memberlist.sol";
import {PermissionedERC20Wrapper} from "src/PermissionedERC20Wrapper.sol";
import {ERC20PermissionedBase, IERC20} from "lib/erc20-permissioned/src/ERC20PermissionedBase.sol";
import {VaultOracle} from "src/VaultOracle.sol";

contract DeployScript is Script {
    address USDC = vm.envAddress("UNDERLYING_TOKEN");
    address morpho = vm.envAddress("MORPHO");
    address bundler = vm.envAddress("BUNDLER");
    address attestationService = vm.envAddress("ATTESTATION_SERVICE");
    address attestationIndexer = vm.envAddress("ATTESTATION_INDEXER");
    address admin = vm.envAddress("ADMIN");
    address vault = vm.envAddress("VAULT");

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        VaultOracle oracle;
        Memberlist memberlist = new Memberlist();
        PermissionedERC20Wrapper wrappedUSDC = new PermissionedERC20Wrapper(
            "Verified USDC",
            "verUSDC",
            IERC20(USDC),
            morpho,
            bundler,
            attestationService,
            attestationIndexer,
            address(memberlist)
        );
        if (vault != address(0)) {
            oracle = new VaultOracle(vault);
        }
        if (admin != msg.sender && admin != address(0)) {
            memberlist.rely(admin);
            wrappedUSDC.rely(admin);
            memberlist.deny(msg.sender);
            wrappedUSDC.deny(msg.sender);
            if (address(oracle) != address(0)) {
                oracle.rely(admin);
                oracle.deny(msg.sender);
            }
        }
        vm.stopBroadcast();
    }
}
