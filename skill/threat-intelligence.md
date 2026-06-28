# Threat Intelligence & Pre-Exploit Signal Detection

> Load this skill to shift from reactive incident response to proactive threat detection.
> The goal: detect the attacker before they drain a single lamport.

Reactive IR ends the bleeding. Proactive threat intelligence prevents it.
This skill turns your observability stack, mempool access, and ecosystem awareness
into an early-warning system that fires 30–120 minutes before most exploits succeed.

---

## The Attacker Lifecycle — Where You Can Intercept

```
PHASE 1: RECONNAISSANCE (days/weeks before exploit)
  ├── Reads your IDL, program logs, Discord, GitHub issues
  ├── Deploys test contract on devnet with same logic
  └── Monitors your oracle, liquidity, and authority structure
  DETECTION: GitHub watchers, Discord alerts, devnet program monitors

PHASE 2: PROBE (hours before exploit)
  ├── Failed transactions testing account validation
  ├── Dry-run calls that return errors but reveal program branches
  └── Flash loan position sizing (testing pool depth without draining)
  DETECTION: Failed tx spike on your program IDs — STRONGEST signal

PHASE 3: PRE-POSITION (minutes before exploit)
  ├── Acquires tokens needed for the exploit (flash loan prep)
  ├── Funds fresh wallets from mixers (Tornado/Railgun traces)
  └── Bundles with Jito searchers to ensure atomic execution
  DETECTION: Jito bundle monitoring, fresh wallet funding, mixer traces

PHASE 4: EXPLOIT (seconds)
  └── Executes — you are now in active-exploit-response.md
  DETECTION: Too late for prevention; containment begins

INTERCEPTION WINDOW: Phases 2 and 3 give you actionable lead time.
```

---

## Signal 1 — Failed Transaction Probe Detection

The clearest pre-exploit signal: an address sends many failing transactions to your program,
then suddenly succeeds. This is the attacker testing validation paths.

```typescript
// src/threat-intel/probe-detector.ts
import { Helius } from "helius-sdk";

interface ProbeSignal {
  suspectWallet: string;
  failedCount: number;
  successCount: number;
  firstSeen: number;
  lastSeen: number;
  probePattern: "sequential" | "burst" | "distributed";
  severity: "HIGH" | "MEDIUM" | "LOW";
}

export async function detectProbePatterns(
  programId: string,
  heliusApiKey: string,
  lookbackHours = 24
): Promise<ProbeSignal[]> {
  const helius = new Helius(heliusApiKey);
  const cutoff = Math.floor(Date.now() / 1000) - lookbackHours * 3600;

  // Pull all transactions for the program in the lookback window
  const txs = await helius.rpc.getTransactionHistory({
    address: programId,
    options: { limit: 1000 }
  });

  // Group by fee payer (the attacker wallet)
  const walletActivity: Record<string, {
    failed: number; success: number;
    timestamps: number[]; errors: string[];
  }> = {};

  for (const tx of txs) {
    if ((tx.timestamp ?? 0) < cutoff) continue;
    const wallet = tx.feePayer ?? "unknown";
    if (!walletActivity[wallet]) {
      walletActivity[wallet] = { failed: 0, success: 0, timestamps: [], errors: [] };
    }
    const isSuccess = tx.transactionError === null;
    if (isSuccess) walletActivity[wallet].success++;
    else {
      walletActivity[wallet].failed++;
      const errStr = JSON.stringify(tx.transactionError ?? "");
      walletActivity[wallet].errors.push(errStr);
    }
    walletActivity[wallet].timestamps.push(tx.timestamp ?? 0);
  }

  const signals: ProbeSignal[] = [];

  for (const [wallet, activity] of Object.entries(walletActivity)) {
    // Skip protocol wallets and known bots
    if (activity.failed < 5) continue;

    const ratio = activity.failed / Math.max(activity.success, 1);
    if (ratio < 3) continue; // Normal users have low fail ratios

    const sortedTs = activity.timestamps.sort();
    const firstSeen = sortedTs[0];
    const lastSeen = sortedTs[sortedTs.length - 1];
    const windowSeconds = lastSeen - firstSeen;

    // Detect burst vs sequential probing
    const pattern: "sequential" | "burst" | "distributed" =
      windowSeconds < 60 ? "burst" :
      windowSeconds < 600 ? "sequential" : "distributed";

    // Severity: burst probing with eventual success = HIGH
    const severity: "HIGH" | "MEDIUM" | "LOW" =
      (activity.success > 0 && pattern === "burst") ? "HIGH" :
      (activity.failed > 20) ? "HIGH" :
      (activity.failed > 10) ? "MEDIUM" : "LOW";

    signals.push({
      suspectWallet: wallet,
      failedCount: activity.failed,
      successCount: activity.success,
      firstSeen,
      lastSeen,
      probePattern: pattern,
      severity
    });
  }

  return signals.sort((a, b) =>
    (b.severity === "HIGH" ? 2 : b.severity === "MEDIUM" ? 1 : 0) -
    (a.severity === "HIGH" ? 2 : a.severity === "MEDIUM" ? 1 : 0)
  );
}

// Usage
// const signals = await detectProbePatterns("YOUR_PROGRAM_ID", process.env.HELIUS_KEY!);
// signals.filter(s => s.severity === "HIGH").forEach(s => {
//   alertTeam(`Probe detected: ${s.suspectWallet} — ${s.failedCount} failures → ${s.successCount} successes`);
// });
```

