// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "lib/erc20-permissioned/src/ERC20PermissionedBase.sol";

interface IERC20PermissionedBase is IERC20 {
    /* ERRORS */

    /// @notice Thrown when `account` has no permission.
    error NoPermission(address account);

    /* IMMUTABLES */

    /// @notice The address of the Morpho contract.
    function MORPHO() external view returns (address);

    /// @notice The address of the Bundler contract.
    function BUNDLER() external view returns (address);

    /* PUBLIC */

    /// @dev Returns true if `account` has permission to hold and transfer tokens.
    /// @dev By default Morpho and Bundler have this permission.
    /// @dev Override this function to change the permissioning scheme.
    function hasPermission(address account) external view returns (bool);

    /* ERC20 */

    function decimals() external view returns (uint8);
}