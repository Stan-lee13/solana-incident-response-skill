# Wallet Security — Key Compromise, Drainer Detection & Recovery

> Load this skill when a user's wallet, team member's keypair, or protocol authority
> key is suspected or confirmed to have been compromised.
>
> Also load for drainer contract detection, seed phrase exposure events, and
> private key hygiene for Solana protocol teams.

---

## Threat Classification

```
THREAT TYPE 1: TEAM AUTHORITY KEY COMPROMISE
  Private key or seed phrase for upgrade authority, mint authority, treasury,
  or multisig signer is leaked or captured.
  Impact: Attacker can upgrade programs, mint tokens, drain vaults.
  Severity: P0 immediately — treat as active exploit.

THREAT TYPE 2: USER WALLET DRAINER
  Malicious dApp or transaction request steals user approval to drain their wallet.
  Impact: Individual user loss; reputational damage if via your frontend.
  Severity: P1 if isolated; P0 if your frontend is serving drainer transactions.

THREAT TYPE 3: SEED PHRASE / PRIVATE KEY EXPOSURE
  Key material exposed in code, logs, environment variables, or public channels.
  Impact: Any funds or authority held by that key are at risk.
  Severity: P0 — rotate the key and move funds before investigating how it leaked.

THREAT TYPE 4: HARDWARE WALLET / MFA BYPASS
  Physical theft, SIM swap, or authenticator compromise targeting team members
  with protocol signing authority.
  Impact: Multisig threshold potentially reachable by attacker.
  Severity: P1 — remove compromised signer from Squads immediately.

THREAT TYPE 5: SUPPLY CHAIN KEY LEAK
  Private key embedded in open-source dependency, CI/CD pipeline, or third-party
  service with access to signing keys.
  Impact: Silent, long-dwell exfiltration of keys.
  Severity: P0 when discovered — assume key is already used.
```

---

## Immediate Response: Authority Key Compromise

If you believe your upgrade authority, mint authority, or treasury key is compromised:

```
PRIORITY ORDER (do all in parallel if team is available):
1. Rotate the compromised key — transfer authority before the attacker can use it
2. Freeze any on-chain capabilities controlled by the key (mint freeze, program pause)
3. Check if the attacker has already used the key (Helius history on the key address)
4. Preserve evidence before rotation destroys it
```

### Step 1 — Transfer Upgrade Authority (Emergency)

If the compromised key holds your program's upgrade authority:

```bash
# FASTEST PATH: transfer upgrade authority to a clean Squads multisig
# Run from a machine that has never touched the compromised key

# Check current upgrade authority
solana program show PROGRAM_ID

# Transfer to a new secure keypair or Squads multisig
solana program set-upgrade-authority PROGRAM_ID \
  --new-upgrade-authority NEW_AUTHORITY_ADDRESS \
  --keypair /path/to/CURRENT_authority.json \
  -u mainnet-beta

# Verify the transfer
solana program show PROGRAM_ID | grep -i "upgrade authority"
```

If the compromised key is a Squads v4 signer:
```bash
# Remove the compromised signer from the multisig
# Do this via Squads UI (app.squads.so) or SDK
# Requires reaching the remaining threshold of current signers

# Via Squads SDK
import { Multisig } from "@sqds/multisig";
// Create a proposal to remove the compromised member
// Requires M-of-N remaining members to approve
```

### Step 2 — Freeze Mint Authority (If Compromised)

```bash
# SPL Token — freeze mint authority
spl-token authorize MINT_ADDRESS mint NEW_MINT_AUTHORITY \
  --keypair /path/to/CURRENT_mint_authority.json

# Token-2022
spl-token authorize MINT_ADDRESS mint NEW_MINT_AUTHORITY \
  --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb \
  --keypair /path/to/CURRENT_mint_authority.json

# If mint authority can't be rotated — use freeze authority to halt transfers
spl-token freeze MINT_ADDRESS \
  --keypair /path/to/freeze_authority.json
```

### Step 3 — Audit What the Key Has Already Done

