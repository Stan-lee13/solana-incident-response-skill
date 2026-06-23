# Liquidity Migration & Fund Recovery

> Load this skill when you need to move user funds or protocol-owned liquidity to safety
> during or immediately after an active exploit.

---

## The Core Principle

During an exploit, your objective is not to fight the attacker. It is to minimize the total loss.
Every second you spend trying to understand the attack is a second funds can still be drained.
Run the freeze and migration in parallel where possible.

---

## Assessing What Can Be Saved

Before moving anything, understand the landscape:

```typescript
import { Connection, PublicKey } from "@solana/web3.js";
import { TOKEN_PROGRAM_ID, getAccount, getMint } from "@solana/spl-token";

const connection = new Connection("https://mainnet.helius-rpc.com/?api-key=YOUR_KEY", "confirmed");

// Get all token accounts owned by your program vault
async function assessProtocolFunds(vaultAuthority: PublicKey) {
  const tokenAccounts = await connection.getTokenAccountsByOwner(
    vaultAuthority,
    { programId: TOKEN_PROGRAM_ID }
  );
  
  const holdings = await Promise.all(
    tokenAccounts.value.map(async ({ pubkey, account }) => {
      const parsed = await getAccount(connection, pubkey);
      return {
        address: pubkey.toString(),
        mint: parsed.mint.toString(),
        amount: parsed.amount.toString(),
        isFrozen: parsed.isFrozen,
      };
    })
  );
  
  console.log("Protocol holdings:", JSON.stringify(holdings, null, 2));
  return holdings;
}
```

---

## Draining Protocol-Owned Liquidity Pools

### Meteora DLMM emergency withdrawal

```typescript
import DLMM from "@meteora-ag/dlmm";
import { Connection, PublicKey, Keypair } from "@solana/web3.js";
import { BN } from "@coral-xyz/anchor";

const connection = new Connection("https://mainnet.helius-rpc.com/?api-key=YOUR_KEY");

async function emergencyWithdrawDLMM(
  poolAddress: PublicKey,
  ownerKeypair: Keypair,
  safeDestination: PublicKey
) {
  const dlmmPool = await DLMM.create(connection, poolAddress);
  
  // Get all positions owned by your protocol
  const { userPositions } = await dlmmPool.getPositionsByUserAndLbPair(
    ownerKeypair.publicKey
  );
  
  for (const position of userPositions) {
    // Remove all liquidity from each position
    const removeLiquidityTx = await dlmmPool.removeLiquidity({
      user: ownerKeypair.publicKey,
      position: position.publicKey,
      fromBinId: position.positionData.lowerBinId,
      toBinId: position.positionData.upperBinId,
      bps: new BN(10000), // 100% — remove everything
      shouldClaimAndClose: true,
    });
    
    const sig = await sendAndConfirmTransaction(
      connection,
      removeLiquidityTx,
      [ownerKeypair],
      { commitment: "confirmed", maxRetries: 5 }
    );
    
    console.log(`Withdrawn from position ${position.publicKey.toString()}: ${sig}`);
  }
}
```

### Orca Whirlpools emergency withdrawal

```typescript
import { WhirlpoolContext, buildWhirlpoolClient, ORCA_WHIRLPOOL_PROGRAM_ID } from "@orca-so/whirlpools-sdk";
import { AnchorProvider } from "@coral-xyz/anchor";
import Decimal from "decimal.js";

async function emergencyWithdrawOrca(
  whirlpoolAddress: PublicKey,
  ownerKeypair: Keypair
) {
  const provider = new AnchorProvider(connection, new Wallet(ownerKeypair), {});
  const ctx = WhirlpoolContext.withProvider(provider, ORCA_WHIRLPOOL_PROGRAM_ID);
  const client = buildWhirlpoolClient(ctx);
  
  const whirlpool = await client.getPool(whirlpoolAddress);
  
  // Get all positions
  const positionAddresses = await ctx.program.account.position.all([
    { memcmp: { offset: 8, bytes: ownerKeypair.publicKey.toBase58() } }
  ]);
  
  for (const posAccount of positionAddresses) {
    const position = await client.getPosition(posAccount.publicKey);
    
    // Decrease liquidity to zero
    const decreaseLiquidityTx = await position.decreaseLiquidity({
      liquidityAmount: position.getData().liquidity,
      tokenMinA: new Decimal(0),
      tokenMinB: new Decimal(0),
    });
    
    await decreaseLiquidityTx.buildAndExecute();
    
    // Collect fees and rewards
    await position.collectFees();
    
    // Close position
    await position.close({ destinationWallet: ownerKeypair.publicKey });
    
    console.log(`Closed Orca position: ${posAccount.publicKey.toString()}`);
  }
}
```

---

## Moving Funds to a Safe Wallet

During an exploit, your hot wallet may be compromised. Move to a fresh cold wallet.

