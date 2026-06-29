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


---

## Supply Chain Attack on Wallet Frontend

One of the most dangerous and least-discussed vectors: a malicious npm package in your wallet's dependencies that exfiltrates key material silently.

### How It Works

```
Timeline of a supply chain wallet compromise:

T-30 days: Attacker publishes legitimate-looking npm package or compromises existing one
           Example: "solana-utils-v2" contains a benign version for 30 days

T-14 days: Attacker submits PR to your repository adding the dependency
           OR compromises an existing trusted dependency via typosquatting

T-0: Malicious version published — contains exfiltration code:
     - Hooks into key generation / decryption functions
     - Extracts key material and POSTs to attacker's C2 server
     - Obfuscated as legitimate analytics or error reporting traffic
```

### Detection

```bash
#!/usr/bin/env bash
# Run this before every production build and in CI

# 1. Audit all dependencies for known vulnerabilities
npm audit --audit-level=moderate

# 2. Check for postinstall scripts (common exfiltration vector)
node -e "
const pkg = require('./node_modules');
const fs = require('fs');
const results = [];
function checkPackage(dir) {
  try {
    const p = JSON.parse(fs.readFileSync(dir + '/package.json', 'utf8'));
    if (p.scripts?.postinstall) {
      results.push({ name: p.name, version: p.version, script: p.scripts.postinstall });
    }
  } catch {}
}
require('glob').sync('node_modules/*/package.json').forEach(f => checkPackage(f.replace('/package.json', '')));
console.log('Packages with postinstall scripts:');
results.forEach(r => console.log(r));
"

# 3. Verify lockfile integrity (never install without lockfile)
npm ci  # NOT npm install — ci refuses to modify lockfile

# 4. Pin to exact versions — no ranges in package.json
grep -E '"[^"]+": "\^|~' package.json && echo "WARNING: Unpinned dependencies found"

# 5. Monitor package.json for unexpected additions (CI gate)
git diff HEAD~1 package.json | grep '"dependencies"' -A 999 | grep '^+'
```

### Prevention Architecture

```typescript
// Content Security Policy headers for wallet frontend
// Add to your server or Cloudflare Worker

export const WALLET_CSP_HEADERS = {
  "Content-Security-Policy": [
    "default-src 'self'",
    "script-src 'self' 'unsafe-eval'",    // 'unsafe-eval' only if required for WASM
    "style-src 'self' 'unsafe-inline'",   // Tailwind requires inline
    "connect-src 'self' https://*.helius-rpc.com https://*.quicknode.com",  // RPC only
    "img-src 'self' data: https:",
    "font-src 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",             // Block iframe embedding (clickjacking)
    "upgrade-insecure-requests",
  ].join("; "),
  "X-Frame-Options": "DENY",
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "no-referrer",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
};

// Subresource Integrity for any CDN-loaded scripts
// In your HTML template:
// <script src="https://cdn.example.com/lib.js"
//   integrity="sha384-HASH"
//   crossorigin="anonymous"></script>
```

---

## Address Poisoning Response Protocol

If your protocol or users are being targeted by address poisoning attacks:

### Detection (Helius webhook setup)

```typescript
// src/address-poison-detector.ts
import { Helius } from "helius-sdk";
import { PublicKey } from "@solana/web3.js";

/**
 * Set up webhook to detect address poisoning attempts.
 * Fires when wallets similar to your known addresses send dust transactions.
 */
export async function setupAddressPoisonWebhook(
  helius: Helius,
  protocolAddresses: string[]   // Addresses to protect
): Promise<string> {
  const webhook = await helius.createWebhook({
    accountAddresses: protocolAddresses,
    transactionTypes: ["TRANSFER"],
    type: "enhanced",
    webhookURL: process.env.INCIDENT_WEBHOOK_URL!,
  });

  return webhook.webhookID;
}

/**
 * Check if an incoming transaction looks like an address poisoning attempt.
 * Triggered by webhook — run on every inbound transfer.
 */
export function isAddressPoisoningAttempt(
  incomingTx: any,
  protocolAddresses: string[]
): { isPoisoning: boolean; evidence: string } {
  const sender = incomingTx.feePayer;
  const amount = incomingTx.nativeTransfers?.[0]?.amount ?? 0;

  // Poisoning characteristics:
  // 1. Dust amount (< 0.001 SOL)
  // 2. Sender address visually similar to known protocol address
  const isDust = amount < 1_000_000; // < 0.001 SOL

  for (const known of protocolAddresses) {
    const senderFirst6 = sender.slice(0, 6);
    const senderLast6 = sender.slice(-6);

    if (known.slice(0, 6) === senderFirst6 || known.slice(-6) === senderLast6) {
      if (isDust) {
        return {
          isPoisoning: true,
          evidence: `Dust transaction (${amount} lamports) from ${sender} — visually similar to known address ${known}`,
        };
      }
    }
  }

  return { isPoisoning: false, evidence: "" };
}
```

