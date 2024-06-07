// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IOracle} from "src/interfaces/IOracle.sol";
import {ERC7540Vault} from "liquidity-pools/src/ERC7540Vault.sol";
import {IERC20Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {MathLib} from "src/libraries/MathLib.sol";

contract Oracle is IOracle {
    ERC7540Vault public vault;

    constructor(address vault_) {
        vault = ERC7540Vault(vault_);
    }

    function price() external view override returns (uint256) {
        uint256 price = vault.convertToAssets(10 ** vault.shareDecimals());
        uint8 assetDecimals = IERC20Metadata(vault.asset()).decimals();
        uint8 precisionDifference = 36 + assetDecimals - vault.shareDecimals();

        // Normalize to 36 digit precision
        return MathLib.mulDiv(price, 10 ** precisionDifference, 10 ** assetDecimals);
    }
}
