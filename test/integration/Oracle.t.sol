pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Oracle, ERC7540Vault} from "src/Oracle.sol";
import {BaseTest} from "liquidity-pools/test/BaseTest.sol";

interface ERC20Like {
    function decimals() external view returns (uint8);
}

contract OracleTest is BaseTest {
    Oracle oracle;
    ERC7540Vault vault;

    function setUp() public override {
        super.setUp();
        vault = ERC7540Vault(deploySimpleVault());
        oracle = new Oracle(address(vault));
    }

    function test_Price(uint128 price) public {
        centrifugeChain.updateTrancheTokenPrice(vault.poolId(), vault.trancheId(), poolManager.assetToId(vault.asset()), price, uint64(block.timestamp));
        vm.warp(block.timestamp + 1);
        uint256 oraclePrice = oracle.price();
        uint8 assetDecimals = ERC20Like(vault.asset()).decimals();
        uint8 PRICE_DECIMALS = 18;
        uint128 expectedPrice = uint128(price / 10 ** (PRICE_DECIMALS - assetDecimals));
        assertEq(oraclePrice, expectedPrice);
    }
}

