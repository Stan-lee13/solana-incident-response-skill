# Anomaly Detection & Early Warning

> Load when you see suspicious activity but are not yet sure if you are under attack.
> Early detection is the difference between a $50K incident and a $50M incident.

The goal is to detect the probe and the dry runs — not just the exploit itself.

---

## The Attacker's Signature Before the Attack

Attackers do not succeed on the first try. They:

1. Deploy a test contract on devnet or localnet

2. Probe your mainnet program with failing transactions (testing account validation)

3. Run a small-scale exploit first (confirm it works, estimate gas)

4. Scale up once confirmed

### You should detect them at step 2 — not step 4

---

## Detection Pattern 1: Transaction Volume Spike

A 10x spike in program interactions in a 5-minute window is the most common early signal.

```typescript
// src/monitors/volume-detector.ts
import { Helius } from "helius-sdk";

const helius = new Helius(process.env.HELIUS_API_KEY!);

async function detectVolumeAnomaly(programId: string): Promise<{
  anomaly: boolean;
  severity: "CRITICAL" | "HIGH" | "MEDIUM" | "NORMAL";
  currentRate: number;
  baselineRate: number;
  multiplier: number;
}> {
  const txs = await helius.rpc.getTransactionHistory({
    address: programId,
    options: { limit: 500 }
  });
  
  const now = Date.now() / 1000;
  
  // Current 5-minute window
  const recent = txs.filter(tx => tx.timestamp > now - 300);
  const currentRate = recent.length / 5; // per minute
  
  // 24-hour baseline (average per 5-minute window)
  const dayAgo = now - 86400;
  const dayTxs = txs.filter(tx => tx.timestamp > dayAgo);
  const baselineRate = (dayTxs.length / (24 * 60)) ; // per minute
  
  const multiplier = currentRate / Math.max(baselineRate, 0.1);
  
  if (multiplier > 20) return { anomaly: true, severity: "CRITICAL", currentRate, baselineRate, multiplier };
  if (multiplier > 10) return { anomaly: true, severity: "HIGH", currentRate, baselineRate, multiplier };
  if (multiplier > 5)  return { anomaly: true, severity: "MEDIUM", currentRate, baselineRate, multiplier };
  return { anomaly: false, severity: "NORMAL", currentRate, baselineRate, multiplier };
}

```

---

## Detection Pattern 2: Failed Transactions from Unknown Wallets

The most reliable probe signal: a wallet that has never interacted with your program before, running failed transactions in rapid succession.

```typescript
async function detectProbeTransactions(programId: string): Promise<{
  suspectedProbers: Array<{
    wallet: string;
    failedCount: number;
    successCount: number;
    firstSeen: string;
    errorTypes: string[];
  }>;
}> {
  const txs = await helius.rpc.getTransactionHistory({
    address: programId,
    options: { limit: 200 }
  });
  
  const now = Date.now() / 1000;
  const last2h = txs.filter(tx => tx.timestamp > now - 7200);
  
  // Group by fee payer
  const byWallet: Record<string, typeof last2h> = {};
  last2h.forEach(tx => {
    if (!byWallet[tx.feePayer]) byWallet[tx.feePayer] = [];
    byWallet[tx.feePayer].push(tx);
  });
  
  const probers = Object.entries(byWallet)
    .map(([wallet, walletTxs]) => {
      const failed = walletTxs.filter(tx => tx.transactionError !== null);
      const succeeded = walletTxs.filter(tx => tx.transactionError === null);
      const errorTypes = [...new Set(failed.map(tx => 
        JSON.stringify(tx.transactionError).substring(0, 100)
      ))];
      
      return {
        wallet,
        failedCount: failed.length,
        successCount: succeeded.length,
        firstSeen: new Date(walletTxs[0].timestamp * 1000).toISOString(),
        errorTypes,
        isSuspicious: failed.length >= 3 && failed.length > succeeded.length,
      };
    })
    .filter(w => w.isSuspicious);
  
  return { suspectedProbers: probers };
}

```

