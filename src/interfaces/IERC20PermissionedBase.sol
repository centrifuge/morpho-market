// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "src/interfaces/IERC20.sol";
import {ERC20Permit} from "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Wrapper} from "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Wrapper.sol";

/// @title ERC20PermissionedBase
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice ERC20Permissioned contract to wrap/unwrap permissionless tokens and add a permissioning scheme.
/// @dev Inherit this contract and override the `hasPermission` and `_update` functions to change the permissioning
/// scheme.
abstract contract ERC20PermissionedBase is ERC20Wrapper, ERC20Permit {
    /* ERRORS */

    /// @notice Thrown when `account` has no permission.
    error NoPermission(address account);

    /* IMMUTABLES */

    /// @notice The address of the Morpho contract.
    address public immutable MORPHO;

    /// @notice The address of the Bundler contract.
    address public immutable BUNDLER;

    /* PUBLIC */

    /// @dev Returns true if `account` has permission to hold and transfer tokens.
    /// @dev By default Morpho and Bundler have this permission.
    /// @dev Override this function to change the permissioning scheme.
    function hasPermission(address account) external view virtual returns (bool) {}

    /* ERC20 */

    function decimals() external view virtual override(ERC20, ERC20Wrapper) returns (uint8) {}
}