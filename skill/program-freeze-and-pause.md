# Program Freeze & Pause

> This skill covers emergency controls: pausing program instructions, freezing mint authority,
> revoking upgrade authority, and coordinating Squads v4 multisig emergency proposals.

---

## Emergency Pause Architecture

The most important thing to know upfront: *Solana programs do not have a universal pause switch.*
Pause capability must be built in. This skill covers both scenarios:

1. You have a pause/emergency mechanism built in — how to invoke it
2. You do not — what options still exist and what you should do next time

---

## Option A — You Have a Built-In Emergency Pause

### Anchor programs with emergency pause

If your program has an `emergency_pause` instruction or similar:

```rust
// Standard pattern — what your instruction should look like
#[derive(Accounts)]
pub struct EmergencyPause<'info> {
    #[account(
        mut,
        seeds = [b"config"],
        bump,
        has_one = pause_authority
    )]
    pub config: Account<'info, ProtocolConfig>,
    pub pause_authority: Signer<'info>,
}

pub fn emergency_pause(ctx: Context<EmergencyPause>) -> Result<()> {
    ctx.accounts.config.paused = true;
    emit!(EmergencyPaused {
        timestamp: Clock::get()?.unix_timestamp,
        authority: ctx.accounts.pause_authority.key(),
    });
    Ok(())
}
```

To invoke this from CLI:
```bash
# Using Anchor CLI
anchor run pause -- --provider.cluster mainnet-beta

# Or with a custom script
npx ts-node scripts/emergency-pause.ts --cluster mainnet-beta --keypair ~/.config/solana/pause-authority.json
```

### Squads v4 — Multisig emergency proposal

If your pause authority is a Squads v4 multisig:

```typescript
import { Multisig } from "@sqds/multisig";
import { Connection, PublicKey, TransactionInstruction } from "@solana/web3.js";

const connection = new Connection("https://mainnet.helius-rpc.com/?api-key=YOUR_KEY");

// Step 1: Create the pause instruction
const pauseIx: TransactionInstruction = await buildEmergencyPauseInstruction(
  programId,
  configPda,
  multisigPda // pause authority is the multisig
);

// Step 2: Create a vault transaction proposal
const [multisigPda] = Multisig.pda.multisigPda({ createKey: MULTISIG_CREATE_KEY });
const [vaultPda] = Multisig.pda.vaultPda({ multisigPda, index: 0 });

const { signature: createTxSignature } = await Multisig.rpc.vaultTransactionCreate({
  connection,
  feePayer: SIGNER_WALLET,
  multisigPda,
  transactionIndex: BigInt(currentIndex + 1),
  creator: SIGNER_WALLET.publicKey,
  vaultIndex: 0,
  ephemeralSigners: 0,
  transactionMessage: {
    instructions: [pauseIx],
    addressLookupTableAccounts: [],
  },
  memo: "EMERGENCY PAUSE — Active exploit in progress",
});

// Step 3: Approve — coordinate all required signers NOW
// Each signer runs:
const { signature: approveSignature } = await Multisig.rpc.proposalApprove({
  connection,
  feePayer: SIGNER_KEYPAIR,
  multisigPda,
  transactionIndex: BigInt(currentIndex + 1),
  member: SIGNER_KEYPAIR,
});

// Step 4: Execute when threshold reached
const { signature: executeSignature } = await Multisig.rpc.vaultTransactionExecute({
  connection,
  feePayer: EXECUTOR_KEYPAIR,
  multisigPda,
  transactionIndex: BigInt(currentIndex + 1),
  member: EXECUTOR_KEYPAIR,
});
```

---

## Option B — No Built-In Pause (Emergency Fallback Options)

If your program has no pause mechanism, you have fewer options but still have some.

### Upgrade the program to a paused version

If you hold upgrade authority (or it is a multisig you can quickly coordinate):

```bash
# Step 1: Build a version of your program that rejects all instructions
# Add this at the top of every instruction handler:
# require!(!config.paused, ErrorCode::ProtocolPaused);
# Then set paused = true in the account data on initialization of this emergency build

# Step 2: Build the emergency binary
anchor build -- --features emergency_pause

# Step 3: Deploy upgrade
solana program deploy \
  --program-id YOUR_PROGRAM_ID \
  --upgrade-authority YOUR_AUTHORITY_KEYPAIR \
  target/deploy/your_program.so \
  --url mainnet-beta
```

*WARNING:* Upgrading a program during an exploit is a serious action. Coordinate with legal first if time permits. In fast-moving exploits, teams have sometimes had to make this call in under 5 minutes.

### Close program data accounts (nuclear option)

This makes the program permanently non-functional. Only for total loss situations.

