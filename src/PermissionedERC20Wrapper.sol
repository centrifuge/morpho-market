// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

import {Auth} from "src/Auth.sol";
import {Memberlist} from "src/Memberlist.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Wrapper} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import {ERC20Permit} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IERC20Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IAttestationService {
    function getAttestation(bytes32 uid) external view returns (Attestation memory);
}

interface IAttestationIndexer {
    function getAttestationUid(address recipient, bytes32 verifiedCountrySchemaUid) external view returns (bytes32);
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

/// @title  PermissionedERC20Wrapper
/// @dev    Extension of the ERC-20 token contract to support token wrapping and transferring for permissioned addresses.
///
///         Permissioned addresses are either those on the memberlist or those with both a VERIFIED_ACCOUNT attestation and a
///         VERIFIED_COUNTRY attestation of anything other than "US". Attestations are provided by Coinbase
///         through the Ethereum Attestation Service.
/// @author Modified from OpenZeppelin Contracts v5.0.0 (token/ERC20/extensions/ERC20Wrapper.sol)
contract PermissionedERC20Wrapper is Auth, ERC20, ERC20Wrapper, ERC20Permit {
    /// @notice Thrown when `account` has no permission.
    error NoPermission(address account);

    bytes32 public constant verifiedCountrySchemaUid =
        0x1801901fabd0e6189356b4fb52bb0ab855276d84f7ec140839fbd1f6801ca065;
    bytes32 public constant verifiedAccountSchemaUid =
        0xf8b05c79f090979bf4a80270aba232dff11a10d9ca55c4f88de95317970f0de9;

    /// @notice The address of the Morpho contract.
    address public immutable MORPHO;

    /// @notice The address of the Bundler contract.
    address public immutable BUNDLER;

    /// @notice The underlying token.
    IERC20Metadata public immutable _underlying;

    Memberlist public memberlist;
    IAttestationService public attestationService;
    IAttestationIndexer public attestationIndexer;

    constructor(
        string memory name_,
        string memory symbol_,
        IERC20Metadata underlyingToken_,
        address morpho_,
        address bundler_,
        address attestationService_,
        address attestationIndexer_,
        address memberlist_
    ) ERC20Wrapper(underlyingToken_) ERC20Permit(name_) ERC20(name_, symbol_) {
        MORPHO = morpho_;
        BUNDLER = bundler_;
        attestationService = IAttestationService(attestationService_);
        attestationIndexer = IAttestationIndexer(attestationIndexer_);
        memberlist = Memberlist(memberlist_);
        if (address(underlyingToken_) == address(this)) {
            revert ERC20InvalidUnderlying(address(this));
        }
        _underlying = underlyingToken_;

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Administration ---
    function file(bytes32 what, address data) external auth {
        if (what == "indexer") attestationIndexer = IAttestationIndexer(data);
        else if (what == "service") attestationService = IAttestationService(data);
        else if (what == "memberlist") memberlist = Memberlist(data);
        else revert("PermissionedERC20Wrapper/file-unrecognized-param");
    }

    // --- ERC20 wrapping ---
    /**
     * @dev Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.
     */
    function depositFor(address account, uint256 value) public override returns (bool) {
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
    function withdrawTo(address account, uint256 value) public override returns (bool) {
        if (account == address(this)) {
            revert ERC20InvalidReceiver(account);
        }
        _burn(_msgSender(), value);
        SafeERC20.safeTransfer(_underlying, account, value);
        return true;
    }

    function _update(address from, address to, uint256 value) internal virtual override {
        if (!hasPermission(to)) revert NoPermission(to);

        super._update(from, to, value);
    }

    function decimals() public view virtual override(ERC20, ERC20Wrapper) returns (uint8) {
        try IERC20Metadata(address(_underlying)).decimals() returns (uint8 value) {
            return value;
        } catch {
            return super.decimals();
        }
    }

    // --- Permission checks ---
    function hasPermission(address account) public view returns (bool attested) {
        if (
            account == address(this) || account == address(0) || account == MORPHO || account == BUNDLER
                || memberlist.isMember(account)
        ) {
            return true;
        }

        Attestation memory verifiedAccountAttestation = getAttestation(account, verifiedAccountSchemaUid);
        Attestation memory verifiedCountryAttestation = getAttestation(account, verifiedCountrySchemaUid);

        return keccak256(verifiedAccountAttestation.data) == keccak256(abi.encodePacked(uint256(1)))
            && keccak256(abi.encodePacked(parseCountryCode(verifiedCountryAttestation.data)))
                != keccak256(abi.encodePacked("US"));
    }

    function getAttestation(address account, bytes32 schemaUid) public view returns (Attestation memory attestation) {
        bytes32 attestationUid = attestationIndexer.getAttestationUid(account, schemaUid);
        require(attestationUid != 0, "PermissionedERC20Wrapper/no-attestation-found");
        attestation = attestationService.getAttestation(attestationUid);
        require(attestation.expirationTime == 0, "PermissionedERC20Wrapper/attestation-expired");
        require(attestation.revocationTime == 0, "PermissionedERC20Wrapper/attestation-revoked");
    }

    // --- Helpers ---
    function recover(address account) public auth returns (uint256) {
        return _recover(account);
    }

    function parseCountryCode(bytes memory data) internal pure returns (string memory) {
        require(data.length >= 66, "PermissionedERC20Wrapper/invalid-attestation-data");
        // Country code is two bytes long and begins at the 65th byte
        bytes memory countryBytes = new bytes(2);
        for (uint256 i = 0; i < 2; i++) {
            countryBytes[i] = data[i + 64];
        }
        return string(countryBytes);
    }
}
