// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

import {IOracle} from "src/interfaces/IOracle.sol";
import {IERC20Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {MathLib} from "src/libraries/MathLib.sol";

interface IERC4626 {
    function share() external view returns (address share);
    function asset() external view returns (address asset);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
}

contract VaultOracle is IOracle {
    IERC4626 public vault;
    uint8 constant PRICE_DECIMALS = 36;
    uint8 assetDecimals;
    uint8 shareDecimals;

    constructor(address vault_) {
        vault = IERC4626(vault_);
        assetDecimals = IERC20Metadata(vault.asset()).decimals();
        shareDecimals = IERC20Metadata(vault.share()).decimals();
    }

    function price() external view override returns (uint256) {
        uint256 priceInAssetDecimals = vault.convertToAssets(10 ** shareDecimals);
        if (assetDecimals == PRICE_DECIMALS) return priceInAssetDecimals;
        else if (assetDecimals > PRICE_DECIMALS) return priceInAssetDecimals / 10 ** (assetDecimals - PRICE_DECIMALS);
        else return priceInAssetDecimals * 10 ** (PRICE_DECIMALS - assetDecimals);
    }
}
