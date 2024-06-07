// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IOracle} from "src/interfaces/IOracle.sol";
import {ERC7540Vault} from "liquidity-pools/src/ERC7540Vault.sol";

/// @title Oracle
contract Oracle is IOracle {
    ERC7540Vault public vault;

    constructor(address vault_) {
        vault = ERC7540Vault(vault_);
    }

    function price() external view override returns (uint256) {
        return vault.convertToAssets(10 ** vault.shareDecimals());
    }
}