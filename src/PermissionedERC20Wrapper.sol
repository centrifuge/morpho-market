// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

import {Memberlist} from "src/Memberlist.sol";
import {Auth} from "lib/liquidity-pools/src/Auth.sol";
import {ERC20PermissionedBase, IERC20} from "lib/erc20-permissioned/src/ERC20PermissionedBase.sol";

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
contract PermissionedERC20Wrapper is Auth, ERC20PermissionedBase {
    bytes32 public constant verifiedCountrySchemaUid =
        0x1801901fabd0e6189356b4fb52bb0ab855276d84f7ec140839fbd1f6801ca065;
    bytes32 public constant verifiedAccountSchemaUid =
        0xf8b05c79f090979bf4a80270aba232dff11a10d9ca55c4f88de95317970f0de9;

    Memberlist public memberlist;
    IAttestationService public attestationService;
    IAttestationIndexer public attestationIndexer;

    constructor(
        string memory name_,
        string memory symbol_,
        IERC20 underlyingToken_,
        address morpho_,
        address bundler_,
        address attestationService_,
        address attestationIndexer_,
        address memberlist_
    ) ERC20PermissionedBase(name_, symbol_, underlyingToken_, morpho_, bundler_) {
        attestationService = IAttestationService(attestationService_);
        attestationIndexer = IAttestationIndexer(attestationIndexer_);
        memberlist = Memberlist(memberlist_);

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

    // --- Permission checks ---
    function hasPermission(address account) public view override returns (bool attested) {
        if (super.hasPermission(account) || memberlist.isMember(account)) {
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