```typescript
// src/wallet-security/key-audit.ts
import { Helius } from "helius-sdk";

export async function auditCompromisedKey(
  keyAddress: string,
  heliusApiKey: string,
  lookbackDays = 7
): Promise<{
  totalTxs: number;
  programUpgrades: string[];
  mintAuthActions: string[];
  largeTransfers: { signature: string; amount: number; destination: string }[];
  firstSuspiciousTx: string | null;
}> {
  const helius = new Helius(heliusApiKey);
  const cutoff = Math.floor(Date.now() / 1000) - lookbackDays * 86400;

  const txs = await helius.rpc.getTransactionHistory({
    address: keyAddress,
    options: { limit: 200 }
  });

  const recentTxs = txs.filter(tx => (tx.timestamp ?? 0) > cutoff);

  const programUpgrades: string[] = [];
  const mintAuthActions: string[] = [];
  const largeTransfers: { signature: string; amount: number; destination: string }[] = [];

  for (const tx of recentTxs) {
    const instructions = tx.instructions ?? [];

    for (const ix of instructions) {
      // BPFLoaderUpgradeable = program upgrade
      if (ix.programId === "BPFLoaderUpgradeab1e11111111111111111111111") {
        programUpgrades.push(tx.signature);
      }
      // Token program authority changes
      if (
        ix.programId === "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA" &&
        ix.data?.includes("SetAuthority")
      ) {
        mintAuthActions.push(tx.signature);
      }
    }

    // Large SOL transfers
    for (const transfer of tx.nativeTransfers ?? []) {
      if (transfer.amount > 1e9) { // > 1 SOL
        largeTransfers.push({
          signature: tx.signature,
          amount: transfer.amount / 1e9,
          destination: transfer.toUserAccount
        });
      }
    }
  }

  // First suspicious tx = first tx after baseline behavior changed
  // Simplified: any program upgrade or large transfer is suspicious if unexpected
  const suspiciousSigs = [...programUpgrades, ...mintAuthActions,
    ...largeTransfers.map(t => t.signature)];

  return {
    totalTxs: recentTxs.length,
    programUpgrades,
    mintAuthActions,
    largeTransfers,
    firstSuspiciousTx: suspiciousSigs.length > 0 ? suspiciousSigs[0] : null
  };
}
```

---

## Drainer Contract Detection

Wallet drainers are malicious Solana programs or transactions that trick users
into approving instructions that transfer all their assets.

### How Solana Drainers Work (2024–2026 Patterns)

```
PATTERN 1: Fake NFT Mint / Free Claim
  User connects wallet → approves "mint" transaction
  Real effect: setAuthority (transfers ownership of their token accounts)
  or malicious transferChecked draining all tokens

PATTERN 2: Phantom Permission Abuse
  Legitimate-looking dApp requests signAllTransactions
  One of many transactions is a drainer — user approves in bulk

PATTERN 3: Malicious Token Approval (Pre-approve Drain)
  Token-2022 delegate pattern: user approves delegate with unlimited amount
  Attacker calls transferChecked later from their account

PATTERN 4: Ledger App Confusion
  Encoded instruction data doesn't display correctly in Ledger
  User approves unknown instruction believing it's benign

PATTERN 5: Domain Hijack / DNS Poisoning
  Legitimate domain redirects to look-alike with replaced program IDs
  All transactions route to drainer contract
```

### Detecting Drainer Transactions Before Signing

```typescript
// src/wallet-security/drainer-detector.ts
import { Transaction, VersionedTransaction } from "@solana/web3.js";

interface DrainerRisk {
  risk: "CRITICAL" | "HIGH" | "MEDIUM" | "LOW";
  flags: string[];
  recommendation: string;
}

export function analyzeTransactionForDrainer(
  tx: Transaction | VersionedTransaction,
  signerAddress: string
): DrainerRisk {
  const flags: string[] = [];

  // Get instructions from either transaction type
  const instructions = "instructions" in tx
    ? tx.instructions
    : (tx as VersionedTransaction).message.compiledInstructions;

  for (const ix of instructions) {
    const programId = "programId" in ix
      ? ix.programId.toString()
      : ix.programIdIndex.toString();
    const data = "data" in ix ? ix.data : ix.data;
    const dataHex = Buffer.from(data).toString("hex");

    // Flag: Token program authority change (SetAuthority instruction = 6)
    if (
      programId === "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA" &&
      dataHex.startsWith("06")
    ) {
      flags.push("SetAuthority instruction detected — would transfer token account ownership");
    }

    // Flag: Token-2022 delegate approve with large amount
    if (
      programId === "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb" &&
      (dataHex.startsWith("04") || dataHex.startsWith("0d")) // Approve or ApproveChecked
    ) {
      flags.push("Token delegate approval — review approved amount and delegate address carefully");
    }

    // Flag: Unknown program being called
    const KNOWN_SAFE_PROGRAMS = new Set([
      "11111111111111111111111111111111",     // System
      "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA", // SPL Token
      "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb", // Token-2022
      "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJe8bv8dX", // ATA
      "ComputeBudget111111111111111111111111111111",
      "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s", // Metaplex
    ]);

    if (!KNOWN_SAFE_PROGRAMS.has(programId)) {
      // Custom program — not inherently bad, but flag for review
      flags.push(`Custom program called: ${programId} — verify this is the expected program`);
    }
  }

  // Assess
  const hasCritical = flags.some(f => f.includes("SetAuthority"));
  const hasHigh = flags.some(f => f.includes("delegate"));
  const risk: DrainerRisk["risk"] =
    hasCritical ? "CRITICAL" : hasHigh ? "HIGH" :
    flags.length > 2 ? "MEDIUM" : "LOW";

  const recommendation =
    risk === "CRITICAL" ? "DO NOT SIGN — SetAuthority detected. This transaction transfers ownership of your assets." :
    risk === "HIGH" ? "Review carefully — token delegation approval. Confirm recipient and amount." :
    risk === "MEDIUM" ? "Simulate before signing. Multiple unknown instructions detected." :
    "Appears standard — still verify program IDs match expected values.";

  return { risk, flags, recommendation };
}
```

