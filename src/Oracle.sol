// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IOracle} from "src/interfaces/IOracle.sol";

/// @title Oracle
contract Oracle is IOracle {
    ERC7540 public vault;

    constructor(ERC7540 vault_) {
        vault = vault_;
    }

    function price() external view override returns (uint256) {
    }
}