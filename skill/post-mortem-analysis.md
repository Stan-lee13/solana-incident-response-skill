# Post-Mortem Analysis & Root Cause Investigation

> Load this skill when the immediate crisis is contained and you need to reconstruct
> the attack, identify the root cause, and produce the public post-mortem report.

---

## The Purpose of a Post-Mortem

A post-mortem is not self-flagellation. It is:

1. A forensic reconstruction of what happened

2. A credibility-building document for your community

3. A technical record that helps the entire ecosystem learn

4. A legal document that may be submitted to insurers and regulators

The best post-mortems in Solana history (Wormhole $320M, Mango Markets, Crema Finance) were thorough, honest, and technically precise. The worst ones destroyed remaining community trust through vagueness.

---

## Phase 1 — Transaction Forensics

Reconstruct the attack transaction by transaction.

```typescript
import { Connection, ParsedTransactionWithMeta } from "@solana/web3.js";

const connection = new Connection("https://mainnet.helius-rpc.com/?api-key=YOUR_KEY");

async function reconstructAttack(attackSignatures: string[]) {
  const transactions = await Promise.all(
    attackSignatures.map(sig =>
      connection.getParsedTransaction(sig, {
        maxSupportedTransactionVersion: 0,
        commitment: "confirmed"
      })
    )
  );
  
  const timeline = transactions
    .filter(Boolean)
    .map((tx: ParsedTransactionWithMeta) => ({
      signature: tx!.transaction.signatures[0],
      timestamp: tx!.blockTime ? new Date(tx!.blockTime * 1000).toISOString() : null,
      accounts: tx!.transaction.message.accountKeys.map(k => k.pubkey.toString()),
      instructions: tx!.transaction.message.instructions,
      preBalances: tx!.meta?.preBalances,
      postBalances: tx!.meta?.postBalances,
      preTokenBalances: tx!.meta?.preTokenBalances,
      postTokenBalances: tx!.meta?.postTokenBalances,
      logs: tx!.meta?.logMessages,
      err: tx!.meta?.err,
    }))
    .sort((a, b) => new Date(a.timestamp!).getTime() - new Date(b.timestamp!).getTime());
  
  return timeline;
}

// Calculate exact amounts drained per transaction
function calculateDrainPerTx(tx: any) {
  const drains: { mint: string; amount: bigint; from: string; to: string }[] = [];
  
  tx.preTokenBalances?.forEach((pre: any) => {
    const post = tx.postTokenBalances?.find(
      (p: any) => p.accountIndex === pre.accountIndex
    );
    if (post && BigInt(pre.uiTokenAmount.amount) > BigInt(post.uiTokenAmount.amount)) {
      drains.push({
        mint: pre.mint,
        amount: BigInt(pre.uiTokenAmount.amount) - BigInt(post.uiTokenAmount.amount),
        from: tx.accounts[pre.accountIndex],
        to: "attacker",
      });
    }
  });
  
  return drains;
}

```

---

## Phase 2 — Attack Vector Classification

Map what you found to known attack patterns. Be precise — "a vulnerability" is not acceptable.

### Solana-specific vulnerability taxonomy

#### Account Validation Errors

- Missing owner check: program didn't verify the account is owned by the expected program

- Missing signer check: instruction accepted unsigned accounts

- Missing rent-exempt check: attacker created malicious accounts

- Type confusion: wrong account type accepted without discriminator check

#### Arithmetic Errors

- Integer overflow: amount calculation exceeded u64 max

- Integer underflow: subtraction wrapped around

- Precision loss: decimal truncation exploited

- Rounding error: fee/reward calculation systematic drain

#### Logic Errors

- Reentrancy via CPI: program called back into itself before state was updated

- Price oracle manipulation: stale or manipulable price feed

- Flash loan interaction: attacker used flash loan to temporarily satisfy collateral requirements

- Sandwich attack: attacker front-ran or back-ran a privileged transaction

#### Access Control Errors

- Privilege escalation: attacker found path to elevated permissions

- Authority confusion: wrong account accepted as authority

- Timestamp manipulation: block time used for time-sensitive logic

#### State Errors

- Initialization bypass: uninitialized accounts accepted

- Double-spend: same asset counted twice

- Stale state: cached state not updated before critical check

### Root cause statement template

```

ROOT CAUSE: [One precise sentence]

Example: "A missing owner check on the [ACCOUNT_NAME] account allowed an attacker 
to substitute their own account in place of the protocol's vault, enabling them 
to authorize withdrawals they did not own."

NOT acceptable: "A smart contract vulnerability was exploited."

```

---

