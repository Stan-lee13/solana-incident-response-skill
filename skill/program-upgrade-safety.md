# Program Upgrade Safety & State Migration

The most dangerous operation in Solana development — and the most under-tooled.

Upgrading a program that has live user funds is not a deployment. It is a coordinated
production operation with real financial consequences if it goes wrong. This skill
covers the complete playbook: pre-upgrade validation, safe state migration, IDL drift
detection, and rollback procedures.

## No competitor skill covers this. This is the gap

---

## The Three Failure Modes of Solana Program Upgrades

### 1. Account Layout Mismatch (Silent Data Corruption)

You add a new field to an account struct. Old accounts have 200 bytes. New struct expects 220 bytes. The program attempts to deserialize old accounts — and either panics or silently reads garbage into the new field.

```rust
// Old account — 200 bytes on-chain
#[account]
pub struct UserPosition {
    pub owner: Pubkey,      // 32 bytes
    pub amount: u64,        // 8 bytes
    pub opened_at: i64,     // 8 bytes
    // ... more fields = 200 bytes total
}

// New account — if you just add this field without migration:
#[account]
pub struct UserPosition {
    pub owner: Pubkey,
    pub amount: u64,
    pub opened_at: i64,
    pub leverage: u8,       // ← New field. Old accounts don't have this byte.
    // Old accounts → garbled data on read
}

```

### 2. IDL Client Drift (Silent Frontend Failure)

Your frontend still uses the old IDL. Users submit transactions that reference old instruction discriminators. The new program rejects them with a cryptic error. Users think your dApp is broken.

### 3. Authority Takeover (Human Error Under Pressure)

During a rushed upgrade, the wrong keypair is used, or authority is not properly transferred to the new program state. Upgrade authority is now lost or held by the wrong party.

---

## Pre-Upgrade Validation Checklist

Run this BEFORE every upgrade. No exceptions.

```bash
#!/bin/bash

## pre-upgrade-check.sh — Run before every program upgrade

PROGRAM_ID="${1:?Usage: $0 <PROGRAM_ID>}"
CLUSTER="${2:-mainnet-beta}"
NEW_BINARY="${3:?Must provide new .so file path}"

echo "=== Pre-Upgrade Validation for $PROGRAM_ID ==="
echo ""

## 1. Verify upgrade authority

echo "[1/7] Checking upgrade authority..."
AUTHORITY=$(solana program show $PROGRAM_ID --url $CLUSTER | grep "Upgrade Authority" | awk '{print $NF}')
echo "  Current upgrade authority: $AUTHORITY"
echo "  Is this the expected multisig? [y/N]"
read -r confirm
[[ "$confirm" != "y" ]] && echo "ABORT: Authority mismatch." && exit 1

## 2. Verify program is actually upgradeable

echo "[2/7] Checking program is upgradeable..."
IS_UPGRADEABLE=$(solana program show $PROGRAM_ID --url $CLUSTER | grep "Upgradeable")
if [ -z "$IS_UPGRADEABLE" ]; then
  echo "  ❌ ABORT: Program is not upgradeable (authority revoked)"
  exit 1
fi
echo "  ✅ Program is upgradeable"

## 3. Check current deployment size vs new binary

echo "[3/7] Checking binary sizes..."
CURRENT_SIZE=$(solana program show $PROGRAM_ID --url $CLUSTER | grep "Data Length" | awk '{print $NF}')
NEW_SIZE=$(wc -c < "$NEW_BINARY")
echo "  Current on-chain size: $CURRENT_SIZE bytes"
echo "  New binary size: $NEW_SIZE bytes"
if [ "$NEW_SIZE" -gt "$CURRENT_SIZE" ]; then
  echo "  ⚠️  New binary is LARGER — upgrade will cost additional SOL for storage"
  EXTRA_BYTES=$((NEW_SIZE - CURRENT_SIZE))
  EXTRA_LAMPORTS=$((EXTRA_BYTES * 100))  # ~100 lamports per byte, rough estimate
  echo "  Estimated additional cost: ~$EXTRA_LAMPORTS lamports"
fi

## 4. Build verification

echo "[4/7] Verifying reproducible build..."
anchor verify $PROGRAM_ID --provider.cluster $CLUSTER --program-name my_program 2>&1
if [ $? -ne 0 ]; then
  echo "  ⚠️  Build verification failed — source may not match deployed binary"
fi

## 5. Check account count (migration impact)

echo "[5/7] Checking account count..."

## Use Helius API to count existing accounts

ACCOUNT_COUNT=$(curl -s "https://mainnet.helius-rpc.com/?api-key=$HELIUS_API_KEY" \
  -X POST -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getProgramAccounts\",\"params\":[\"$PROGRAM_ID\",{\"encoding\":\"base64\",\"dataSlice\":{\"offset\":0,\"length\":0}}]}" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('result',[])))")
echo "  Accounts to migrate: $ACCOUNT_COUNT"
if [ "$ACCOUNT_COUNT" -gt 10000 ]; then
  echo "  ⚠️  Large migration — lazy migration pattern required (accounts migrate on next touch)"
fi

## 6. Simulate the upgrade

echo "[6/7] Simulating upgrade transaction..."
solana program deploy $NEW_BINARY \
  --program-id $PROGRAM_ID \
  --url $CLUSTER \
  --simulate 2>&1 | head -20

## 7. Confirm backup of current binary

echo "[7/7] Current binary backup..."
solana program dump $PROGRAM_ID /tmp/backup_${PROGRAM_ID}_$(date +%Y%m%d_%H%M%S).so --url $CLUSTER
echo "  ✅ Current binary backed up to /tmp/"

echo ""
echo "=== Pre-upgrade validation complete ==="
echo "Proceed with upgrade? This will affect $ACCOUNT_COUNT live user accounts. [yes/abort]"
read -r final_confirm
[[ "$final_confirm" != "yes" ]] && echo "Upgrade aborted by operator." && exit 0
echo "Proceeding..."

```

