// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import "test/mocks/BaseMock.sol";
import {ERC20} from "liquidity-pools/src/token/ERC20.sol";

contract MockVault is BaseMock {
    address public asset;

    constructor(uint256 price, uint8 shareDecimals, uint8 assetDecimals) {
        // create new ERC20 with asset decimals store address
        ERC20 testAsset = new ERC20(assetDecimals);
        asset = address(testAsset);

        values_uint256["price"] = price;
        //price * 10 ** uint128(assetDecimals);
        values_uint8["shareDecimals"] = shareDecimals;
        values_address["asset"] = asset;
    }

    function convertToAssets(uint256 amount) external returns (uint256) {
        return values_uint256["price"];
    }

    function shareDecimals() external view returns (uint8) {
        return values_uint8["shareDecimals"];
    }

    function asset() external view returns (address) {
        return values_address["asset"];
    }
}
