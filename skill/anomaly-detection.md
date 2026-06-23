# Anomaly Detection & Threat Classification

> Load this skill when you see suspicious activity but are not yet sure
> if you are under active attack. Early detection saves millions.

---

## Anomaly Detection Patterns

### Transaction volume anomalies

```typescript
import { Connection } from "@solana/web3.js";

const connection = new Connection("https://mainnet.helius-rpc.com/?api-key=YOUR_KEY");

async function detectVolumeAnomaly(programId: string, windowMinutes: number = 5) {
  const response = await fetch(
    `https://api.helius.xyz/v0/addresses/${programId}/transactions` +
    `?api-key=${HELIUS_KEY}&limit=200`
  );
  const txs = await response.json();
  
  const now = Date.now() / 1000;
  const windowStart = now - (windowMinutes * 60);
  
  // Count transactions in window
  const recentTxs = txs.filter((tx: any) => tx.timestamp > windowStart);
  
  // Get baseline (last 24h average per 5 min window)
  const dayAgo = now - 86400;
  const dayTxs = txs.filter((tx: any) => tx.timestamp > dayAgo);
  const baseline = dayTxs.length / (24 * 12); // avg per 5-min window
  
  const volumeMultiplier = recentTxs.length / Math.max(baseline, 1);
  
  if (volumeMultiplier > 10) {
    return {
      anomaly: true,
      severity: "CRITICAL",
      message: `${volumeMultiplier.toFixed(1)}x normal transaction volume`,
      recentCount: recentTxs.length,
      baseline: baseline.toFixed(1),
    };
  }
  
  return { anomaly: false, volumeMultiplier };
}
```

### Single wallet concentration

```typescript
async function detectWalletConcentration(programId: string) {
  const response = await fetch(
    `https://api.helius.xyz/v0/addresses/${programId}/transactions` +
    `?api-key=${HELIUS_KEY}&limit=100&type=TOKEN_TRANSFER`
  );
  const txs = await response.json();
  
  const walletCounts: Record<string, number> = {};
  
  txs.forEach((tx: any) => {
    tx.feePayer && (walletCounts[tx.feePayer] = (walletCounts[tx.feePayer] || 0) + 1);
  });
  
  const sorted = Object.entries(walletCounts)
    .sort(([, a], [, b]) => b - a);
  
  // Alert if single wallet represents >20% of recent transactions
  if (sorted.length > 0) {
    const [topWallet, topCount] = sorted[0];
    const concentration = topCount / txs.length;
    
    if (concentration > 0.2) {
      return {
        anomaly: true,
        severity: concentration > 0.5 ? "CRITICAL" : "HIGH",
        wallet: topWallet,
        percentage: (concentration * 100).toFixed(1) + "%",
        message: `Single wallet responsible for ${(concentration * 100).toFixed(1)}% of recent transactions`,
      };
    }
  }
  
  return { anomaly: false };
}
```

### Oracle deviation detection

```typescript
import { PythHttpClient, getPythClusterApiUrl, getPythProgramKeyForCluster } from "@pythnetwork/client";
import { Connection, clusterApiUrl } from "@solana/web3.js";

async function detectOracleDeviation(feedId: string, thresholdPct: number = 3) {
  const connection = new Connection("https://mainnet.helius-rpc.com/?api-key=YOUR_KEY");
  const pythClient = new PythHttpClient(
    connection,
    getPythProgramKeyForCluster("mainnet-beta")
  );
  
  const data = await pythClient.getData();
  
  // Sample price over 5 slots
  const prices: number[] = [];
  for (let i = 0; i < 5; i++) {
    const feed = data.productPrice.get(feedId);
    if (feed?.price) prices.push(feed.price);
    await new Promise(r => setTimeout(r, 400)); // ~1 slot
  }
  
  if (prices.length < 2) return { anomaly: false };
  
  const maxChange = Math.max(...prices.map((p, i) => {
    if (i === 0) return 0;
    return Math.abs((p - prices[i - 1]) / prices[i - 1]) * 100;
  }));
  
  if (maxChange > thresholdPct) {
    return {
      anomaly: true,
      severity: maxChange > 10 ? "CRITICAL" : "HIGH",
      maxChangePct: maxChange.toFixed(2),
      message: `Oracle price moved ${maxChange.toFixed(2)}% in under 2 seconds`,
    };
  }
  
  return { anomaly: false };
}
```

---

## Threat Classification Matrix

```
SEVERITY LEVELS:

CRITICAL — Respond within 5 minutes
  Signs: Active drain, >$100K moved, program being called by unknown wallets
  Action: Load active-exploit-response.md, wake team immediately

HIGH — Respond within 15 minutes  
  Signs: Anomalous volume spike, single wallet concentration, oracle deviation
  Action: Convene technical lead, begin monitoring escalation, prepare freeze

MEDIUM — Respond within 1 hour
  Signs: Unusual instruction patterns, elevated transaction frequency, new wallet exploring contract
  Action: Technical review, check if behavior matches known attack patterns

LOW — Respond within 24 hours
  Signs: Minor anomalies, single failed exploit attempt (reverted tx), social media FUD
  Action: Log and monitor, review after normal working hours
```

---

## Pre-Exploit Attack Recon Detection

Attackers often probe before exploiting. Watch for:

```typescript
// Detect failed transactions to your program (revert = attacker testing)
async function detectFailedTransactions(programId: string) {
  const response = await fetch(
    `https://api.helius.xyz/v0/addresses/${programId}/transactions` +
    `?api-key=${HELIUS_KEY}&limit=100`
  );
  const txs = await response.json();
  
  const failedTxs = txs.filter((tx: any) => tx.transactionError !== null);
  const failedByWallet: Record<string, number> = {};
  
  failedTxs.forEach((tx: any) => {
    const wallet = tx.feePayer;
    failedByWallet[wallet] = (failedByWallet[wallet] || 0) + 1;
  });
  
  // Multiple failed txs from same wallet = attacker probing
  Object.entries(failedByWallet)
    .filter(([, count]) => count >= 3)
    .forEach(([wallet, count]) => {
      console.warn(`⚠️ Suspicious: ${wallet} had ${count} failed transactions`);
    });
}
```

---

## Setting Up Automated Monitoring

```typescript
// Helius webhook handler — deploy as an edge function
export async function handleWebhook(req: Request) {
  const events = await req.json();
  
  for (const event of events) {
    // Check for large single transactions
    const totalValueMoved = event.nativeTransfers?.reduce(
      (sum: number, t: any) => sum + t.amount, 0
    ) || 0;
    
    if (totalValueMoved > 1_000_000_000) { // >1000 SOL
      await sendAlert({
        level: "HIGH",
        message: `Large movement: ${totalValueMoved / 1e9} SOL`,
        signature: event.signature,
      });
    }
    
    // Check for program upgrades
    if (event.type === "PROGRAM_UPGRADE") {
      await sendAlert({
        level: "CRITICAL",
        message: `Program upgraded! Signature: ${event.signature}`,
        requiresImmediateReview: true,
      });
    }
    
    // Check for authority changes
    if (event.type === "SET_AUTHORITY") {
      await sendAlert({
        level: "CRITICAL",
        message: `Authority changed on account ${event.accountData?.[0]?.account}`,
        signature: event.signature,
      });
    }
  }
}

async function sendAlert(alert: { level: string; message: string; [key: string]: any }) {
  // PagerDuty
  await fetch("https://events.pagerduty.com/v2/enqueue", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      routing_key: PAGERDUTY_KEY,
      event_action: alert.level === "CRITICAL" ? "trigger" : "acknowledge",
      payload: {
        summary: alert.message,
        severity: alert.level.toLowerCase(),
        source: "solana-incident-skill",
        custom_details: alert,
      },
    }),
  });
  
  // Telegram
  await fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      chat_id: TELEGRAM_CHAT_ID,
      text: `🚨 [${alert.level}] ${alert.message}`,
      parse_mode: "Markdown",
    }),
  });
}
```
