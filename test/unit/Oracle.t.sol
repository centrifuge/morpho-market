pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {Oracle} from "src/Oracle.sol";
import {MockVault} from "test/mocks/MockVault.sol";
import {ERC20} from "src/ERC20.sol";
import {MathLib} from "src/libraries/MathLib.sol";
import {IERC20Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract OracleTest is Test {
    Oracle oracle;

    function setUp() public {}

    function test_Price_unit(uint128 price, uint8 shareDecimals) public {
        vm.assume(shareDecimals <= 54);
        ERC20 asset = new ERC20("Test", "TST");
        MockVault vault = new MockVault(price, shareDecimals, address(asset));
        oracle = new Oracle(address(vault));
        uint256 oraclePrice = oracle.price();
        uint8 assetDecimals = IERC20Metadata(vault.asset()).decimals();
        uint8 precisionDifference = 36 + assetDecimals - vault.shareDecimals();
        uint256 expectedPrice = MathLib.mulDiv(price, 10 ** precisionDifference, 10 ** assetDecimals);
        console.log("oraclePrice", oraclePrice);
        console.log("computedPrice", expectedPrice);
        assertEq(oraclePrice, expectedPrice);
    }
}