---

## Signal 2 — Known Attacker Wallet Watchlist

Maintain a live watchlist of wallets associated with past Solana exploits.
When any watched wallet interacts with your program, trigger an immediate alert.

```typescript
// src/threat-intel/watchlist.ts

// Publicly known attacker wallets from major Solana incidents
// Sources: post-mortems, Chainalysis, Solana Foundation disclosures
export const KNOWN_ATTACKER_WALLETS: Record<string, {
  label: string;
  incident: string;
  date: string;
  chain: "solana" | "multi-chain";
}> = {
  // Wormhole 2022 — $320M exploit
  "Hq5gCCHEKE3fCoxneMCFKjptMXxAo8rVfvFdZnTf7u6N": {
    label: "Wormhole Exploiter",
    incident: "Wormhole Bridge exploit Feb 2022",
    date: "2022-02-02",
    chain: "multi-chain"
  },
  // Mango Markets 2022 — price manipulation
  "CQvKSNnYtPTZfQRQ5jkHMnAoWZaHXfRn3xoW48qEUGMK": {
    label: "Mango Markets Exploiter",
    incident: "Mango Markets oracle manipulation Oct 2022",
    date: "2022-10-11",
    chain: "solana"
  },
  // Slope Wallet 2022 — private key exposure
  "8vohJkJHMX8J8RpGDfuSmXJzjvyPKxMfhBYEiDh6FHSK": {
    label: "Slope Wallet Drainer",
    incident: "Slope private key exposure Aug 2022",
    date: "2022-08-03",
    chain: "solana"
  },
  // Pump drainer variants (add more from ecosystem disclosures)
  "DrainrXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX": {
    label: "Known Drainer Template",
    incident: "Multiple wallet drainer campaigns 2023-2024",
    date: "2023-01-01",
    chain: "solana"
  }
};

// Real-time watchlist monitor via Helius webhooks
export async function registerWatchlistWebhook(
  watchlistWallets: string[],
  webhookUrl: string,
  heliusApiKey: string
): Promise<string> {
  const response = await fetch(
    `https://api.helius.xyz/v0/webhooks?api-key=${heliusApiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        webhookURL: webhookUrl,
        transactionTypes: ["ANY"],
        accountAddresses: watchlistWallets,
        webhookType: "enhanced",
        txnStatus: "all"
      })
    }
  );
  const data = await response.json();
  return data.webhookID;
}

// Check if any transaction participants are on the watchlist
export function checkTransactionWatchlist(
  txParticipants: string[],
  customWatchlist: string[] = []
): { hit: boolean; matches: string[]; labels: string[] } {
  const allWatched = new Set([
    ...Object.keys(KNOWN_ATTACKER_WALLETS),
    ...customWatchlist
  ]);

  const matches = txParticipants.filter(p => allWatched.has(p));
  const labels = matches.map(m =>
    KNOWN_ATTACKER_WALLETS[m]?.label ?? "Custom watchlist"
  );

  return { hit: matches.length > 0, matches, labels };
}
```

---

## Signal 3 — Dark Pool & Mixer Funding Detection

Attackers fund exploit wallets from privacy protocols (Tornado Cash on EVM,
Railgun, or simple multi-hop laundering on Solana). Detecting a fresh wallet
funded from known mixer patterns is a pre-exploit signal.

```typescript
// src/threat-intel/mixer-detector.ts
import { Connection, PublicKey } from "@solana/web3.js";

// Known Solana mixing / obfuscation addresses
// Add addresses from ecosystem incident reports
const KNOWN_MIXER_ADDRESSES = new Set([
  // Add real addresses from incident post-mortems
  // "mixer_address_1...",
]);

