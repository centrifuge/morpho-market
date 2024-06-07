// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import "./Mock.sol";

contract MockVault is Mock {
    constructor(uint128 price) {
        values_uint128["price"] = price;
        values_uint256["shareDecimals"] = 18;
    }

    function convertToAssets(uint128 amount) external returns (uint128) {
        return values_uint128["price"];
    }

    function shareDecimals() external view returns (uint256) {
        return values_uint256["shareDecimals"];
    }
}