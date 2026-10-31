# Deep Funding Payouts

Non-upgradeable Merkle ETH pot with a one-shot proposal and juror dispute window. The proposer commits to a payout tree (root + total); jurors can dispute within a 3-day window, and once finalized, recipients claim their share with a Merkle proof.

## Deployed Contracts

| Network | Contract | Address |
|---------|----------|---------|
| Sepolia (11155111) | DeepFundingPayout | `0x87C0260BF2930077F83952F5e0E077b61F9E484c` |

### Current State (Sepolia)
- **Proposer**: `0xa568860f02DEf6CC6420F6721B774aa3a71c71d9`
- **Juror**: `0x76cd707D25685Dc7956Ed5d4e41D086845A1fB92`
- **Merkle Root**: `0x3b0a5e6f1e3518da7fe9bec0add746b6292570a203b1492e5f8f1dd1b2b0f8c9`
- **Total**: 0.01 ETH
- **Status**: Proposed (awaiting 3-day dispute window)
- **Deployment tx**: `0xad25075efe0d3657cb3cda9e115813b710158f16e6e98733f3a6ae8ff0373878`
- **Proposal tx**: `0x7b5c855e839367fd540f3810eeefc2316959f1c443add31101517a933fea5cea`

### Allocation Graph
- **Pot**: 1 ETH (1000000000000000000 wei)
- **Retention**: 5000 bps (50%)
- **Rounds**: 8
- **Cycle**: wallet-wrapper → abi-lib → utils → wallet-wrapper

## Setup

```sh
cp .env.example .env
# fill PRIVATE_KEY, SEPOLIA_RPC_URL, PROPOSER, JUROR_1, PROPOSER_PRIVATE_KEY
source .env
```

## Reproduce Allocation

```sh
npm run reproduce
# Output: Merkle root matching on-chain proposal
```

## End-to-End Flow

```sh
# 1. Fund contract (anyone)
cast send <CONTRACT> "fund()" --value <amount> --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY"

# 2. Propose (proposer only)
cast send <CONTRACT> "propose(bytes32,uint256,string)" <root> <total> <uri> --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PROPOSER_PRIVATE_KEY"

# 3. Optional: Dispute (anyone, within 3 days)
cast send <CONTRACT> "dispute(string)" <evidenceURI> --value <bond> --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY"

# 4. Jurors vote (jurors only)
cast send <CONTRACT> "resolveDispute(bool)" <true|false> --rpc-url "$SEPOLIA_RPC_URL" --private-key "$JUROR_PRIVATE_KEY"

# 5. Finalize (anyone, after dispute window)
cast send <CONTRACT> "finalize()" --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY"

# 6. Claim (recipients)
cast send <CONTRACT> "claim(address,uint256,bytes32[])" <recipient> <amount> <proof> --rpc-url "$SEPOLIA_RPC_URL" --private-key "$RECIPIENT_PRIVATE_KEY"
```

## Deploy

```sh
# build
forge build

# test
forge test

# deploy to sepolia (requires 15M gas limit)
forge create src/DeepFundingPayout.sol:DeepFundingPayout \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  --gas-limit 15000000 \
  --constructor-args "$PROPOSER" "[$JUROR_1]"
```

## Frontend

```sh
cd web
npm install
npm run dev
# Opens at http://localhost:5175
```

The frontend displays the reproducible allocation, Merkle root, contract state, and allows claiming via wallet connection.

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