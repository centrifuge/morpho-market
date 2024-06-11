// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IOracle} from "src/interfaces/IOracle.sol";
import {IERC20Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {MathLib} from "src/libraries/MathLib.sol";

interface IERC7540Vault {
    function shareDecimals() external view returns (uint8 decimals);
    function asset() external view returns (address asset);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
}

contract Oracle is IOracle {
    IERC7540Vault public vault;
    uint8 constant PRICE_DECIMALS = 36;

    constructor(address vault_) {
        vault = IERC7540Vault(vault_);
    }

    function price() external view override returns (uint256 price) {
        uint256 priceInAssetDecimals = vault.convertToAssets(10 ** vault.shareDecimals());
        uint8 assetDecimals = IERC20Metadata(vault.asset()).decimals();
        if (assetDecimals == PRICE_DECIMALS) price = priceInAssetDecimals;
        else if (assetDecimals > PRICE_DECIMALS) price = priceInAssetDecimals / 10 ** (assetDecimals - PRICE_DECIMALS);
        else price = priceInAssetDecimals * 10 ** (PRICE_DECIMALS - assetDecimals);
    }
}
