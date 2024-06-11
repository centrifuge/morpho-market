// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import "test/mocks/BaseMock.sol";
import {ERC20} from "liquidity-pools/src/token/ERC20.sol";

contract MockVault is BaseMock {
    address public asset;
    address public share;

    constructor(uint256 price, uint8 shareDecimals, uint8 assetDecimals) {
        // create new ERC20 with asset decimals store address
        ERC20 testAsset = new ERC20(assetDecimals);
        ERC20 testShare = new ERC20(shareDecimals);
        asset = address(testAsset);
        share = address(testShare);

        values_uint256["price"] = price * 10 ** uint256(assetDecimals);
        values_address["share"] = share;
        values_address["asset"] = asset;
    }

    function convertToAssets(uint256 amount) external returns (uint256) {
        return values_uint256["price"];
    }
}
