# Liquidity Migration & Fund Recovery

> Load when you need to move user funds or protocol-owned liquidity to safety
> during or immediately after an active exploit.
>
> Run in parallel with program-freeze-and-pause.md — do both simultaneously.

---

## Core Principle

During an exploit, your objective is not to fight the attacker. It is to minimize total loss.
Every second you spend trying to understand the attack is a second funds can still be drained.
Move first, investigate later.

---

## Step 0: Assess What Can Be Saved (2 minutes)

Before moving anything, map what you have and what is at risk.

```typescript
// scripts/incident/assess-funds.ts
import { Connection, PublicKey } from "@solana/web3.js";
import { TOKEN_PROGRAM_ID, getAccount, TOKEN_2022_PROGRAM_ID } from "@solana/spl-token";

const connection = new Connection(process.env.HELIUS_RPC_URL!, "confirmed");

export async function assessProtocolFunds(vaultAuthority: string) {
  const authority = new PublicKey(vaultAuthority);
  
  // Get all SPL Token accounts (legacy)
  const [legacyAccounts, token2022Accounts] = await Promise.all([
    connection.getTokenAccountsByOwner(authority, { programId: TOKEN_PROGRAM_ID }),
    connection.getTokenAccountsByOwner(authority, { programId: TOKEN_2022_PROGRAM_ID }),
  ]);
  
  const allAccounts = [...legacyAccounts.value, ...token2022Accounts.value];
  
  const holdings = await Promise.all(
    allAccounts.map(async ({ pubkey }) => {
      try {
        const account = await getAccount(connection, pubkey);
        return {
          address: pubkey.toString(),
          mint: account.mint.toString(),
          amount: account.amount.toString(),
          isFrozen: account.isFrozen,
          isCloseable: account.amount === 0n,
        };
      } catch {
        return null;
      }
    })
  );
  
  const active = holdings.filter(Boolean).filter(h => h!.amount !== "0");
  
  // SOL balance
  const solBalance = await connection.getBalance(authority);
  
  console.table(active);
  console.log(`SOL balance: ${solBalance / 1e9} SOL`);
  console.log(`Total token positions: ${active.length}`);
  
  return { holdings: active, solBalance };
}
```

---

## Step 1: Emergency Drain to Safe Wallet

The fastest move — transfer all token balances to a pre-designated safe wallet.

**CRITICAL**: Pre-designate this safe wallet BEFORE an incident. It should be:
- A hardware wallet you control
- Not connected to any protocol infrastructure
- Known to all core team members
- Documented in your security runbook

```typescript
// scripts/incident/emergency-drain.ts
import { Connection, PublicKey, Keypair, Transaction } from "@solana/web3.js";
import {
  createTransferInstruction,
  getOrCreateAssociatedTokenAccount,
  TOKEN_PROGRAM_ID,
} from "@solana/spl-token";
import * as fs from "fs";

const SAFE_WALLET = new PublicKey(process.env.EMERGENCY_SAFE_WALLET!);

async function emergencyDrainAllTokens(
  vaultAuthority: Keypair,
  tokenAccounts: Array<{ address: string; mint: string; amount: string }>
) {
  const connection = new Connection(process.env.HELIUS_RPC_URL!, "confirmed");
  
  // Priority order: largest balances first
  const sorted = tokenAccounts.sort((a, b) => 
    Number(BigInt(b.amount) - BigInt(a.amount))
  );
  
  const results: Array<{ mint: string; signature: string; status: string }> = [];
  
  for (const tokenAccount of sorted) {
    if (tokenAccount.amount === "0") continue;
    
    try {
      // Get or create destination ATA on the safe wallet
      const destATA = await getOrCreateAssociatedTokenAccount(
        connection,
        vaultAuthority, // Fee payer for ATA creation
        new PublicKey(tokenAccount.mint),
        SAFE_WALLET
      );
      
      const ix = createTransferInstruction(
        new PublicKey(tokenAccount.address),  // Source
        destATA.address,                       // Destination
        vaultAuthority.publicKey,              // Authority
        BigInt(tokenAccount.amount),           // Amount — drain everything
        [],
        TOKEN_PROGRAM_ID
      );
      
      const tx = new Transaction().add(ix);
      const sig = await connection.sendTransaction(tx, [vaultAuthority], {
        skipPreflight: false,
        maxRetries: 3,
      });
      
      await connection.confirmTransaction(sig, "confirmed");
      
      results.push({ mint: tokenAccount.mint, signature: sig, status: "success" });
      console.log(`✅ Drained ${tokenAccount.mint} → ${sig}`);
    } catch (err) {
      results.push({ mint: tokenAccount.mint, signature: "", status: `FAILED: ${err}` });
      console.error(`❌ Failed to drain ${tokenAccount.mint}:`, err);
    }
  }
  
  // Log all results for forensics
  fs.writeFileSync(
    `emergency-drain-log-${Date.now()}.json`,
    JSON.stringify(results, null, 2)
  );
  
  return results;
}
```

