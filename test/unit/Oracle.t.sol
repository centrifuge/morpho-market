pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Oracle} from "src/Oracle.sol";
import {MockVault} from "test/mocks/MockVault.sol";

contract OracleTest is Test {
    Oracle oracle;

    function setUp() public override {}

    function test_Price(uint128 price) public {
        MockVault vault = new MockVault(price);
        oracle = new Oracle(address(vault));
        uint256 oraclePrice = oracle.price();
        assertEq(oraclePrice, price);
    }
}

