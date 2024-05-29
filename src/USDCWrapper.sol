// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC20Wrapper.sol)

pragma solidity ^0.8.20;

import {IERC20, IERC20Metadata, ERC20} from "./ERC20.sol";
import {SafeERC20} from "./SafeERC20.sol";
import {Auth} from "./utils/Auth.sol";

/**
 * @dev Extension of the ERC-20 token contract to support token wrapping.
 *
 * Users can deposit and withdraw "underlying tokens" and receive a matching number of "wrapped tokens". This is useful
 * in conjunction with other modules. For example, combining this wrapping mechanism with {ERC20Votes} will allow the
 * wrapping of an existing "basic" ERC-20 into a governance token.
 *
 * WARNING: Any mechanism in which the underlying token changes the {balanceOf} of an account without an explicit transfer
 * may desynchronize this contract's supply and its underlying balance. Please exercise caution when wrapping tokens that
 * may undercollateralize the wrapper (i.e. wrapper's total supply is higher than its underlying balance). See {_recover}
 * for recovering value accrued to the wrapper.
 */

// indexer: 0x2c7eE1E5f416dfF40054c27A62f7B357C4E8619C // base mainnet
// attester: 0x4200000000000000000000000000000000000021 // base mainnet

interface AttestationService {
    function getAttestation(bytes32 uid) external view returns (CountryAttestation memory);
}

interface AttestationIndexer {
    function getAttestationUid(address recipient, bytes32 schemaUid) external returns (bytes32);
}

struct CountryAttestation {
    bytes32 schema; // The unique identifier of the schema.
    address recipient; // The recipient of the attestation..
    bool revocable; // Whether the attestation is revocable.
    string verifiedCountry; // Custom attestation data.
}

contract USDCWrapper is ERC20, Auth {
    IERC20 private immutable _underlying;
    bytes32 schemaUid = 0x1801901fabd0e6189356b4fb52bb0ab855276d84f7ec140839fbd1f6801ca065; // verified country schema

    /**
     * @dev The underlying token couldn't be wrapped.
     */
    error ERC20InvalidUnderlying(address token);

    AttestationService attestationService;
    AttestationIndexer indexer;

    modifier onlyAttested() {
        require(isAttested(_msgSender()));
        _;
    }

    constructor(string memory name_, string memory symbol_, IERC20 underlyingToken) ERC20(name_, symbol_) {
        if (underlyingToken == this) {
            revert ERC20InvalidUnderlying(address(this));
        }
        _underlying = underlyingToken;
    }

    function file(bytes32 what, address data) external auth {
        if (what == "indexer") attestationService = AttestationService(data);
        else if (what == "service") attestationService = AttestationService(data);
        else revert("USDCWrapper/file-unrecognized-param");
    }

    /**
     * @dev See {ERC20-decimals}.
     */
    function decimals() public view virtual override returns (uint8) {
        try IERC20Metadata(address(_underlying)).decimals() returns (uint8 value) {
            return value;
        } catch {
            return super.decimals();
        }
    }

    /**
     * @dev Returns the address of the underlying ERC-20 token that is being wrapped.
     */
    function underlying() public view returns (IERC20) {
        return _underlying;
    }

    /**
     * @dev Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.
     */
    function depositFor(address account, uint256 value) public virtual onlyAttested returns (bool) {
        address sender = _msgSender();
        if (sender == address(this)) {
            revert ERC20InvalidSender(address(this));
        }
        if (account == address(this)) {
            revert ERC20InvalidReceiver(account);
        }
        SafeERC20.safeTransferFrom(_underlying, sender, address(this), value);
        _mint(account, value);
        return true;
    }

    /**
     * @dev Allow a user to burn a number of wrapped tokens and withdraw the corresponding number of underlying tokens.
     */
    function withdrawTo(address account, uint256 value) public virtual onlyAttested returns (bool) {
        if (account == address(this)) {
            revert ERC20InvalidReceiver(account);
        }
        _burn(_msgSender(), value);
        SafeERC20.safeTransfer(_underlying, account, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override onlyAttested returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function transfer(address to, uint256 value) public override onlyAttested returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function isAttested(address user) public returns (bool attested) {
        bytes32 attestationUid = indexer.getAttestationUid(user, schemaUid);
        CountryAttestation memory attestation = attestationService.getAttestation(attestationUid);
        attested = (keccak256(abi.encodePacked((attestation.verifiedCountry))) != keccak256(abi.encodePacked(("US"))));
    }

    /**
     * @dev Mint wrapped token to cover any underlyingTokens that would have been transferred by mistake or acquired from
     * rebasing mechanisms. Internal function that can be exposed with access control if desired.
     */
    function _recover(address account) internal virtual returns (uint256) {
        uint256 value = _underlying.balanceOf(address(this)) - totalSupply();
        _mint(account, value);
        return value;
    }
}