---

## Account Versioning Pattern (Safe State Migration)

The only safe way to add fields to existing accounts without breaking old data.

```rust
// programs/my_protocol/src/state.rs

use anchor_lang::prelude::*;

/// Version field is ALWAYS the first byte.
/// This is your migration contract — never change this layout.
#[account]
pub struct UserPosition {
    pub version: u8,           // ALWAYS first — discriminates migration state
    pub owner: Pubkey,         // 32 bytes
    pub amount: u64,           // 8 bytes  
    pub opened_at: i64,        // 8 bytes
    // Future fields added here — with defaults handled in migrate()
    pub leverage: Option<u8>,  // Added in v2 — Option<T> is backward safe
    pub risk_tier: u8,         // Added in v2 — with default=0 in migration
}

impl UserPosition {
    pub const CURRENT_VERSION: u8 = 2;

    pub fn migrate_if_needed(&mut self) -> bool {
        match self.version {
            Self::CURRENT_VERSION => false, // Already current
            1 => {
                // Migrate from v1: set defaults for new fields
                self.leverage = None;
                self.risk_tier = 0; // Conservative default
                self.version = 2;
                true // Account was migrated
            }
            _ => panic!("Unknown account version: {}", self.version),
        }
    }
}

/// Every instruction that reads UserPosition must call this first
/// This is "lazy migration" — accounts upgrade on next interaction
#[instruction]
pub fn any_instruction(ctx: Context<AnyCtx>, ...) -> Result<()> {
    let position = &mut ctx.accounts.user_position;
    
    let was_migrated = position.migrate_if_needed();
    if was_migrated {
        msg!("Migrated account {} from older version", ctx.accounts.user_position.key());
    }
    
    // Now safely use position fields — guaranteed to be v2 layout
    Ok(())
}

```

---

## IDL Drift Detection

When you upgrade a program, the on-chain IDL and client-side IDL must stay in sync.
This script detects drift before it causes user-facing failures.