---

## Detection Pattern 3: Flash Loan in Same Transaction

A flash loan + your program in the same atomic transaction is almost always adversarial. Legitimate use cases exist but are rare.

```typescript
// Known flash loan program IDs on Solana (update as ecosystem evolves)
const FLASH_LOAN_PROGRAMS = new Set([
  "So1endDq2YkqhipRh3WViPa8hdiSpxWy6z3Z6tMCpAo",  // Solend
  "KLend2g3cP87fffoy8q1mQqGKjrxjC8boSyAYavgmjD",   // Kamino Lend
  "MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA",   // MarginFi
]);

async function detectFlashLoanAttacks(programId: string): Promise<Array<{
  signature: string;
  flashLoanProgram: string;
  yourProgramInvoked: boolean;
  tokenDrained: string | null;
  timestamp: string;
}>> {
  const txs = await helius.rpc.getTransactionHistory({
    address: programId,
    options: { limit: 100 }
  });
  
  const suspicious = [];
  
  for (const tx of txs) {
    const involvedPrograms = new Set(
      tx.instructions?.map(ix => ix.programId) ?? []
    );
    
    const flashLoanProgram = [...FLASH_LOAN_PROGRAMS].find(p => involvedPrograms.has(p));
    
    if (flashLoanProgram && involvedPrograms.has(programId)) {
      // Flash loan + your program = inspect closely
      const largestOutflow = tx.tokenTransfers
        ?.filter(t => t.fromUserAccount !== tx.feePayer)
        ?.sort((a, b) => Number(BigInt(b.tokenAmount) - BigInt(a.tokenAmount)))?.[0];
      
      suspicious.push({
        signature: tx.signature,
        flashLoanProgram,
        yourProgramInvoked: true,
        tokenDrained: largestOutflow?.mint ?? null,
        timestamp: new Date(tx.timestamp * 1000).toISOString(),
      });
    }
  }
  
  return suspicious;
}

```

---

## Detection Pattern 4: Oracle Price Deviation

If your protocol uses price oracles, a sudden oracle deviation before program interactions is a manipulation signal.

```typescript
import { Connection, PublicKey } from "@solana/web3.js";
import { PriceServiceConnection } from "@pythnetwork/price-service-client";

const PRICE_DEVIATION_THRESHOLD = 0.05; // 5% deviation = alert
const MAX_CONFIDENCE_RATIO = 0.02;      // confidence >2% of price = degraded
const MAX_STALENESS_SECONDS = 30;

type OracleSnapshot = {
  price: number;
  confidence?: number;
  publishTime?: number;
  provider: "pyth" | "switchboard" | "custom";
};

function normalizePythPrice(raw: { price: string; expo: number; conf: string; publish_time: number }): OracleSnapshot {
  const scale = Math.pow(10, raw.expo);
  return {
    price: Number(raw.price) * scale,
    confidence: Number(raw.conf) * scale,
    publishTime: raw.publish_time,
    provider: "pyth",
  };
}

async function detectOracleDeviation(
  pythPriceId: string,
  onChainOracleAddress: string,
  parseOnChainOracle: (data: Buffer) => OracleSnapshot
): Promise<{ deviation: number; isAnomaly: boolean; reason: string[]; onChainPrice: number; pythPrice: number }> {
  const connection = new Connection(process.env.HELIUS_RPC_URL!, "confirmed");
  const pythConnection = new PriceServiceConnection("https://hermes.pyth.network");
  const [pythFeed] = await pythConnection.getLatestPriceFeeds([pythPriceId]);
  const pythRaw = pythFeed?.getPriceUnchecked();
  if (!pythRaw) throw new Error("Could not fetch Pyth reference price");

  const pyth = normalizePythPrice(pythRaw);
  const oracleAccount = await connection.getAccountInfo(new PublicKey(onChainOracleAddress), "confirmed");
  if (!oracleAccount) throw new Error("On-chain oracle account not found");

  // Implement parser per provider: Pyth pull account, Switchboard aggregator, or protocol custom oracle PDA.
  const onChain = parseOnChainOracle(oracleAccount.data);
  const deviation = Math.abs(onChain.price - pyth.price) / Math.abs(pyth.price);
  const reason: string[] = [];

  if (deviation > PRICE_DEVIATION_THRESHOLD) reason.push("price_deviation");
  if (onChain.confidence && Math.abs(onChain.confidence / onChain.price) > MAX_CONFIDENCE_RATIO) reason.push("wide_confidence_interval");
  if (onChain.publishTime && Date.now() / 1000 - onChain.publishTime > MAX_STALENESS_SECONDS) reason.push("stale_on_chain_price");
  if (pyth.confidence && Math.abs(pyth.confidence / pyth.price) > MAX_CONFIDENCE_RATIO) reason.push("degraded_reference_price");

  return { deviation, isAnomaly: reason.length > 0, reason, onChainPrice: onChain.price, pythPrice: pyth.price };
}

```