### If Your Frontend Is Serving Drainer Transactions

Immediate steps:
```
1. Take the frontend offline immediately (Vercel/Netlify → disable deployment)
2. Post: "We are investigating a potential issue with our frontend. Do NOT sign any transactions."
3. Load skill/crisis-communication.md + agents/comms-director.md
4. Audit: when did the malicious deployment go live? (check git blame + deploy logs)
5. Rotate all DNS, hosting credentials, deploy keys
6. Verify program IDs in the malicious build vs your canonical build
7. Alert exchanges with token address to watch for drainer proceeds
```

---

## Seed Phrase / Private Key Exposure Response

The moment you suspect a key has been exposed — even if you're not sure — rotate it.
Do not wait for confirmation. The cost of a false positive (rotating a good key) is zero.
The cost of a false negative (not rotating a compromised key) is everything.

### Key Hygiene Audit for Protocol Teams

```bash
#!/usr/bin/env bash
# Run this monthly or before any public event

echo "=== SOLANA KEY HYGIENE AUDIT ==="
echo ""
echo "1. Checking for keys in code..."
grep -rn "PRIVATE\|SECRET\|MNEMONIC\|seed_phrase\|\[" . \
  --include="*.ts" --include="*.js" --include="*.json" \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  | grep -v ".test.\|spec\|example\|placeholder" \
  | head -20

echo ""
echo "2. Checking environment files..."
find . -name ".env*" -not -path "./.git/*" | while read f; do
  echo "  Found: $f"
  if grep -qE "[0-9a-zA-Z]{43,88}" "$f"; then
    echo "  ⚠️  Contains potential key material — verify it's not committed"
  fi
done

echo ""
echo "3. Checking git history for accidental key commits..."
git log --all --oneline -20
echo "  Run: git log --all -S 'PRIVATE_KEY_PATTERN' to search for specific strings"

echo ""
echo "4. Authority inventory check..."
echo "  Upgrade authority: [run: solana program show YOUR_PROGRAM_ID]"
echo "  Mint authority:    [run: spl-token display YOUR_MINT]"
echo "  Treasury wallet:   [verify in Squads UI at app.squads.so]"
```

---

## Emergency Key Rotation Checklist

```text
[ ] Rotate compromised key (transfer authority to new clean keypair)
[ ] Rotate any key on the same device / environment (assume lateral compromise)
[ ] Rotate CI/CD secrets that had access to signing keys
[ ] Revoke all API keys from services that had access to the compromised environment
[ ] Check on-chain for unauthorized actions in the last 30 days
[ ] Notify Squads co-signers to verify their own key hygiene
[ ] Document rotation: which key, why, when, new authority address
[ ] Verify all program authorities are now pointing to the new correct addresses
[ ] Resume monitoring with fresh Helius webhook alerts on old key address
```

---

## Cross-Skill Signals

### Feeds Incident Response
- Any team authority key compromise → immediately escalates to `agents/incident-commander.md`
- Drainer detected on frontend → load `skill/crisis-communication.md` immediately
- Key exposure discovered → load `skill/legal-regulatory-response.md` if user funds at risk

### Receives from Observability
- `wallet-error-spike` runbook signal → check if spike is drainer-related vs UX bug
- Unexpected program upgrade alert → immediately audit upgrade authority key

### Feeds UX Skill
- Drainer pattern taxonomy shared with `solana-ux-skill/skill/wallet-ux.md`
- Transaction analysis patterns used in pre-sign simulation UX
