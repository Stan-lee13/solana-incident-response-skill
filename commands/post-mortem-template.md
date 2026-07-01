# /post-mortem-template

Google SRE-style post-mortem template adapted for Solana protocols and on-chain incident disclosure.

> Use only after containment. Do not publish until forensics, legal, engineering, recovery, and comms approve.

## Required Inputs

```text

1) Protocol name and affected program IDs.

2) Incident start/end: UTC time + slot range.

3) Impacted assets: SOL / SPL / Token-2022 / LP / collateral / governance.

4) Confirmed loss or at-risk amount, with evidence source.

5) Root cause classification.

6) Containment actions and tx signatures.

7) Remediation status: patch, pause, migration, redeploy, compensation.

8) Disclosure constraints: legal, exchange, law enforcement, white-hat negotiation.

```

Unknown items must be labeled `pending verification`.

## Title Block

```text

## [PROTOCOL] Incident Post-Mortem — [DATE]

Status: [draft/final] | Published: [DATE UTC] | Severity: [P0/P1/P2/P3]
Incident window: [START UTC / SLOT] → [END UTC / SLOT]
Affected components: [PROGRAM_ID / POOL / MINT / FRONTEND]
Prepared by: [Incident Commander / Forensics / Engineering / Comms]

```

## 1. Executive Summary

Include what happened, what was affected, confirmed impact, containment status, remediation status, and user action needed.

```text
On [DATE UTC], [PROTOCOL] detected [incident type] affecting [component]. The incident began at [TIME UTC], slot [SLOT], and was contained at [TIME UTC], slot [SLOT].
Confirmed impact: [impact].
Actions taken: [pause/freeze/upgrade/frontend disabled/exchange notification].
Current status: [paused / redeployed / compensation pending / restored].

```

Do not include copycat-enabling exploit mechanics unless the fix is deployed and reviewed.

## 2. Impact Assessment

User impact: funds lost, funds inaccessible, incorrect balances, forced liquidations, trading disruption, or no direct user impact.

| Asset / pool / vault | Mint / account | Pre | Post | Impact |
| --- | --- | ---: | ---: | ---: |
| [name] | [address] | [amount] | [amount] | [loss / locked / none] |

Protocol/market impact: affected program IDs, instructions, PDAs/vaults, paused components, unaffected components, DEX liquidity, CEX status, oracle/liquidation impact, integrator impact.

## 3. Timeline

Use UTC and Solana slots. Every claim should map to evidence.

| Time UTC | Slot | Event | Evidence |
| --- | ---: | --- | --- |
| [time] | [slot] | first known probe transaction | [signature] |
| [time] | [slot] | first successful malicious transaction | [signature] |
| [time] | [slot] | alert fired / user report received | [alert ID] |
| [time] | [slot] | incident declared P0/P1 | [incident log] |
| [time] | [slot] | program paused / freeze executed | [tx signature] |
| [time] | [slot] | exchanges contacted | [ticket ID] |
| [time] | [slot] | public notice posted | [URL] |
| [time] | [slot] | containment confirmed | [evidence] |

Rules: distinguish first known from first detected; mark inferred events; use UTC only; include Jito bundle slot/tip evidence if front-running is relevant.

## 4. Detection

Explain source and latency: Helius webhook, Helius Enhanced Transactions, QuickNode/Triton alert, custom indexer, user/Discord report, or exchange notice. Note latency from first malicious slot, failed probes, oracle deviations, and whether frontend/backend/keeper/RPC logs had earlier evidence.

## 5. Root Cause

| Classification | Use when | Solana examples |
| --- | --- | --- |
| Oracle manipulation | price inputs enabled extraction | Mango-style market manipulation |
| Account confusion | unauthorized accounts passed validation | Cashio-style spoofing |
| CPI / reentrancy-equivalent | unsafe CPI order or state-after-CPI bug | CPI side-effect exploit |
| Upgrade exploit | unsafe or malicious upgrade path | BPFLoaderUpgradeable authority compromise |
| Access control failure | missing signer, owner, `has_one`, seeds, constraints | Anchor constraint bypass |
| Economic attack | intended rules allowed extreme extraction | AMM/liquidation design failure |
| Bridge verification failure | message/signature/guardian validation failed | Wormhole-style issue |
| Infrastructure compromise | frontend, RPC, API key, keeper, deploy pipeline | malicious tx construction |

```text
Primary root cause: [classification]
Affected instruction/account path: [high level for public version]
Why existing controls failed: [explanation]
Why tests/audits/monitoring missed it: [explanation]

```

## 6. Contributing Factors

Examples: pause authority not separated from upgrade authority; Squads v4 quorum unavailable; missing rate limits; missing Anchor constraints (`has_one`, `owner`, `seeds`, `signer`, `constraint`); permissive oracle thresholds; manual frontend kill switch; Helius webhook missed failed probes; no exchange emergency package.

## 7. Response and Containment

| Action | Time UTC | Owner | Tx / evidence | Result |
| --- | --- | --- | --- | --- |
| declared incident | [time] | Incident Commander | [log] | [result] |
| preserved evidence | [time] | Forensics | [artifact] | [result] |
| paused program | [time] | Engineering / Squads | [tx] | [result] |
| disabled frontend | [time] | Frontend | [deploy hash] | [result] |
| contacted exchanges | [time] | Comms / Legal | [ticket] | [result] |
| started recovery | [time] | Recovery Engineer | [plan] | [result] |

Explain tradeoffs: pause vs no pause, freeze vs drain-to-safety, disclose vs delay.

## 8. Remediation

Completed: vulnerable instruction disabled or patched; program paused until reviewed; upgrade authority moved to Squads v4; emergency pause added or hardened; Helius rules updated; frontend kill switch tested; affected users identified; exchange or partner notices completed.

Planned: independent audit; fuzz/property tests; account validation review; oracle circuit breakers; rate limits; hardened redeployment using `skill/hardened-redeployment.md`; compensation or Merkle claim distribution if applicable.

## 9. Recovery and Compensation

```text
Recovered funds: [amount / pending]
Unrecovered funds: [amount / pending]
Compensation model: [treasury / insurance / Merkle distribution / governance vote / none]
Claim eligibility slot: [slot]
Claim process status: [planned / live / complete]

```

If white-hat negotiation occurred, summarize returned funds and bounty without promising legal conclusions.

## 10. Disclosure Obligations

- [ ] exchange notifications completed; law enforcement/regulator notifications assessed

- [ ] OFAC / sanctions screening completed for returned or traced funds

- [ ] insurer, investor, partner, and user notice requirements reviewed by counsel

## 11. Action Items

| Priority | Action item | Owner | Deadline | Verification |
| --- | --- | --- | --- | --- |
| P0 | [must complete before unpause] | [role] | [date] | [test/audit/tx] |
| P1 | [complete before redeploy] | [role] | [date] | [evidence] |
| P2 | [process improvement] | [role] | [date] | [runbook/update] |

No owner, deadline, or verification means the item is not complete.

## 12. Final Approval Gate

- [ ] Forensics, Engineering, IC, Legal, Comms, and Recovery approve facts, root cause, decision record, disclosure, tone, and compensation/redeployment status.

`Next update: [DATE UTC]` — Official channels: [LINKS]
