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

    function test_Price(uint256 price, uint8 assetDecimals, uint8 shareDecimals) public {
        vm.assume(assetDecimals <= 54 && assetDecimals > 0);
        vm.assume(shareDecimals <= 54 && shareDecimals > 0);
        vm.assume(price < 1000);

        MockVault vault = new MockVault(price, shareDecimals, assetDecimals);
        oracle = new Oracle(address(vault));
        uint256 oraclePrice = oracle.price();

        assertEq(oraclePrice, price * 10 ** 36);
    }
}