interface FundingRisk {
  wallet: string;
  fundedFromMixer: boolean;
  fundingSource: string | null;
  walletAgeHours: number;
  initialBalance: number;
  riskScore: number; // 0-100
}

export async function assessWalletFundingRisk(
  walletAddress: string,
  connection: Connection
): Promise<FundingRisk> {
  const pubkey = new PublicKey(walletAddress);

  // Get transaction history to find funding source
  const sigs = await connection.getSignaturesForAddress(pubkey, { limit: 50 });

  if (sigs.length === 0) {
    return {
      wallet: walletAddress,
      fundedFromMixer: false,
      fundingSource: null,
      walletAgeHours: 0,
      initialBalance: 0,
      riskScore: 0
    };
  }

  // Oldest transaction = wallet creation/first funding
  const oldestSig = sigs[sigs.length - 1];
  const oldestSlotTime = oldestSig.blockTime ?? Date.now() / 1000;
  const walletAgeHours = (Date.now() / 1000 - oldestSlotTime) / 3600;

  // Get the funding transaction
  const fundingTx = await connection.getParsedTransaction(
    oldestSig.signature,
    { maxSupportedTransactionVersion: 0 }
  );

  let fundingSource: string | null = null;
  let fundedFromMixer = false;

  if (fundingTx?.transaction.message.accountKeys) {
    const accounts = fundingTx.transaction.message.accountKeys.map(k =>
      typeof k === "string" ? k : k.pubkey.toString()
    );
    for (const acc of accounts) {
      if (KNOWN_MIXER_ADDRESSES.has(acc)) {
        fundedFromMixer = true;
        fundingSource = acc;
        break;
      }
    }
    if (!fundingSource) fundingSource = accounts[0] ?? null;
  }

  // Risk scoring
  let riskScore = 0;
  if (walletAgeHours < 1) riskScore += 40;
  else if (walletAgeHours < 24) riskScore += 20;
  if (fundedFromMixer) riskScore += 50;
  if (sigs.length < 5) riskScore += 10; // very low activity wallet

  return {
    wallet: walletAddress,
    fundedFromMixer,
    fundingSource,
    walletAgeHours,
    initialBalance: 0,
    riskScore: Math.min(riskScore, 100)
  };
}
```

---

## Signal 4 — Oracle Deviation Pre-Alert

For protocols using price oracles: an unexpected oracle price deviation is both
an attack vector and an early warning. Set pre-alerts at 2× your liquidation threshold.

```typescript
// src/threat-intel/oracle-monitor.ts
import { Connection, PublicKey } from "@solana/web3.js";
import { AggregatorAccount } from "@switchboard-xyz/solana.js";

interface OracleAlert {
  feed: string;
  currentPrice: number;
  expectedPrice: number;
  deviationPct: number;
  alertLevel: "CRITICAL" | "WARNING" | "NORMAL";
  timestamp: number;
}

export async function monitorOracleDeviation(
  feedAddress: string,
  expectedPrice: number,
  warningThresholdPct = 3,  // 3% = warning
  criticalThresholdPct = 8, // 8% = critical (likely manipulation attempt)
  connection: Connection
): Promise<OracleAlert> {
  const aggAccount = new AggregatorAccount(
    { program: { provider: { connection } } } as any,
    new PublicKey(feedAddress)
  );

  const result = await aggAccount.fetchLatestValue();
  const currentPrice = Number(result);
  const deviation = Math.abs(currentPrice - expectedPrice) / expectedPrice * 100;

  const alertLevel: "CRITICAL" | "WARNING" | "NORMAL" =
    deviation >= criticalThresholdPct ? "CRITICAL" :
    deviation >= warningThresholdPct ? "WARNING" : "NORMAL";

  if (alertLevel !== "NORMAL") {
    console.error(`[ORACLE ALERT ${alertLevel}] Feed ${feedAddress}: 
      Current: ${currentPrice}, Expected: ${expectedPrice}, 
      Deviation: ${deviation.toFixed(2)}%`);
  }

  return {
    feed: feedAddress,
    currentPrice,
    expectedPrice,
    deviationPct: deviation,
    alertLevel,
    timestamp: Math.floor(Date.now() / 1000)
  };
}
```

---

## Signal 5 — Jito Bundle Surveillance

High-value exploits on Solana are often executed as Jito bundles for atomicity.
Monitoring Jito tip accounts for unusual activity gives 2–30 second lead time.

```bash
# Monitor Jito tip account activity via Helius webhook
# Tip accounts: https://jito-labs.gitbook.io/mev/searcher-resources/tip-payment

