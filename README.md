# Morpho Market

Contracts required for the real-world asset (RWA) Morpho market. Two main features:
* `PermissionedERC20Wrapper`: an ERC20 wrapper that can be minted and transferred only to accounts that hold verified account and non-US verified country attestations, or have been manually added to the memberlist.
* `VaultOracle`: Morpho-compatible oracle for ERC4626 vaults.

## Developing
#### Getting started
```sh
git clone git@github.com:centrifuge/morpho-market.git
cd morpho-market
forge update
```

#### Testing
To run all tests locally, where `[FORK_URL]` is a valid RPC endpoint for Base:
```sh
forge test --fork-url [FORK_URL]
```

## License
This codebase is licensed under [GNU Lesser General Public License v3.0](https://github.com/centrifuge/liquidity-pools/blob/main/LICENSE).
