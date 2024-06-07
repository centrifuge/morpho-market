// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import "./Mock.sol";

contract MockVault is Mock {
    constructor(uint128 price) {
        values_uint128["price"] = price;
    }

    function convertToAssets(uint256 amount) external {
        return values_uint128["price"];
    }
}