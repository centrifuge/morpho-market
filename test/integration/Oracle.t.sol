pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {VaultOracle} from "src/VaultOracle.sol";
import {ERC7540Vault} from "liquidity-pools/src/ERC7540Vault.sol";
import {BaseTest} from "liquidity-pools/test/BaseTest.sol";
import {MathLib} from "src/libraries/MathLib.sol";

interface ERC20Like {
    function decimals() external view returns (uint8);
}

contract OracleTest is BaseTest {
    VaultOracle oracle;
    ERC7540Vault vault;

    function setUp() public override {
        super.setUp();
        vault = ERC7540Vault(deploySimpleVault());
        oracle = new VaultOracle(address(vault));
    }

    function test_Price_ReturnsExpectedPrice(uint128 price) public {
        uint128 price = 1000000000000000000;
        uint8 PRICE_DECIMALS = 18;
        uint8 assetDecimals = ERC20Like(vault.asset()).decimals();

        centrifugeChain.updateTrancheTokenPrice(
            vault.poolId(), vault.trancheId(), poolManager.assetToId(vault.asset()), price, uint64(block.timestamp)
        );
        vm.warp(block.timestamp + 1);

        uint256 oraclePrice = oracle.price();
        uint128 assetPrecisionPrice = uint128(price / 10 ** (PRICE_DECIMALS - assetDecimals));

        // Normalize to 36 digit precision
        uint8 precisionDifference = 36 + assetDecimals - vault.shareDecimals();
        uint256 expectedPrice = MathLib.mulDiv(assetPrecisionPrice, 10 ** precisionDifference, 10 ** assetDecimals);
        assertEq(oraclePrice, expectedPrice);
    }

    function test_Price_Precision() public {
        uint128 price = 1000000000000000000;
        centrifugeChain.updateTrancheTokenPrice(
            vault.poolId(), vault.trancheId(), poolManager.assetToId(vault.asset()), price, uint64(block.timestamp)
        );
        vm.warp(block.timestamp + 1);
        uint256 oraclePrice = oracle.price();

        uint256 expectedNormalizedPrice = 10 ** 36;
        assertEq(oraclePrice, expectedNormalizedPrice);
    }

    function toAssetPrecision(uint128 price) internal view returns (uint128) {}
}