## Phase 3 — Impact Quantification

Calculate exactly what was lost.

```typescript
async function calculateTotalImpact(
  attackerWallets: string[],
  attackStartTime: number,
  attackEndTime: number
) {
  // Get all transactions from attacker wallets in the time window
  const transfers: { mint: string; amount: bigint; usdValue: number }[] = [];
  
  for (const wallet of attackerWallets) {
    const response = await fetch(
      `https://api.helius.xyz/v0/addresses/${wallet}/transactions` +
      `?api-key=${HELIUS_KEY}&type=TOKEN_TRANSFER&limit=100`
    );
    const txs = await response.json();
    
    for (const tx of txs) {
      if (tx.timestamp >= attackStartTime && tx.timestamp <= attackEndTime) {
        for (const transfer of tx.tokenTransfers || []) {
          if (transfer.toUserAccount === wallet) {
            transfers.push({
              mint: transfer.mint,
              amount: BigInt(transfer.tokenAmount),
              usdValue: transfer.tokenAmount * await getTokenPriceAtTime(
                transfer.mint,
                tx.timestamp
              ),
            });
          }
        }
      }
    }
  }
  
  const totalUSD = transfers.reduce((sum, t) => sum + t.usdValue, 0);
  return { transfers, totalUSD };
}

```

---

## Phase 4 — Writing the Public Post-Mortem

### Structure (follow this exactly)

```markdown

## [PROTOCOL NAME] — Post-Mortem Report

**Date of incident:** [DATE UTC]
**Date of report:** [DATE UTC]
**Report authors:** [NAMES/HANDLES]

---

## Summary

[2-3 sentences: what happened, how much was lost, current status]

---

## Timeline

[TIMESTAMP UTC] — [Event]
[TIMESTAMP UTC] — [Event]
[TIMESTAMP UTC] — [Event]

Be precise. Include when you discovered it, not just when it happened.

---

## Technical Description

### Attack Vector

[Precise technical description of the vulnerability]

### Attack Execution

[Step-by-step reconstruction of how the attacker exploited it]

### Why It Was Not Caught

[Honest assessment: audit gaps, test coverage, monitoring failure]

---

## Impact

**Total funds affected:** [EXACT AMOUNT in tokens and USD at time of attack]
**Affected users:** [NUMBER] addresses
**Protocol status:** [Current status]

---

## Root Cause

[One paragraph. Be specific. Be honest. Use technical language.]

---

## What We Did

[Timeline of your response actions with exact timestamps]

---

## How We Fixed It

[Technical fix description — what changed in the code, what was added]

---

## Changes We Are Making

[Specific, accountable changes with timelines]

1. [Change 1 — with deadline]

2. [Change 2 — with deadline]

3. [Audit scheduled with X firm by DATE]

---

## User Compensation

[Precise plan: who gets what, how, when]
[If no compensation possible, say so honestly and explain why]

---

## Acknowledgements

[Security researchers, community members who helped]
[If a white hat returned funds, acknowledge them]

---

## Final Statement

[Direct, personal statement from founder/team. Own it.]

```

---

## Reconstruction Tools

```bash

## Solscan transaction decoder

https://solscan.io/tx/TRANSACTION_SIGNATURE

## Helius transaction enrichment

curl "https://api.helius.xyz/v0/transactions?api-key=YOUR_KEY" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"transactions": ["TX_SIGNATURE_1", "TX_SIGNATURE_2"]}'

## Anchor discriminator decoder — identify which instruction was called

## First 8 bytes of instruction data = discriminator

echo "INSTRUCTION_DATA_HEX" | cut -c1-16

## Cross-reference with your IDL to identify the instruction name

anchor idl fetch PROGRAM_ID --output json | jq '.instructions[].discriminator'

```

---

## Engaging External Security Researchers

If you need help reconstructing the attack:

```

Message template for security firms:

"We experienced an exploit on [DATE] affecting [PROTOCOL]. 
We have preserved all forensic data. We are seeking assistance with:

1. Attack vector confirmation

2. Full technical reconstruction

3. Post-mortem review before publication

Budget available for this engagement: [RANGE]

Relevant data: [attack tx signatures], [program IDs], [git commit at time of exploit]"

```

Top firms for post-mortem assistance:

- OtterSec: https://osec.io

- Neodyme: https://neodyme.io

- Trail of Bits: https://www.trailofbits.com

- Halborn: https://halborn.com

---

## Transition Points

- Post-mortem complete, preparing to relaunch → `skill/hardened-redeployment.md`

- Legal obligations from the incident → `skill/legal-regulatory-response.md`
