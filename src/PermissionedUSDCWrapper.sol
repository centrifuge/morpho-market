// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC20Wrapper.sol)

pragma solidity ^0.8.20;

import {IERC20Metadata} from "./ERC20.sol";
import {ERC20PermissionedBase, IERC20} from "lib/erc20-permissioned/src/ERC20PermissionedBase.sol";
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
    function getAttestation(bytes32 uid) external view returns (Attestation memory);
}

interface AttestationIndexer {
    function getAttestationUid(address recipient, bytes32 schemaUid) external view returns (bytes32);
}

struct Attestation {
    bytes32 uid; // A unique identifier of the attestation.
    bytes32 schema; // The unique identifier of the schema.
    uint64 time; // The time when the attestation was created (Unix timestamp).
    uint64 expirationTime; // The time when the attestation expires (Unix timestamp).
    uint64 revocationTime; // The time when the attestation was revoked (Unix timestamp).
    bytes32 refUID; // The UID of the related attestation.
    address recipient; // The recipient of the attestation.
    address attester; // The attester/sender of the attestation.
    bool revocable; // Whether the attestation is revocable.
    bytes data; // Custom attestation data.
}

struct CountryAttestation {
    bytes32 schema; // The unique identifier of the schema.
    address recipient; // The recipient of the attestation..
    bool revocable; // Whether the attestation is revocable.
    string verifiedCountry; // Custom attestation data.
}

contract PermissionedUSDCWrapper is ERC20PermissionedBase, Auth {
    IERC20 private immutable _underlying;

    // verified country schema
    bytes32 schemaUid = 0x1801901fabd0e6189356b4fb52bb0ab855276d84f7ec140839fbd1f6801ca065;

    AttestationService public attestationService;
    AttestationIndexer public indexer;

    modifier onlyPermissioned() {
        require(hasPermission(_msgSender()), "USDCWrapper: no permission");
        _;
    }

    constructor(string memory name_, string memory symbol_, IERC20 underlyingToken, address morpho, address bundler)
        ERC20PermissionedBase(name_, symbol_, underlyingToken, morpho, bundler)
    {
        if (address(underlyingToken) == address(this)) {
            revert ERC20InvalidUnderlying(address(this));
        }
        _underlying = underlyingToken;

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "indexer") indexer = AttestationIndexer(data);
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
     * @dev Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.
     */
    function depositFor(address account, uint256 value) public override onlyPermissioned returns (bool) {
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
    function withdrawTo(address account, uint256 value) public override onlyPermissioned returns (bool) {
        if (account == address(this)) {
            revert ERC20InvalidReceiver(account);
        }
        _burn(_msgSender(), value);
        SafeERC20.safeTransfer(_underlying, account, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(hasPermission(to), "USDCWrapper: no permission");
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        require(hasPermission(to), "USDCWrapper: no permission");
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function hasPermission(address account) public view override returns (bool attested) {
        super.hasPermission(account);
        if (account == address(this) || account == address(0) || account == MORPHO || account == BUNDLER) {
            return true;
        }
        bytes32 attestationUid = indexer.getAttestationUid(account, schemaUid);
        require(attestationUid != 0, "USDCWrapper: no attestation found");
        Attestation memory attestation = attestationService.getAttestation(attestationUid);
        string memory countryCode = parseCountryCode(attestation.data);
        bool isUS = compareStrings(countryCode, "US");
        return !isUS;
    }

    /**
     * @dev Mint wrapped token to cover any underlyingTokens that would have been transferred by mistake or acquired from
     * rebasing mechanisms. Internal function that can be exposed with access control if desired.
     */
    function _recover(address account) internal override returns (uint256) {
        uint256 value = _underlying.balanceOf(address(this)) - totalSupply();
        _mint(account, value);
        return value;
    }

    // --- Helpers ---

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function parseCountryCode(bytes memory data) internal pure returns (string memory) {
        require(data.length >= 66, "USDCWrapper: invalid attestation data");
        // Country code is two bytes long and begins at the 65th byte
        bytes memory countryBytes = new bytes(2);
        for (uint256 i = 0; i < 2; i++) {
            countryBytes[i] = data[i + 64];
        }
        return string(countryBytes);
    }
}