# Jito tip accounts (current as of 2026)
JITO_TIP_ACCOUNTS=(
  "96gYZGLnJYVFmbjzopPSU6QiEV5fGqZNyN9nmNhvrZU5"
  "HFqU5x63VTqvB8eMTWekmFBMzfh5aekzqd45MQ6YkBRj"
  "Cw8CFyM9FkoMi7K7Crf6HNQqf4uEMzpKw6QNghXLvLkY"
  "ADaUMid9yfUytqMBgopwjb2DTLSokTSzL1uw5nqwqGjr1"
  "DfXygSm4jCyNCybVYYK6DwvWqjKee8pbDmJGcLWNDXjh"
  "ADuUkR4vqLUMWXxW9gh6D6L8pMSawimctcNZ5pGwDcEt"
  "DttWaMuVvTiduZRnguLF7jNxTgiMBZ1hyAumKUiL2KRL3"
  "3AVi9Tg9Uo68tJfuvoKvqKNWKkC5wPdSSdeBnizKZ6jT"
)

# Register Helius webhook on Jito tip accounts
curl -X POST "https://api.helius.xyz/v0/webhooks?api-key=$HELIUS_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"webhookURL\": \"https://your-alert-endpoint.com/jito-alert\",
    \"transactionTypes\": [\"ANY\"],
    \"accountAddresses\": $(echo "${JITO_TIP_ACCOUNTS[@]}" | tr ' ' '\n' | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().split()))'),
    \"webhookType\": \"enhanced\"
  }"
```

---

## Signal 6 — Governance Attack Pre-Detection

Governance attacks (Mango, Solend style) require accumulating voting power before execution.
Detect unusual governance token accumulation in the 24–72 hours before an attack.

```typescript
// src/threat-intel/governance-monitor.ts

interface GovernanceAlert {
  suspectWallet: string;
  tokenAccumulated: number;
  percentOfSupply: number;
  accumulationPeriodHours: number;
  walletAge: number;
  riskLevel: "CRITICAL" | "HIGH" | "MEDIUM";
}

export async function monitorGovernanceAccumulation(
  governanceMint: string,
  totalSupply: number,
  heliusApiKey: string,
  alertThresholdPct = 5 // alert if wallet acquires >5% of supply in <72h
): Promise<GovernanceAlert[]> {
  const helius = new (await import("helius-sdk")).Helius(heliusApiKey);
  
  const mintTxs = await helius.rpc.getTransactionHistory({
    address: governanceMint,
    options: { limit: 500 }
  });

  const walletInflows: Record<string, { amount: number; timestamps: number[] }> = {};

  for (const tx of mintTxs) {
    const cutoff = Math.floor(Date.now() / 1000) - 72 * 3600;
    if ((tx.timestamp ?? 0) < cutoff) continue;

    for (const transfer of tx.tokenTransfers ?? []) {
      if (transfer.mint !== governanceMint) continue;
      const dest = transfer.toUserAccount;
      if (!dest) continue;
      if (!walletInflows[dest]) walletInflows[dest] = { amount: 0, timestamps: [] };
      walletInflows[dest].amount += transfer.tokenAmount;
      walletInflows[dest].timestamps.push(tx.timestamp ?? 0);
    }
  }

  const alerts: GovernanceAlert[] = [];

  for (const [wallet, data] of Object.entries(walletInflows)) {
    const pct = (data.amount / totalSupply) * 100;
    if (pct < alertThresholdPct) continue;

    const sortedTs = data.timestamps.sort();
    const periodHours = ((sortedTs[sortedTs.length - 1] - sortedTs[0]) / 3600) || 1;

    alerts.push({
      suspectWallet: wallet,
      tokenAccumulated: data.amount,
      percentOfSupply: pct,
      accumulationPeriodHours: periodHours,
      walletAge: 0, // fill with assessWalletFundingRisk
      riskLevel: pct > 10 ? "CRITICAL" : pct > 5 ? "HIGH" : "MEDIUM"
    });
  }

  return alerts.sort((a, b) => b.percentOfSupply - a.percentOfSupply);
}
```

---

## Threat Intelligence Aggregation Dashboard

Run all signals together and produce a unified threat score:

```typescript
// src/threat-intel/aggregator.ts

