# /incident-triage

Systematic triage protocol for Solana security incidents. Run this before deep investigation unless funds are visibly draining; if so, declare P0 and contain in parallel.

> Prime directive: preserve evidence before state changes; contain before root cause; communicate only through approved channels.

## Usage

Run `/incident-triage`. Ask the 5 questions in one message. If unknown, record `Unknown`. Target: severity and first actions within 3 minutes.

## The 5 Questions

```text
Q1) CONFIRMATION STATUS
[ ] A — Confirmed: on-chain loss or unauthorized state change
[ ] B — Suspected: alert/anomaly/user report; loss not verified
[ ] C — Unclear: possible UI/RPC issue or weak evidence

Q2) CURRENT STATUS
[ ] X — Ongoing: suspect txs still appearing or repeatable path exists
[ ] Y — Stopped: no suspect txs for >10 min and control path known
[ ] Z — Unknown: monitoring unavailable or history incomplete

Q3) MAXIMUM PLAUSIBLE SCOPE
[ ] 1 — <$10K
[ ] 2 — $10K–$100K
[ ] 3 — $100K–$1M
[ ] 4 — >$1M, bridge collateral, token supply, or governance control
[ ] 5 — Unknown / still assessing

Q4) CONTROL SURFACE
[ ] Emergency pause instruction exists
[ ] Upgrade authority exists and is reachable
[ ] Upgrade authority is Squads v4: threshold ___ of ___; reachable ___
[ ] SPL / Token-2022 mint freeze authority exists
[ ] Frontend kill switch exists
[ ] Program is immutable or authority unreachable
[ ] Unknown

Q5) PRIMARY SIGNAL / INCIDENT TYPE
[ ] 1 — Vault drain / unauthorized withdrawal (Cashio-style)
[ ] 2 — Unauthorized mint / supply inflation
[ ] 3 — Oracle manipulation / economic attack (Mango-style)
[ ] 4 — Governance, Squads, SPL Governance, or admin takeover
[ ] 5 — Bridge or wrapped asset failure (Wormhole-style)
[ ] 6 — Account confusion / Anchor constraint bypass / CPI abuse
[ ] 7 — Frontend, RPC, webhook, or infrastructure compromise
[ ] 8 — Unknown
```

## Severity Classification

| Severity | Definition | Solana examples | Target |
|---|---|---|---|
| P0 | Active or imminent material loss, privileged takeover, token integrity failure | Wormhole-style bridge drain, Cashio-style spoofing, hostile upgrade authority | 0–3 min |
| P1 | Confirmed loss or high-confidence exploit, not actively draining | stopped Crema-style exploit, Mango-style oracle attack after state change | 10 min |
| P2 | Suspicious anomaly with limited scope or uncertain loss | failed probes, odd oracle prints, unexpected CPI failures | 60 min |
| P3 | No security impact confirmed | UI bug, stale dashboard, RPC outage | same day |

| Confirmation | Ongoing | Scope | Severity |
|---|---|---|---|
| Confirmed | Yes | Any | P0 |
| Confirmed | No | >$1M / token / governance | P0 |
| Confirmed | No | $10K–$1M | P1 |
| Suspected | Yes | Any | P1; P0 if no control path |
| Suspected | No | >$100K or unknown | P1 |
| Suspected | No | <$100K | P2 |
| Unclear | Unknown | Any | P2 |
| Unclear | No impact | Any | P3 |

P0 override: authority compromise, bridge/mint/oracle risk, unknown max loss with no pause, repeatable attacker path, or public exploit details spreading.

## Rapid Risk Score

```text
Confirmed unauthorized state change or loss              +30
Ongoing attacker activity or repeatable path              +25
Scope ≥ $1M or unknown                                    +20
No reachable pause/freeze/upgrade path                    +15
Authority compromise or governance takeover signal        +15
CEX/bridge destination observed                           +10
Public rumor already spreading                             +5
```

Interpretation: `≥70` P0, `50–69` P1, `30–49` P2, `<30` P2/P3.

## Sub-Skills to Load

| Type | Load now | Load after containment |
|---|---|---|
| Active drain | `skill/active-exploit-response.md`, `skill/program-freeze-and-pause.md` | `skill/post-mortem-analysis.md` |
| Mint / token integrity | `skill/program-freeze-and-pause.md`, `skill/legal-regulatory-response.md` | `skill/hardened-redeployment.md` |
| Oracle manipulation | `skill/anomaly-detection.md`, `skill/active-exploit-response.md` | `skill/liquidity-migration.md` |
| Governance / admin | `skill/program-upgrade-safety.md`, `skill/program-freeze-and-pause.md` | `skill/legal-regulatory-response.md` |
| Bridge | `skill/active-exploit-response.md`, `skill/liquidity-migration.md` | `skill/legal-regulatory-response.md` |
| Frontend / infra | `skill/crisis-communication.md`, `skill/anomaly-detection.md` | `skill/post-mortem-analysis.md` |
| Unknown | `skill/anomaly-detection.md` | escalate by evidence |

## Agent Assignment

Always activate for P0/P1: `agents/incident-commander.md`, `agents/forensic-investigator.md`, `agents/comms-director.md`.

Activate when relevant: `agents/recovery-engineer.md` after containment; `agents/upgrade-commander.md` for authority, layout, upgrade, or governance issues.

## Immediate Actions

P0:
```text
[ ] Declare P0 and start UTC incident log.
[ ] Open war room and assign Incident Commander.
[ ] Preserve minimum evidence: sigs, slot range, account snapshots.
[ ] Execute fastest safe containment: pause, freeze, frontend kill switch, or emergency upgrade.
[ ] Draft holding statement; do not publish exploit mechanics.
[ ] Notify exchanges if token integrity, CEX deposits, or attacker outflow exists.
```
P1:
```text
[ ] Start incident log and preserve evidence before remediation.
[ ] Validate whether attacker path remains repeatable.
[ ] Prepare pause/freeze action and signer availability.
[ ] Produce community holding draft within 60 min if users are exposed.
```
P2/P3:
```text
[ ] Keep investigation private.
[ ] Pull Helius Enhanced Transactions for suspect signatures.
[ ] Do not post publicly unless user action is required.
[ ] Reclassify within 60 min or when evidence changes.
```

## Required Output Format

```text
INCIDENT STATUS: [P0/P1/P2/P3]
PRIMARY TYPE: [vault drain / mint / oracle / governance / bridge / CPI / infra / unknown]
RISK SCORE: [score]/100
FUND MOVEMENT: [yes/no/unknown]
CONTROL PATH: [pause / freeze / upgrade / frontend kill switch / none / unknown]
SUB-SKILLS TO LOAD:
  - [skill file]
AGENTS TO ACTIVATE:
  - [agent file]
IMMEDIATE ACTIONS:
  1. [first action]
  2. [second action]
  3. [third action]
NEXT DECISION DEADLINE: [UTC time]
```
