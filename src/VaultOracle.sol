// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {IOracle} from "src/interfaces/IOracle.sol";
import {IERC20Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {MathLib} from "src/libraries/MathLib.sol";

interface IERC7540Vault {
    function share() external view returns (address share);
    function asset() external view returns (address asset);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
}

contract VaultOracle is IOracle {
    IERC7540Vault public vault;
    uint8 constant PRICE_DECIMALS = 36;
    uint8 assetDecimals;
    uint8 shareDecimals;

    constructor(address vault_) {
        vault = IERC7540Vault(vault_);
        assetDecimals = IERC20Metadata(vault.asset()).decimals();
        shareDecimals =  IERC20Metadata(vault.share()).decimals();
    }

    function price() external view override returns (uint256 price) {
        uint256 priceInAssetDecimals = vault.convertToAssets(10 ** shareDecimals);
        if (assetDecimals == PRICE_DECIMALS) price = priceInAssetDecimals;
        else if (assetDecimals > PRICE_DECIMALS) price = priceInAssetDecimals / 10 ** (assetDecimals - PRICE_DECIMALS);
        else price = priceInAssetDecimals * 10 ** (PRICE_DECIMALS - assetDecimals);
    }
}
