// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import "test/mocks/BaseMock.sol";

contract MockVault is BaseMock {
    constructor(uint128 price, uint8 shareDecimals, address asset) {
        values_uint128["price"] = price;
        values_uint8["shareDecimals"] = shareDecimals;
        values_address["asset"] = asset;
    }

    function convertToAssets(uint256 amount) external returns (uint128) {
        return values_uint128["price"];
    }

    function shareDecimals() external view returns (uint8) {
        return values_uint8["shareDecimals"];
    }

    function asset() external view returns (address) {
        return values_address["asset"];
    }
}
