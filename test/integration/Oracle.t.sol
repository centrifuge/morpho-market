pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {VaultOracle} from "src/VaultOracle.sol";
import {ERC7540Vault} from "liquidity-pools/src/ERC7540Vault.sol";
import {BaseTest} from "liquidity-pools/test/BaseTest.sol";
import {MathLib} from "src/libraries/MathLib.sol";
import "forge-std/console.sol";

interface ERC20Like {
    function decimals() external view returns (uint8);
}

contract OracleTest is BaseTest {
    VaultOracle oracle;
    ERC7540Vault vault;

    uint8 constant POOL_DECIMALS = 18;
    uint8 constant ORACLE_PRECISION = 36;

    function setUp() public override {
        super.setUp();
        vault = ERC7540Vault(deploySimpleVault());
        oracle = new VaultOracle(address(vault));
    }

    function test_Expected_Price(uint256 price) public {
        vm.assume(price <= 1000 && price > 0);
        uint128 pricePoolDecimals = uint128(price * 10 ** POOL_DECIMALS);

        centrifugeChain.updateTrancheTokenPrice(
            vault.poolId(),
            vault.trancheId(),
            poolManager.assetToId(vault.asset()),
            pricePoolDecimals,
            uint64(block.timestamp)
        );
        vm.warp(block.timestamp + 1);
        uint256 oraclePrice = oracle.price();

        uint256 expectedNormalizedPrice = price * 10 ** ORACLE_PRECISION;
        assertEq(oraclePrice, expectedNormalizedPrice);
    }
}