Operational notes:

- For Pyth, monitor price ID, confidence interval, publish time, and whether the feed is in trading status.

- For Switchboard, monitor aggregator `latestConfirmedRound`, staleness, queue authority changes, and crank delays.

- For custom oracle PDAs, document the exact account layout and owner; alert if owner or authority changes.

---

## Detection Pattern 5: Wallet Concentration & New Wallet Surge

```typescript
async function detectWalletAnomaly(programId: string): Promise<{
  topWalletConcentration: number;
  topWallet: string;
  newWalletsIn2h: number;
  isAnomaly: boolean;
}> {
  const txs = await helius.rpc.getTransactionHistory({
    address: programId,
    options: { limit: 200 }
  });
  
  const now = Date.now() / 1000;
  const recent = txs.filter(tx => tx.timestamp > now - 7200); // 2h window
  const older = txs.filter(tx => tx.timestamp <= now - 7200);
  
  const knownWallets = new Set(older.map(tx => tx.feePayer));
  const newWalletsIn2h = recent.filter(tx => !knownWallets.has(tx.feePayer)).length;
  
  // Concentration: what % of recent txs come from one wallet
  const walletCounts: Record<string, number> = {};
  recent.forEach(tx => walletCounts[tx.feePayer] = (walletCounts[tx.feePayer] ?? 0) + 1);
  
  const topEntry = Object.entries(walletCounts).sort(([,a],[,b]) => b-a)[0] ?? ["unknown", 0];
  const topWalletConcentration = topEntry[1] / Math.max(recent.length, 1);
  
  return {
    topWalletConcentration,
    topWallet: topEntry[0],
    newWalletsIn2h,
    isAnomaly: topWalletConcentration > 0.30 || newWalletsIn2h > 20,
  };
}

```

---

## Detection Pattern 6: Governance Attack Signals

Governance exploits follow a specific pattern: rapid token accumulation → proposal → immediate execution.

```typescript
async function detectGovernanceAttack(
  governanceProgramId: string,
  tokenMint: string
): Promise<{ alert: boolean; details: string }> {
  // Signs of a governance attack:
  // 1. Large token purchase in short window
  // 2. New proposal created immediately after
  // 3. Voting compressed into minimum time window
  // 4. Proposal contains treasury drain or authority transfer
  
  const SUSPICIOUS_PATTERNS = [
    "transfer authority",
    "upgrade program",
    "drain treasury",
    "set admin",
    "disable timelock",
  ];
  
  // Check recent governance proposals for suspicious instructions
  // Implementation depends on governance program (SPL Governance, Realms, etc.)
  
  return { alert: false, details: "Requires governance program address to check" };
}

```

---

## Detection Pattern 7: CPI Depth Anomaly

A legitimate user transaction rarely exceeds 3-4 CPI levels. Exploit transactions often chain 8+ nested calls.