interface ThreatAssessment {
  programId: string;
  overallRisk: "CRITICAL" | "HIGH" | "MEDIUM" | "LOW";
  riskScore: number; // 0-100
  activeSignals: string[];
  recommendedAction: string;
  nextReviewIn: string; // "5 min" | "1 hour" | "24 hours"
}

export async function runThreatAssessment(
  programId: string,
  governanceMint: string | null,
  heliusApiKey: string
): Promise<ThreatAssessment> {
  const signals: string[] = [];
  let totalRisk = 0;

  // Run probe detection
  const probes = await detectProbePatterns(programId, heliusApiKey);
  const highProbes = probes.filter(p => p.severity === "HIGH");
  if (highProbes.length > 0) {
    signals.push(`${highProbes.length} HIGH-severity probe wallet(s) detected`);
    totalRisk += 40;
  } else if (probes.length > 0) {
    signals.push(`${probes.length} probe pattern(s) detected`);
    totalRisk += 15;
  }

  // Check watchlist
  // (simplified — in production, check recent program transaction participants)
  
  // Governance monitoring
  if (governanceMint) {
    const govAlerts = await monitorGovernanceAccumulation(
      governanceMint, 1_000_000_000, heliusApiKey
    );
    if (govAlerts.some(a => a.riskLevel === "CRITICAL")) {
      signals.push("Critical governance token accumulation detected");
      totalRisk += 50;
    }
  }

  const overallRisk: ThreatAssessment["overallRisk"] =
    totalRisk >= 70 ? "CRITICAL" :
    totalRisk >= 40 ? "HIGH" :
    totalRisk >= 20 ? "MEDIUM" : "LOW";

  const recommendedAction =
    overallRisk === "CRITICAL" ? "Alert IC immediately. Load skill/anomaly-detection.md. Consider preemptive pause review." :
    overallRisk === "HIGH" ? "Increase monitoring frequency. Brief IC. Review pause mechanisms." :
    overallRisk === "MEDIUM" ? "Add suspect wallets to watchlist. Schedule security review." :
    "Continue normal monitoring cadence.";

  const nextReviewIn =
    overallRisk === "CRITICAL" ? "5 min" :
    overallRisk === "HIGH" ? "1 hour" : "24 hours";

  return {
    programId,
    overallRisk,
    riskScore: Math.min(totalRisk, 100),
    activeSignals: signals,
    recommendedAction,
    nextReviewIn
  };
}
```

---

## Cross-Skill Integration

### Receives from Observability
Load this skill immediately when `Solana-observabilty-skill` emits:
- `OBS_ANOMALY_TO_INCIDENT` signal (see `ecosystem-signals.md`)
- Failed transaction burst above SLO threshold
- Unexpected program authority change alert

### Feeds to Incident Commander
When any Signal 1–6 reaches HIGH or CRITICAL:
```text
THREAT INTEL ALERT → INCIDENT COMMANDER
Type: [probe_detected / watchlist_hit / oracle_deviation / governance_accumulation]
Risk: [score] / 100
Suspect: [wallet_address]
Program: [program_id]
Recommended: [load anomaly-detection / brief IC / preemptive pause review]
Time: [UTC timestamp]
```

### Feeds to Observability
After adding a new suspect wallet to the watchlist, register it as a monitored
address in your Helius webhook configuration:
```
POST to Observability skill: add_monitored_wallet([suspect_address])
Helius webhook auto-registers for enhanced transaction monitoring.
```

---

## Watchlist Management

Keep your protocol-specific watchlist current:

```typescript
// watchlist.json — commit to your private security repo, not public
{
  "protocolWatchlist": [
    {
      "address": "SUSPECT_WALLET_ADDRESS",
      "reason": "Sent 47 failed probes to program on 2026-06-01",
      "addedAt": "2026-06-01T14:22:00Z",
      "addedBy": "security-monitor"
    }
  ],
  "lastUpdated": "2026-06-28T00:00:00Z",
  "version": "1"
}
```

Update after every incident. Add suspect wallets discovered during forensics.
Cross-reference with: https://solanafm.com, https://solscan.io, https://app.blocksec.com

---

## Response Thresholds

| Signal combination | Immediate action |
|---|---|
| High-severity probe + fresh wallet | Alert IC, load anomaly-detection |
| Watchlist wallet + your program | IMMEDIATE P1 declaration |
| Oracle deviation >5% + probe pattern | Pre-emptive IC brief + freeze review |
| Governance >10% accumulation in <48h | Alert IC + legal + community watch |
| Jito bundle surge + volume spike | Load active-exploit-response, declare P0 candidate |
