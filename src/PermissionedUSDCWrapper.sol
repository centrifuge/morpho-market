// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC20Wrapper.sol)

pragma solidity ^0.8.20;

import {IERC20Metadata} from "./ERC20.sol";
import {ERC20, ERC20Wrapper, ERC20Permit, IERC20} from "lib/erc20-permissioned/src/ERC20PermissionedBase.sol";
import {SafeERC20} from "./SafeERC20.sol";
import {Auth} from "./utils/Auth.sol";
import {IERC20PermissionedBase} from "src/interfaces/IERC20PermissionedBase.sol";
import {Memberlist} from "src/Memberlist.sol";

/**
 * @dev Extension of the ERC-20 token contract to support token wrapping and transferring for permissioned addresses.
 *
 * Permissioned addresses are either those on the memberlist or those with both a VERIFIED_ACCOUNT attestation and a
 * VERIFIED_COUNTRY attestation of anything other than "US". Attestations are provided by Coinbase through the Ethereum
 * Attestation Service.
 */
interface AttestationService {
    function getAttestation(bytes32 uid) external view returns (Attestation memory);
}

interface AttestationIndexer {
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

contract PermissionedUSDCWrapper is Auth, ERC20, ERC20Wrapper, ERC20Permit {
    // --- ERRORS ---

    /// @notice Thrown when `account` has no permission.
    error NoPermission(address account);

    // --- IMMUTABLES ---

    /// @notice The address of the Morpho contract.
    address public immutable MORPHO;

    /// @notice The address of the Bundler contract.
    address public immutable BUNDLER;

    /// @notice The underlying token.
    IERC20 private immutable _underlying;

    bytes32 verifiedCountrySchemaUid = 0x1801901fabd0e6189356b4fb52bb0ab855276d84f7ec140839fbd1f6801ca065;
    bytes32 verifiedAccountSchemaUid = 0xf8b05c79f090979bf4a80270aba232dff11a10d9ca55c4f88de95317970f0de9;

    AttestationService public attestationService;
    AttestationIndexer public attestationIndexer;
    Memberlist public memberlist;

    constructor(
        string memory name_,
        string memory symbol_,
        IERC20 underlyingToken_,
        address morpho_,
        address bundler_,
        address attestationService_,
        address attestationIndexer_,
        address memberlist_
    ) ERC20Wrapper(underlyingToken_) ERC20Permit(name_) ERC20(name_, symbol_) {
        MORPHO = morpho_;
        BUNDLER = bundler_;
        attestationService = AttestationService(attestationService_);
        attestationIndexer = AttestationIndexer(attestationIndexer_);
        memberlist = Memberlist(memberlist_);
        if (address(underlyingToken_) == address(this)) {
            revert ERC20InvalidUnderlying(address(this));
        }
        _underlying = underlyingToken_;

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "indexer") attestationIndexer = AttestationIndexer(data);
        else if (what == "service") attestationService = AttestationService(data);
        else if (what == "memberlist") memberlist = Memberlist(data);
        else revert("USDCWrapper/file-unrecognized-param");
    }

    /**
     * @dev See {ERC20-decimals}.
     */
    function decimals() public view virtual override(ERC20, ERC20Wrapper) returns (uint8) {
        try IERC20Metadata(address(_underlying)).decimals() returns (uint8 value) {
            return value;
        } catch {
            return super.decimals();
        }
    }

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

    function hasPermission(address account) public view returns (bool attested) {
        if (
            account == address(this) || account == address(0) || account == MORPHO || account == BUNDLER
                || memberlist.isMember(account)
        ) {
            return true;
        }

        Attestation memory verifiedAccountAttestation = getVerifiedAccountAttestation(account);
        bool isAccountVerified = keccak256(verifiedAccountAttestation.data) == keccak256(abi.encodePacked(uint256(1)));

        Attestation memory verifiedCountryAttestation = getVerifiedCountryAttestation(account);
        string memory countryCode = parseCountryCode(verifiedCountryAttestation.data);
        bool isUS = keccak256(abi.encodePacked(countryCode)) == keccak256(abi.encodePacked("US"));

        return isAccountVerified && !isUS;
    }

    function getVerifiedCountryAttestation(address account) public view returns (Attestation memory attestation) {
        bytes32 attestationUid = attestationIndexer.getAttestationUid(account, verifiedCountrySchemaUid);
        require(attestationUid != 0, "USDCWrapper: no attestation found");
        attestation = attestationService.getAttestation(attestationUid);
        require(attestation.expirationTime == 0, "USDCWrapper: attestation expired");
        require(attestation.revocationTime == 0, "USDCWrapper: attestation revoked");
    }

    function getVerifiedAccountAttestation(address account) public view returns (Attestation memory attestation) {
        bytes32 attestationUid = attestationIndexer.getAttestationUid(account, verifiedAccountSchemaUid);
        require(attestationUid != 0, "USDCWrapper: no attestation found");
        attestation = attestationService.getAttestation(attestationUid);
        require(attestation.expirationTime == 0, "USDCWrapper: attestation expired");
        require(attestation.revocationTime == 0, "USDCWrapper: attestation revoked");
    }

    /**
     * @dev Mint wrapped token to cover any underlyingTokens that would have been transferred by mistake or acquired from
     * rebasing mechanisms.
     */
    function recover(address account) public auth returns (uint256) {
        _recover(account);
    }

    function _update(address from, address to, uint256 value) internal virtual override {
        if (!hasPermission(to)) revert NoPermission(to);

        super._update(from, to, value);
    }

    // --- HELPERS ---
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
