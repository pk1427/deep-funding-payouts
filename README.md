# Deep Funding Payouts

Non-upgradeable Merkle ETH pot with a one-shot proposal and juror dispute window. The proposer commits to a payout tree (root + total); jurors can dispute within a 3-day window, and once finalized, recipients claim their share with a Merkle proof.

## Deployed Contracts

| Network | Contract | Address |
|---------|----------|---------|
| Sepolia (11155111) | DeepFundingPayout | `0x3E8DA75cf58b389ea20e4CEdCC42dECF2Ac5F4fC` |

## Setup

```sh
cp .env.example .env
# fill PRIVATE_KEY, SEPOLIA_RPC_URL, PROPOSER, JUROR_1
source .env
```

## Usage

```sh
# build
forge build

# test
forge test

# deploy to sepolia
forge script script/Counter.s.sol --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY" --broadcast
```

## Foundry

Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.

- **Forge**: Ethereum testing framework
- **Cast**: Swiss army knife for interacting with EVM smart contracts
- **Anvil**: Local Ethereum node
- **Chisel**: Fast Solidity REPL

https://book.getfoundry.sh/

```sh
$ forge build
$ forge test
$ forge fmt
$ forge snapshot
$ anvil
$ forge --help
$ cast --help
```

Never commit `.env`; it is gitignored. Only `.env.example` is tracked.