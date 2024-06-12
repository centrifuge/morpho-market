// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

import {Auth} from "src/Auth.sol";
import {IOracle} from "src/interfaces/IOracle.sol";
import {IERC20Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC4626 {
    function share() external view returns (address share);
    function asset() external view returns (address asset);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
}

contract VaultOracle is Auth, IOracle {
    uint8 public constant PRICE_DECIMALS = 36;
    
    IERC4626 public vault;
    uint8 public assetDecimals;
    uint8 public shareDecimals;

    // --- Events ---
    event File(bytes32 indexed what, address data);

    constructor(address vault_) {
        _updateVault(vault_);

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Administration ---
    function file(bytes32 what, address data) public auth {
        if (what == "vault") {
            _updateVault(data);
            emit File(what, data);
        } else {
            revert("VaultOracle/file-unrecognized-param");
        }
    }

    function _updateVault(address vault_) internal {
        vault = IERC4626(vault_);
        assetDecimals = IERC20Metadata(vault.asset()).decimals();
        shareDecimals = IERC20Metadata(vault.share()).decimals();
    }

    // --- Administration ---
    function price() external view override returns (uint256) {
        uint256 priceInAssetDecimals = vault.convertToAssets(10 ** shareDecimals);
        if (assetDecimals == PRICE_DECIMALS) return priceInAssetDecimals;
        else if (assetDecimals > PRICE_DECIMALS) return priceInAssetDecimals / 10 ** (assetDecimals - PRICE_DECIMALS);
        else return priceInAssetDecimals * 10 ** (PRICE_DECIMALS - assetDecimals);
    }
}