---

## Step 2: Meteora DLMM Emergency Withdrawal

```typescript
import DLMM from "@meteora-ag/dlmm";
import { BN } from "@coral-xyz/anchor";
import { Connection, PublicKey, Keypair } from "@solana/web3.js";

export async function emergencyWithdrawDLMM(
  poolAddress: string,
  ownerKeypair: Keypair,
  safeDestination: PublicKey
) {
  const connection = new Connection(process.env.HELIUS_RPC_URL!, "confirmed");
  const poolPubkey = new PublicKey(poolAddress);
  
  const dlmmPool = await DLMM.create(connection, poolPubkey);
  
  // Get all positions owned by this keypair
  const { userPositions } = await dlmmPool.getPositionsByUserAndLbPair(
    ownerKeypair.publicKey
  );
  
  if (userPositions.length === 0) {
    console.log("No positions found in this DLMM pool");
    return;
  }
  
  console.log(`Found ${userPositions.length} positions — withdrawing all...`);
  
  for (const position of userPositions) {
    const binIds = [];
    const liquidityShares = [];
    
    for (const binData of position.positionData.positionBinData) {
      if (!new BN(binData.positionLiquidityShare).isZero()) {
        binIds.push(binData.binId);
        liquidityShares.push(new BN(binData.positionLiquidityShare));
      }
    }
    
    if (binIds.length === 0) continue;
    
    try {
      const removeTxs = await dlmmPool.removeLiquidity({
        user: ownerKeypair.publicKey,
        position: position.publicKey,
        fromBinId: Math.min(...binIds),
        toBinId: Math.max(...binIds),
        bps: new BN(10000), // 100% — drain everything
        shouldClaimAndClose: true, // Close position to reclaim rent
      });
      
      for (const tx of removeTxs) {
        tx.sign([ownerKeypair]);
        const sig = await connection.sendRawTransaction(tx.serialize(), {
          skipPreflight: false,
          maxRetries: 3,
        });
        await connection.confirmTransaction(sig, "confirmed");
        console.log(`✅ DLMM position removed: ${sig}`);
      }
    } catch (err) {
      console.error(`❌ Failed to remove DLMM position ${position.publicKey.toString()}:`, err);
    }
  }
}
```

---

## Step 3: Orca Whirlpool Emergency Withdrawal

```typescript
import { WhirlpoolClient, buildWhirlpoolClient, ORCA_WHIRLPOOL_PROGRAM_ID } from "@orca-so/whirlpools-sdk";
import { AnchorProvider } from "@coral-xyz/anchor";
import { Connection, PublicKey, Keypair } from "@solana/web3.js";
import NodeWallet from "@coral-xyz/anchor/dist/cjs/nodewallet";
import Decimal from "decimal.js";

export async function emergencyWithdrawWhirlpool(
  poolAddress: string,
  ownerKeypair: Keypair
) {
  const connection = new Connection(process.env.HELIUS_RPC_URL!, "confirmed");
  const provider = new AnchorProvider(
    connection,
    new NodeWallet(ownerKeypair),
    { commitment: "confirmed" }
  );
  
  const client: WhirlpoolClient = buildWhirlpoolClient(provider);
  const pool = await client.getPool(new PublicKey(poolAddress));
  
  // Get all positions
  const positionAddresses = await client.getAllPositionsOf(pool, ownerKeypair.publicKey);
  
  for (const positionAddress of positionAddresses) {
    const position = await client.getPosition(positionAddress);
    const positionData = position.getData();
    
    if (positionData.liquidity.isZero()) continue;
    
    try {
      // Collect fees and rewards before removing liquidity
      const collectTx = await position.collectFees(true);
      if (collectTx) {
        await collectTx.buildAndExecute();
        console.log(`✅ Collected fees from Whirlpool position ${positionAddress.toString()}`);
      }
      
      // Remove all liquidity (100%)
      const removeTx = await position.decreaseLiquidity({
        liquidityAmount: positionData.liquidity,
        tokenMinA: new Decimal(0), // Accept any amount in emergency
        tokenMinB: new Decimal(0),
      });
      await removeTx.buildAndExecute();
      console.log(`✅ Removed Whirlpool liquidity from ${positionAddress.toString()}`);
      
      // Close position to reclaim rent
      const closeTx = await position.close({ 
        receiver: ownerKeypair.publicKey 
      });
      await closeTx.buildAndExecute();
      
    } catch (err) {
      console.error(`❌ Failed to withdraw from Whirlpool position ${positionAddress}:`, err);
    }
  }
}
```

