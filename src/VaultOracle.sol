// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {IOracle} from "src/interfaces/IOracle.sol";
import {IERC20Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Auth} from "liquidity-pools/src/Auth.sol";

interface IERC7540Vault {
    function share() external view returns (address share);
    function asset() external view returns (address asset);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
}

contract VaultOracle is IOracle, Auth {
    IERC7540Vault public vault;
    uint8 public constant PRICE_DECIMALS = 36;
    uint8 public assetDecimals;
    uint8 public shareDecimals;

    // --- Events ---
    event File(bytes32 indexed what, address data);

    constructor(address vault_) {
        _updateVault(vault_);
        wards[msg.sender] = 1;
    }

    // --- Administration ---
    function file(bytes32 what, address data) external auth {
        if (what == "vault") {
            _updateVault(data);
            emit File(what, data);
        } else {
            revert("VaultOracle/file-unrecognized-param");
        }
    }

    function price() external view override returns (uint256 price) {
        uint256 priceInAssetDecimals = vault.convertToAssets(10 ** shareDecimals);
        if (assetDecimals == PRICE_DECIMALS) price = priceInAssetDecimals;
        else if (assetDecimals > PRICE_DECIMALS) price = priceInAssetDecimals / 10 ** (assetDecimals - PRICE_DECIMALS);
        else price = priceInAssetDecimals * 10 ** (PRICE_DECIMALS - assetDecimals);
    }

    function _updateVault(address vault_) internal {
        vault = IERC7540Vault(vault_);
        assetDecimals = IERC20Metadata(vault.asset()).decimals();
        shareDecimals = IERC20Metadata(vault.share()).decimals();
    }
}