```typescript
import {
  createTransferInstruction,
  getAssociatedTokenAddressSync,
  createAssociatedTokenAccountInstruction,
  TOKEN_PROGRAM_ID,
  ASSOCIATED_TOKEN_PROGRAM_ID,
} from "@solana/spl-token";
import {
  Connection,
  Transaction,
  sendAndConfirmTransaction,
  ComputeBudgetProgram,
} from "@solana/web3.js";

async function emergencyTokenTransfer(
  mint: PublicKey,
  sourceOwner: Keypair,
  safeDestination: PublicKey, // freshly generated cold wallet
  amount: bigint
) {
  const sourceATA = getAssociatedTokenAddressSync(mint, sourceOwner.publicKey);
  const destATA = getAssociatedTokenAddressSync(mint, safeDestination);
  
  const tx = new Transaction();
  
  // High priority fee — during an exploit, network congestion may spike
  tx.add(
    ComputeBudgetProgram.setComputeUnitPrice({ microLamports: 500_000 })
  );
  
  // Create destination ATA if it doesn't exist
  const destAccount = await connection.getAccountInfo(destATA);
  if (!destAccount) {
    tx.add(
      createAssociatedTokenAccountInstruction(
        sourceOwner.publicKey,
        destATA,
        safeDestination,
        mint
      )
    );
  }
  
  // Transfer
  tx.add(
    createTransferInstruction(
      sourceATA,
      destATA,
      sourceOwner.publicKey,
      amount
    )
  );
  
  const sig = await sendAndConfirmTransaction(
    connection,
    tx,
    [sourceOwner],
    { commitment: "confirmed", maxRetries: 10 }
  );
  
  console.log(`Transferred ${amount} tokens to safe wallet: ${sig}`);
  return sig;
}
```

---

## White Hat Front-Running (Advanced)

In some exploits, you know the attack vector and can front-run the attacker to drain your own funds to safety before they reach them. This is legally complex but has saved millions of dollars.

```typescript
// Concept: Use Jito bundles to land your drain transaction before the attacker's
import { SearcherClient, Bundle } from "jito-ts/dist/sdk/block-engine/searcher";
import { Connection, VersionedTransaction } from "@solana/web3.js";

const searcherClient = SearcherClient.searcherClient(
  "amsterdam.mainnet.block-engine.jito.wtf"
);

// Build your emergency drain transaction
const drainTx = await buildEmergencyDrainTransaction(/* ... */);

// Submit as a Jito bundle for guaranteed ordering
const bundle = new Bundle([drainTx], 5);
const { result } = await searcherClient.sendBundle(bundle);

console.log("Emergency bundle submitted:", result);
```

*Important:* Front-running is a significant legal and ethical decision. Consult legal immediately. Document everything. Many protocols have successfully used this to save user funds — it is defensible if the intent and execution are transparent.

---

## Tracking the Attacker's Funds

Even if you cannot stop the exploit, tracking where funds go is critical for recovery:

```bash
# Use Helius to trace attacker wallet movements
curl "https://api.helius.xyz/v0/addresses/ATTACKER_WALLET/transactions?api-key=YOUR_KEY&limit=50" \
  | jq '[.[] | {
      signature: .signature,
      timestamp: .timestamp,
      type: .type,
      tokenTransfers: .tokenTransfers,
      nativeTransfers: .nativeTransfers
    }]' > attacker_trace_$(date +%s).json

# Watch for bridging activity (Wormhole, deBridge, Allbridge)
# If funds hit a bridge, you have minutes to contact bridge security teams
```

*Bridge security contacts (have these ready):*
- Wormhole: https://wormhole.com/contact — report asset theft immediately
- deBridge: https://debridge.finance — security@debridge.finance
- Allbridge: https://allbridge.io — they have frozen funds in past incidents

---

## Fund Recovery After the Fact

### White hat negotiation

Many exploiters return funds when offered a bug bounty. Industry standard: 10% of recovered funds.

Template DM to attacker wallet (via on-chain memo or Etherscan/Solscan message):

```
We are aware of the exploit from [DATE]. We invite you to contact [EMAIL] 
to discuss a responsible disclosure bounty of [10% of stolen amount] for 
returning the remaining funds. No legal action will be taken if funds are 
returned within 72 hours. After this window, we will pursue all available 
legal remedies.
```

### On-chain message to attacker

```typescript
import { SystemProgram, Transaction, TransactionInstruction } from "@solana/web3.js";

// Send 0 SOL with a memo to the attacker's wallet
const memoIx = new TransactionInstruction({
  keys: [],
  programId: new PublicKey("MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr"),
  data: Buffer.from(
    "We know what happened. Contact security@yourprotocol.com within 72 hours. We offer 10% as bounty. After that, law enforcement has been notified.",
    "utf8"
  )
});
```

### Insurance Claims

If you have DeFi insurance (Nexus Mutual, InsurAce, Sherlock):
- File claim within 72 hours of confirmed exploit
- Required documentation: attack transaction signatures, total loss calculation, post-mortem report
- Sherlock: https://app.sherlock.xyz/protocols — file claim
- Nexus Mutual: https://nexusmutual.io/claims — file claim

---

## Migration Completion Checklist

```
LIQUIDITY MIGRATION CHECKLIST

[ ] All DEX positions (Meteora/Orca/Raydium) withdrawn
[ ] Protocol-owned SOL moved to cold wallet
[ ] Protocol-owned token accounts drained and closed
[ ] Transfer signatures recorded for all movements
[ ] Attacker wallet(s) documented and traced
[ ] Bridge security teams notified if funds are moving cross-chain
[ ] Insurance claim initiated (if applicable)
[ ] White hat negotiation message sent to attacker wallet
[ ] All actions documented with timestamps for post-mortem
```
