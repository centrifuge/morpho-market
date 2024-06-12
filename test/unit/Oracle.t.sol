pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {VaultOracle} from "src/VaultOracle.sol";
import {MockVault} from "test/mocks/MockVault.sol";
import {Auth} from "lib/liquidity-pools/src/Auth.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract OracleTest is Test {
    VaultOracle oracle;

    function setUp() public {}

    function test_Deploy(uint8 assetDecimals, uint8 shareDecimals) public {
        vm.assume(assetDecimals < 36 && assetDecimals > 0);
        vm.assume(shareDecimals < 36 && shareDecimals > 0);
        deployOracle(1, assetDecimals, shareDecimals);
    }

    function test_File(uint8 assetDecimals, uint8 shareDecimals, uint8 assetDecimalsNew, uint8 shareDecimalsNew)
        public
    {
        vm.assume(assetDecimals < 36 && assetDecimals > 0);
        vm.assume(shareDecimals < 36 && shareDecimals > 0);
        vm.assume(assetDecimalsNew < 36 && assetDecimalsNew > 0);
        vm.assume(shareDecimalsNew < 36 && shareDecimalsNew > 0);
        deployOracle(1, assetDecimals, shareDecimals);

        // update vault
        MockVault vaultNew = new MockVault(1, shareDecimalsNew, assetDecimalsNew);
        oracle.file("vault", address(vaultNew));
        assertEq(Auth(oracle).wards(address(this)), 1);
        assert(address(oracle.vault()) == address(vaultNew));
        assertEq(oracle.assetScaling(), 10 ** (36 - assetDecimalsNew));
        assertEq(oracle.singleShare(), 10 ** shareDecimalsNew);
        // fail to file unknown param
        vm.expectRevert("VaultOracle/file-unrecognized-param");
        oracle.file("random", address(vaultNew));
        // fail to file not ward
        oracle.deny(address(this));
        vm.expectRevert("Auth/not-authorized");
        oracle.file("vault", address(vaultNew));
    }

    function test_Price(uint256 price, uint8 assetDecimals, uint8 shareDecimals) public {
        vm.assume(assetDecimals < 36 && assetDecimals > 0);
        vm.assume(shareDecimals < 36 && shareDecimals > 0);
        vm.assume(price < 1000);
        deployOracle(price, assetDecimals, shareDecimals);
        uint256 oraclePrice = oracle.price();

        assertEq(oraclePrice, price * 10 ** 36);
    }

    function deployOracle(uint256 price, uint8 assetDecimals, uint8 shareDecimals) public {
        MockVault vault = new MockVault(price, shareDecimals, assetDecimals);
        oracle = new VaultOracle(address(vault));
        // assert permissions
        assertEq(Auth(oracle).wards(address(this)), 1);
        // assert state
        assert(address(oracle.vault()) == address(vault));
        assertEq(oracle.assetScaling(), 10 ** (36 - assetDecimals));
        assertEq(oracle.singleShare(), 10 ** shareDecimals);
    }
}