```typescript
// scripts/check-idl-drift.ts
import { AnchorProvider, Program, Idl } from "@coral-xyz/anchor";
import { Connection, PublicKey } from "@solana/web3.js";
import * as fs from "fs";
import * as crypto from "crypto";

const PROGRAM_ID = new PublicKey(process.env.PROGRAM_ID!);

interface DriftReport {
  status: "in_sync" | "drifted" | "idl_missing";
  onChainInstructionNames: string[];
  clientInstructionNames: string[];
  addedInstructions: string[];  // In on-chain, not in client IDL
  removedInstructions: string[]; // In client IDL, not on-chain
  changedInstructions: Array<{
    name: string;
    clientArgs: string[];
    onChainArgs: string[];
  }>;
}

async function detectIdlDrift(clientIdlPath: string): Promise<DriftReport> {
  const connection = new Connection(process.env.HELIUS_RPC_URL!);
  
  // Fetch on-chain IDL
  const onChainIdlAddress = PublicKey.findProgramAddressSync(
    [Buffer.from("anchor:idl"), PROGRAM_ID.toBuffer()],
    PROGRAM_ID
  )[0];
  
  const onChainAccount = await connection.getAccountInfo(onChainIdlAddress);
  if (!onChainAccount) {
    return { status: "idl_missing", onChainInstructionNames: [], clientInstructionNames: [], 
             addedInstructions: [], removedInstructions: [], changedInstructions: [] };
  }
  
  // Decode on-chain IDL (Anchor stores compressed IDL)
  const onChainIdl = decodeAnchorIdl(onChainAccount.data) as Idl;
  const clientIdl = JSON.parse(fs.readFileSync(clientIdlPath, "utf-8")) as Idl;
  
  const onChainIxNames = new Set(onChainIdl.instructions.map(ix => ix.name));
  const clientIxNames = new Set(clientIdl.instructions.map(ix => ix.name));
  
  const addedInstructions = [...onChainIxNames].filter(n => !clientIxNames.has(n));
  const removedInstructions = [...clientIxNames].filter(n => !onChainIxNames.has(n));
  
  // Check argument changes on matching instructions
  const changedInstructions = onChainIdl.instructions
    .filter(ix => clientIxNames.has(ix.name))
    .map(onChainIx => {
      const clientIx = clientIdl.instructions.find(ix => ix.name === onChainIx.name)!;
      const onChainArgs = onChainIx.args.map(a => `${a.name}:${a.type}`);
      const clientArgs = clientIx.args.map(a => `${a.name}:${a.type}`);
      const isDifferent = JSON.stringify(onChainArgs) !== JSON.stringify(clientArgs);
      return isDifferent ? { name: onChainIx.name, clientArgs, onChainArgs } : null;
    })
    .filter(Boolean) as DriftReport['changedInstructions'];
  
  const hasDrift = addedInstructions.length > 0 || removedInstructions.length > 0 || changedInstructions.length > 0;
  
  return {
    status: hasDrift ? "drifted" : "in_sync",
    onChainInstructionNames: [...onChainIxNames],
    clientInstructionNames: [...clientIxNames],
    addedInstructions,
    removedInstructions,
    changedInstructions,
  };
}

async function main() {
  const report = await detectIdlDrift("./target/idl/my_protocol.json");
  
  if (report.status === "in_sync") {
    console.log("✅ IDL in sync — on-chain program matches client IDL");
    process.exit(0);
  }
  
  if (report.status === "idl_missing") {
    console.log("⚠️  No IDL uploaded on-chain — run: anchor idl init <PROGRAM_ID>");
    process.exit(1);
  }
  
  console.log("🚨 IDL DRIFT DETECTED\n");
  
  if (report.addedInstructions.length > 0) {
    console.log("New instructions on-chain (not in client IDL):");
    report.addedInstructions.forEach(n => console.log(`  + ${n}`));
    console.log("  → Run: anchor idl upgrade <PROGRAM_ID> --filepath target/idl/my_protocol.json\n");
  }
  
  if (report.removedInstructions.length > 0) {
    console.log("Instructions removed from on-chain (still in client IDL):");
    report.removedInstructions.forEach(n => console.log(`  - ${n}`));
    console.log("  → WARNING: Frontend clients calling these will fail\n");
  }
  
  if (report.changedInstructions.length > 0) {
    console.log("Instructions with argument changes:");
    report.changedInstructions.forEach(ix => {
      console.log(`  ~ ${ix.name}`);
      console.log(`    Client args: ${ix.clientArgs.join(", ")}`);
      console.log(`    On-chain args: ${ix.onChainArgs.join(", ")}`);
    });
  }
  
  process.exit(1);
}

```

---

## Safe Upgrade Procedure (Step by Step)

```

PHASE 1 — BEFORE UPGRADE (T-48h to T-1h)
[ ] Run pre-upgrade-check.sh against the new binary
[ ] Run check-idl-drift.ts and confirm zero drift (or planned drift)
[ ] Deploy to devnet and run full integration test suite
[ ] Notify community: "Upgrade scheduled for [DATE TIME UTC]"
[ ] Prepare rollback binary (copy of current deployed .so)

PHASE 2 — UPGRADE WINDOW
[ ] Set maintenance mode on frontend
[ ] Confirm all signers on the multisig call
[ ] For Squads v4:
    → New Transaction → Program Upgrade → [program data address] → [new .so]
    → Collect N-of-M signatures
    → Execute transaction
[ ] For single keypair:
    → anchor upgrade target/deploy/my_program.so --program-id [ID] --provider.cluster mainnet-beta

PHASE 3 — POST-UPGRADE VERIFICATION (first 30 minutes)
[ ] Run: solana program show [PROGRAM_ID] — confirm new executable data hash
[ ] Run: anchor idl upgrade [PROGRAM_ID] — update on-chain IDL to match new binary
[ ] Run: check-idl-drift.ts — confirm zero drift
[ ] Send 1 test transaction of each instruction type on mainnet
[ ] Monitor CU usage on first real transactions (should match profiling baselines)
[ ] Disable maintenance mode
[ ] Post community update: "Upgrade complete"

PHASE 4 — MONITORING (first 24h)
[ ] Watch for account deserialization errors in logs
[ ] Monitor migration rate (how many accounts have been upgraded via lazy migration)
[ ] Watch CU usage — should be consistent with pre-upgrade baseline
[ ] Keep rollback binary and pre-upgrade IDL ready

```

---

## Emergency Rollback

If something goes wrong post-upgrade:

```bash

## Rollback to previous binary (requires upgrade authority)

solana program deploy /tmp/backup_${PROGRAM_ID}_TIMESTAMP.so \
  --program-id $PROGRAM_ID \
  --url mainnet-beta

## If using Squads multisig

## → Emergency proposal: "Rollback to backup binary"

## → Coordinate all signers — this needs to happen in < 30 minutes

## After rollback

## → Rollback the on-chain IDL too

anchor idl upgrade $PROGRAM_ID --filepath target/idl/PREVIOUS_VERSION.json --provider.cluster mainnet-beta

```

**Critical**: Account state written by the new program MAY be incompatible with the old binary if new fields were introduced. Rollback fixes the program logic but cannot undo account state changes. If accounts were migrated, you may need to deploy a "compatibility shim" that handles both old and new layouts rather than a true rollback.