```bash
# Only do this if the program is beyond saving and you want to prevent further exploitation
solana program close YOUR_PROGRAM_ID \
  --upgrade-authority YOUR_AUTHORITY_KEYPAIR \
  --bypass-warning \
  --url mainnet-beta
```

---

## Freezing Mint Authority

If attackers have access to your token's mint authority:

```typescript
import { createSetAuthorityInstruction, AuthorityType } from "@solana/spl-token";
import { Connection, Transaction, sendAndConfirmTransaction } from "@solana/web3.js";

const connection = new Connection("https://mainnet.helius-rpc.com/?api-key=YOUR_KEY");

// Option 1: Set mint authority to null (permanent — cannot be undone)
const setNullAuthorityTx = new Transaction().add(
  createSetAuthorityInstruction(
    MINT_ADDRESS,          // mint account
    CURRENT_AUTHORITY,     // current authority (must sign)
    AuthorityType.MintTokens,
    null                   // null = permanently revoke
  )
);

const sig = await sendAndConfirmTransaction(
  connection,
  setNullAuthorityTx,
  [AUTHORITY_KEYPAIR],
  { commitment: "confirmed" }
);

console.log("Mint authority revoked:", sig);
```

```typescript
// Option 2: Transfer mint authority to a cold multisig
const transferAuthorityTx = new Transaction().add(
  createSetAuthorityInstruction(
    MINT_ADDRESS,
    CURRENT_AUTHORITY,
    AuthorityType.MintTokens,
    COLD_MULTISIG_ADDRESS  // transfer to safe multisig
  )
);
```

---

## Freezing Token Accounts

If your token has freeze authority enabled (Token-2022 or legacy SPL with freeze), you can freeze attacker accounts:

```typescript
import { createFreezeAccountInstruction } from "@solana/spl-token";

// Freeze the attacker's token account
const freezeTx = new Transaction().add(
  createFreezeAccountInstruction(
    ATTACKER_TOKEN_ACCOUNT,   // account to freeze
    MINT_ADDRESS,             // mint
    FREEZE_AUTHORITY_KEYPAIR.publicKey  // freeze authority
  )
);

const sig = await sendAndConfirmTransaction(
  connection,
  freezeTx,
  [FREEZE_AUTHORITY_KEYPAIR],
  { commitment: "confirmed" }
);
```

Note: Freeze authority must have been set at mint creation. If you don't have it, you cannot freeze accounts.

---

## Revoking Upgrade Authority (Post-Incident Hardening)

After containment, consider permanently revoking upgrade authority or transferring to a timelock:

```bash
# Option 1: Transfer to Squads multisig (recommended)
solana program set-upgrade-authority YOUR_PROGRAM_ID \
  --new-upgrade-authority YOUR_SQUADS_MULTISIG_VAULT \
  --upgrade-authority CURRENT_AUTHORITY_KEYPAIR \
  --url mainnet-beta

# Option 2: Make program immutable (cannot be upgraded ever again)
solana program set-upgrade-authority YOUR_PROGRAM_ID \
  --final \
  --upgrade-authority CURRENT_AUTHORITY_KEYPAIR \
  --url mainnet-beta
```

---

## Emergency Freeze Checklist

```
PROGRAM FREEZE CHECKLIST

[ ] All multisig signers notified and reachable
[ ] Incident snapshot taken before any changes
[ ] Attack vector understood well enough to know freeze will stop it
[ ] Legal/security advisor notified (if time permits)

EXECUTION:
[ ] Emergency pause instruction proposed in Squads
[ ] Threshold of signers approved the proposal
[ ] Transaction executed and confirmed
[ ] New transactions to your program are failing (verified)
[ ] Mint authority frozen or transferred (if applicable)
[ ] Freeze applied to attacker token accounts (if applicable)

POST-FREEZE:
[ ] Confirming no new drain transactions in last 5 minutes
[ ] Recording freeze transaction signature for post-mortem
[ ] Moving to liquidity-migration.md to protect remaining funds
[ ] Drafting initial public communication (skill/crisis-communication.md)
```

---

## Emergency Contacts for Upgrade Authority Coordination

If your upgrade authority is held by a third party (e.g., you used a multisig service):

- Squads Protocol support: https://discord.gg/squads — #emergency channel
- If upgrade authority is on a hardware wallet that is physically inaccessible: contact OtterSec or Neodyme — they have handled this

---

## What Happens If You Cannot Freeze

If you have lost upgrade authority, the attacker controls it, or your multisig cannot reach threshold:

1. Immediately move to `skill/liquidity-migration.md` — protect what can still be protected
2. Contact Solana Foundation security: security@solana.org — in extreme cases they have coordinated with validators
3. Contact exchange security teams to flag the attacker wallet
4. Move to `skill/crisis-communication.md` — transparency is now your only tool
