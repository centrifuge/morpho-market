pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Oracle, ERC7540Vault} from "src/Oracle.sol";
import {BaseTest} from "liquidity-pools/test/BaseTest.sol";

contract OracleTest is BaseTest {
    Oracle oracle;
    ERC7540Vault vault;

    function setUp() public override {
        super.setUp();
        vault = ERC7540Vault(deploySimpleVault());
        oracle = new Oracle(address(vault));
    }

    function test_Price() public {
        uint128 price = 100;
        centrifugeChain.updateTrancheTokenPrice(vault.poolId(), vault.trancheId(), poolManager.assetToId(vault.asset()), price, uint64(block.timestamp));
        vm.warp(block.timestamp + 1);
        uint256 oraclePrice = oracle.price();
        assertEq(oraclePrice, price);
    }
}