---

## Step 4: Raydium CLMM Emergency Withdrawal

```typescript
import Raydium, { CLMM_PROGRAM_ID } from "@raydium-io/raydium-sdk-v2";
import { Connection, PublicKey, Keypair } from "@solana/web3.js";

export async function emergencyWithdrawRaydiumCLMM(
  poolId: string,
  ownerKeypair: Keypair
) {
  const connection = new Connection(process.env.HELIUS_RPC_URL!, "confirmed");
  
  const raydium = await Raydium.load({
    connection,
    owner: ownerKeypair.publicKey,
    disableFeatureCheck: true,
    blockhashCommitment: "confirmed",
  });
  
  // Get all positions
  const positions = await raydium.clmm.getOwnerPositionInfo({
    programId: new PublicKey(CLMM_PROGRAM_ID),
  });
  
  const poolPositions = positions.filter(p => p.poolId.toString() === poolId);
  
  for (const position of poolPositions) {
    if (position.liquidity.isZero()) continue;
    
    try {
      const { execute } = await raydium.clmm.decreaseLiquidity({
        poolInfo: position.poolInfo,
        ownerPosition: position,
        liquidity: position.liquidity,
        amountMinA: new BN(0), // Accept any in emergency
        amountMinB: new BN(0),
        slippage: 1, // 100% slippage tolerance — emergency mode
      });
      
      const sig = await execute({ sendAndConfirm: true });
      console.log(`✅ Raydium CLMM position withdrawn: ${sig}`);
    } catch (err) {
      console.error(`❌ Failed to withdraw Raydium position:`, err);
    }
  }
}
```

---

## Step 5: Multisig Coordination for Mass Withdrawal

If your vault authority is a Squads v4 multisig (it should be):

```typescript
import { Multisig } from "@sqds/multisig";
import { Connection, PublicKey, TransactionInstruction } from "@solana/web3.js";

async function createEmergencyWithdrawalProposal(
  multisigPda: PublicKey,
  withdrawalInstructions: TransactionInstruction[],
  proposerKeyPair: Keypair
) {
  const connection = new Connection(process.env.HELIUS_RPC_URL!, "confirmed");
  
  const multisigInfo = await Multisig.fromAccountAddress(connection, multisigPda);
  const nextTransactionIndex = Number(multisigInfo.transactionIndex) + 1;
  
  // Create the vault transaction
  const ix = Multisig.instructions.vaultTransactionCreate({
    multisigPda,
    transactionIndex: BigInt(nextTransactionIndex),
    creator: proposerKeyPair.publicKey,
    vaultIndex: 0,
    ephemeralSigners: 0,
    transactionMessage: await buildMultisigMessage(connection, withdrawalInstructions),
    addressLookupTableAccounts: [],
    memo: `EMERGENCY WITHDRAWAL - ${new Date().toISOString()}`,
  });
  
  // Broadcast to all signers immediately via:
  // 1. Direct message to all multisig members
  // 2. Emergency Telegram/Signal group
  // 3. Phone call if needed
  
  console.log(`
  === EMERGENCY MULTISIG PROPOSAL CREATED ===
  Transaction index: ${nextTransactionIndex}
  Required signatures: ${multisigInfo.threshold}/${multisigInfo.members.length}
  
  All signers must go to: https://squads.so/dashboard/[YOUR_MULTISIG]
  AND approve transaction #${nextTransactionIndex}
  
  CALL ALL SIGNERS NOW — DO NOT USE ONLY MESSAGING
  `);
  
  return nextTransactionIndex;
}
```

---

## Emergency Withdrawal Runbook (Print This)

```
⚠️  EMERGENCY WITHDRAWAL RUNBOOK
     Keep this printed and accessible without internet

T+0:   Confirm exploit is real (check Solscan/Helius)
T+2:   Open emergency channel — wake all multisig signers
T+5:   Run: npx ts-node scripts/incident/assess-funds.ts
       Note: Total value at risk: $________

T+10:  Start all three in parallel:
       Thread 1: Run program-freeze-and-pause.md
       Thread 2: Run emergency-drain.ts for direct token accounts
       Thread 3: Create Squads proposal for LP positions

T+20:  Multisig signers approve on Squads UI
       URL: https://squads.so/dashboard/[YOUR_MULTISIG_ADDRESS]
       
T+30:  Verify all funds reached safe wallet:
       Safe wallet: [PRE-FILL THIS ADDRESS]
       Check: https://solscan.io/account/[SAFE_WALLET]

T+45:  All liquidity positions closed
T+60:  Post initial public notice (load crisis-communication.md)
```