### User Response Communication

When address poisoning is detected targeting your users:

```
Immediate actions:
1. Post warning on Discord, Twitter, Telegram: "Address poisoning attack detected"
2. Add warning banner to your frontend: "⚠️ Address poisoning active — verify every character of addresses"
3. Enable address similarity check in your send flow
4. Report attacker addresses to Helius and Solscan for labeling

User guidance template:
---
🚨 SECURITY ALERT: Address Poisoning Attack

Attackers are sending tiny amounts from addresses that look like [PROTOCOL NAME] addresses.

If you recently copied an address from your transaction history, STOP.

✅ How to stay safe:
1. Never copy-paste addresses from transaction history
2. Bookmark our official address: [OFFICIAL ADDRESS]
3. Verify ALL 44 characters before confirming any transaction
4. Use our official address book feature

❌ Never trust: recent transaction history, Discord DMs, search results
---
```

---

## Drainer Contract Deep Analysis (2024–2026 Patterns)

Understanding exactly how modern Solana drainers work allows wallets to detect them pre-signing.

### Pattern 1: setAuthority Drainer (most common)

```
Transaction structure:
  IX 1: setAuthority(tokenAccount, ownerType, newOwner=ATTACKER)
  
What happens: ownership of the token account transfers to attacker.
They can then drain it at any time without further user interaction.

Detection: any instruction with programId=TokenProgram, discriminator=7 (setAuthority),
           authorityType=1 (AccountOwner), newAuthority≠user's own addresses

Wallet action: HARD BLOCK — never show approval UI for this
```

### Pattern 2: Delegate Approval Drainer

```
Transaction structure:
  IX 1: approve(tokenAccount, delegate=ATTACKER, amount=MAX_UINT64)

What happens: attacker can transfer up to MAX_UINT64 tokens at will.
User keeps nominal ownership but has granted unlimited spending power.

Detection: discriminator=3 (Approve), amount=18446744073709551615 (max), delegate≠known protocol

Wallet action: DANGER warning — show delegate address + amount prominently
               Require explicit "I understand" checkbox before signing
```

### Pattern 3: Versioned Transaction Bundle Drainer (newest, hardest to detect)

```
Transaction structure (Versioned / Address Lookup Tables):
  Uses ALTs to hide malicious accounts from the readable instruction list
  Accounts at ALT indices are not shown in wallet's account list
  
What happens: wallet shows "approve 1.0 SOL transfer"
              ALT account expansion reveals hidden token drainer instruction

Detection: for EVERY versioned transaction, expand ALL address lookup tables
           and verify every resolved account before displaying approval UI

Wallet action: expand ALTs before showing approval — never trust unresolved account lists
```

```typescript
// Expand address lookup tables before transaction analysis
import {
  AddressLookupTableAccount,
  Connection,
  PublicKey,
  VersionedTransaction,
} from "@solana/web3.js";

export async function expandVersionedTransaction(
  tx: VersionedTransaction,
  connection: Connection
): Promise<{ allAccounts: PublicKey[]; altAccounts: PublicKey[] }> {
  const message = tx.message;
  const altKeys = message.addressTableLookups.map((l) => l.accountKey);

  // Load all address lookup tables
  const altAccounts = await Promise.all(
    altKeys.map((key) =>
      connection.getAddressLookupTable(key).then((r) => r.value)
    )
  );

  // Expand ALL accounts including ALT-resolved ones
  const allAccounts = message.getAccountKeys({
    addressLookupTableAccounts: altAccounts.filter(Boolean) as AddressLookupTableAccount[],
  });

  return {
    allAccounts: allAccounts.staticAccountKeys.concat(
      allAccounts.accountKeysFromLookups?.writable ?? [],
      allAccounts.accountKeysFromLookups?.readonly ?? []
    ),
    altAccounts: altAccounts.flatMap((alt) => alt?.state.addresses ?? []),
  };
}
```

---

## Wallet-Specific Threat Model by Architecture

Different wallet architectures have different primary threat vectors.