```typescript
function detectCPIDepthAnomaly(logMessages: string[]): {
  maxDepth: number;
  isAnomaly: boolean;
  deepestCallChain: string[];
} {
  let maxDepth = 0;
  let currentDepth = 0;
  const callStack: string[] = [];
  const deepestCallChain: string[] = [];
  
  for (const log of logMessages) {
    if (log.includes("Program") && log.includes("invoke")) {
      currentDepth++;
      const programMatch = log.match(/Program (\w+) invoke/);
      if (programMatch) callStack.push(programMatch[1]);
      
      if (currentDepth > maxDepth) {
        maxDepth = currentDepth;
        deepestCallChain.length = 0;
        deepestCallChain.push(...callStack);
      }
    } else if (log.includes("Program") && log.includes("success")) {
      currentDepth = Math.max(0, currentDepth - 1);
      callStack.pop();
    } else if (log.includes("Program") && log.includes("failed")) {
      currentDepth = Math.max(0, currentDepth - 1);
      callStack.pop();
    }
  }
  
  return {
    maxDepth,
    isAnomaly: maxDepth > 6,
    deepestCallChain,
  };
}

```

---

## Setting Up Continuous Monitoring

Run all detectors in a loop with alerting:

```typescript
// src/monitors/watchdog.ts
import { sendDiscordAlert } from "./discord";

async function runWatchdog(programId: string) {
  const POLL_INTERVAL_MS = 30_000; // 30 seconds
  
  console.log(`🔍 Watchdog started for ${programId}`);
  
  setInterval(async () => {
    try {
      const [volume, probes, flashLoans, wallets] = await Promise.all([
        detectVolumeAnomaly(programId),
        detectProbeTransactions(programId),
        detectFlashLoanAttacks(programId),
        detectWalletAnomaly(programId),
      ]);
      
      const alerts: string[] = [];
      
      if (volume.anomaly) {
        alerts.push(`📈 Volume spike: ${volume.multiplier.toFixed(1)}x normal (${volume.severity})`);
      }
      if (probes.suspectedProbers.length > 0) {
        alerts.push(`🔍 ${probes.suspectedProbers.length} wallets probing with failed transactions`);
        probes.suspectedProbers.forEach(p => 
          alerts.push(`  → ${p.wallet}: ${p.failedCount} failures, ${p.successCount} successes`)
        );
      }
      if (flashLoans.length > 0) {
        alerts.push(`⚡ ${flashLoans.length} flash loan + program interactions detected`);
      }
      if (wallets.isAnomaly) {
        alerts.push(`👛 Wallet anomaly: ${(wallets.topWalletConcentration * 100).toFixed(0)}% from one wallet, ${wallets.newWalletsIn2h} new wallets`);
      }
      
      if (alerts.length > 0) {
        const severity = volume.severity === "CRITICAL" || flashLoans.length > 0 ? "CRITICAL" : "HIGH";
        await sendDiscordAlert({
          severity,
          programId,
          alerts,
          timestamp: new Date().toISOString(),
        });
      }
    } catch (err) {
      console.error("Watchdog error:", err);
    }
  }, POLL_INTERVAL_MS);
}

runWatchdog(process.env.PROGRAM_ID!);

```

---

## Threat Classification Matrix

| Signal | Alone | Combined | Response |
| -------- | ------- | ---------- | ---------- |
| Volume 5x | MEDIUM | + new wallet | HIGH |
| Volume 20x+ | HIGH | + flash loan | CRITICAL |
| Failed tx probes | MEDIUM | + success after | HIGH → load active-exploit-response.md |
| Flash loan + program | HIGH | + volume spike | CRITICAL |
| Oracle deviation 5%+ | HIGH | + your program call | CRITICAL |
| New wallet surge | LOW | + concentrated | MEDIUM |
| CPI depth >6 | HIGH | + fund drain | CRITICAL |
| Governance proposal | MEDIUM | + treasury target | HIGH |

**When severity reaches CRITICAL → load `skill/active-exploit-response.md` immediately.**