```
BROWSER EXTENSION WALLET:
  Primary threat: A3 (malicious extension injection)
  Primary threat: A8 (supply chain in extension dependencies)
  Key mitigation: extension isolation — background script holds keys
                  content scripts NEVER have key access
                  message passing with origin validation
  Secondary: A2 (malicious dApp), A7 (phishing)

MOBILE WALLET (React Native):
  Primary threat: A6 (physical device theft)
  Key mitigation: OS Secure Enclave / Keychain mandatory
                  biometric required for every signing operation
                  screen blur on background
  Secondary: A4 (clipboard), A7 (phishing QR codes)

EMBEDDED WALLET (Privy/Magic, no seed phrase):
  Primary threat: Custodian compromise (beyond user control)
  Key mitigation: hardware-bound key shards (Privy MPC)
                  social recovery configured before onboarding
  Secondary: A7 (phishing the custodian's OAuth flow)

SERVER-SIDE FEE PAYER:
  Primary threat: A8 (secrets in code/environment)
  Key mitigation: AWS KMS, HashiCorp Vault, never in .env
                  separate keypair per environment (dev/staging/prod)
                  rotated on any suspected compromise
  Secondary: A3 (compromised CI pipeline)
```

---

## Wallet Recovery Protocol

When a user loses access to their wallet (lost seed phrase, broken device), coordinate:

```
LOAD ORDER FOR WALLET RECOVERY:
  1. THIS FILE — threat classification + triage
  2. UX skill/wallet-building.md — key derivation + account discovery
  3. UX skill/wallet-ux.md — recovery flow UX

RECOVERY TRIAGE:
  "Lost seed phrase, no backup"
    → Cannot recover software wallet. Load gasless-onboarding.md to create new wallet.
    → If had Squads multisig, remaining signers can rotate. Load program-upgrade-safety.md.
    → Prevention: implement social recovery (Squads + 2 of 3 trusted recovery contacts)

  "Device destroyed, seed phrase available"
    → Standard restore: mnemonic → keypairFromMnemonic → account discovery (gap limit)
    → Load wallet-building.md → keypairFromMnemonic + discoverAccounts
    → Re-run security tier evaluation for new device

  "Seed phrase exposed (phishing, screenshot, iCloud sync)"
    → TREAT AS P0 COMPROMISE — key is considered stolen
    → Load skill/active-exploit-response.md immediately
    → Rotate all keys, move all funds BEFORE investigating how it leaked
    → Create new wallet on clean device using clean derivation path

  "Hardware wallet lost/stolen"
    → Hardware wallet PIN protects device. Attacker cannot sign without PIN.
    → Treat as P1 if device was unlocked when lost
    → Load this file → threat type 4 response (MFA bypass)
    → Immediately rotate co-signer in any Squads multisig
```

---

## WALLET_KEY_COMPROMISED Signal

This is the highest-priority cross-skill signal in the entire ecosystem.
When any wallet key compromise is detected, ALL five skills must be notified.

```typescript
// Signal definition — shared across all skills
export interface WalletKeyCompromisedSignal {
  signal: "WALLET_KEY_COMPROMISED";
  source_skill: "solana-incident-response-skill";
  severity: "P0";
  key_type:
    | "user_wallet"
    | "fee_payer"
    | "upgrade_authority"
    | "mint_authority"
    | "treasury";
  compromised_address: string;
  confirmed: boolean;       // false = suspected; true = confirmed activity
  detected_at_utc: string;

  // What to load in each skill:
  skill_actions: {
    incident_response: "skill/active-exploit-response.md";
    observability: "skill/security-observability.md → heightened monitoring";
    ux: "skill/wallet-ux.md → drain warning UI";
    depin: "skill/incident-response-integration.md → pause rewards if fee payer";
    token_launch: "skill/post-launch-monitoring.md → pause distributions";
  };
}

// Fire this signal immediately on any confirmed or suspected key compromise
export function fireWalletKeyCompromised(
  params: Omit<WalletKeyCompromisedSignal, "signal" | "source_skill" | "severity" | "skill_actions">
): WalletKeyCompromisedSignal {
  return {
    signal: "WALLET_KEY_COMPROMISED",
    source_skill: "solana-incident-response-skill",
    severity: "P0",
    skill_actions: {
      incident_response: "skill/active-exploit-response.md",
      observability: "skill/security-observability.md → heightened monitoring",
      ux: "skill/wallet-ux.md → drain warning UI",
      depin: "skill/incident-response-integration.md → pause rewards if fee payer",
      token_launch: "skill/post-launch-monitoring.md → pause distributions",
    },
    ...params,
  };
}
```
