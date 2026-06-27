# Ecosystem Signals: solana-incident-response-skill

This file defines how `solana-incident-response-skill` collaborates with the other four Solana engineering skills.
Incident Response owns exploit triage, containment, forensics, crisis communications, recovery coordination, and post-incident hardening.

---
## Ecosystem Peers
| Skill | Owns | Incident-response boundary |
|---|---|---|
| `solana-depin-builder-skill` | DePIN node networks, oracle integration, proof validation, rewards | Receives oracle, fake-node, and reward-exploit hardening signals |
| `Solana-observabilty-skill` | Alerts, Helius/QuickNode/Triton telemetry, dashboards | Sends anomalies; receives new monitoring rules after incidents |
| `solana-token-launch-skill` | TGE, mints, vesting, claims, liquidity, treasury controls | Receives token contract and mint compromise signals |
| `solana-ux-skill` | Wallet safety, transaction UX, status pages, onboarding | Receives frontend compromise and user-protection signals |

---
## Receives from Observability
`Solana-observabilty-skill` triggers this skill when an anomaly exceeds threshold and may be P0/P1.
Run `/incident-triage` when any are observed:
- Helius webhook detects unexpected transfers from protocol vaults.
- Failed transaction bursts hit the same Anchor instruction discriminator before success.
- Oracle deviation affects borrow, liquidation, reward, mint, or routing logic.
- BPFLoaderUpgradeable touches program-data outside an approved upgrade window.
- Squads v4 or SPL Governance proposal executes outside the planned schedule.
- SPL or Token-2022 supply changes without an approved mint event.
- Jito bundle activity surrounds suspicious protocol transactions.
- Frontend telemetry shows wallet-drain signatures or transaction payload mismatch.
```text
SIGNAL: OBS_ANOMALY_TO_INCIDENT
SOURCE_SKILL: Solana-observabilty-skill
SEVERITY_HINT: [critical/high/medium/low]
PROGRAM_ID: [program id]
SLOT_RANGE: [start slot - latest slot]
SIGNATURES: [sig1, sig2]
AFFECTED_ACCOUNTS: [vaults, mints, PDAs, oracle accounts]
PATTERN: [vault drain / oracle skew / mint anomaly / governance action / frontend mismatch]
ACTION: run /incident-triage
```
Incident-response action: run `/incident-triage`; if P0/P1 load `agents/incident-commander.md` and `agents/forensic-investigator.md`; load `agents/comms-director.md` for user/exchange/partner/media exposure; load `agents/recovery-engineer.md` only after containment.

---
## Alert Routing Table
| Alert | Severity floor | Incident action | Load |
|---|---:|---|---|
| Active vault drain | P0 | Contain immediately | `skill/active-exploit-response.md`, `skill/program-freeze-and-pause.md` |
| Unexpected upgrade authority change | P0 | Declare authority-compromise incident, freeze upgrade path, validate Squads/SPL Governance | `skill/active-exploit-response.md`, `skill/program-freeze-and-pause.md`, `agents/incident-commander.md` |
| Mint supply anomaly | P0 | Engage token safety and exchange notifications | `skill/program-freeze-and-pause.md` |
| Oracle skew causing liquidations/rewards | P0/P1 | Pause affected markets or rewards; preserve price evidence | `skill/anomaly-detection.md` |
| Failed probes into one instruction | P1 | Preserve sigs and identify entry point | `agents/forensic-investigator.md` |
| Frontend tx mismatch | P1 | Disable UI and notify UX | `skill/crisis-communication.md` |
| RPC outage only, no loss | P2/P3 | Monitor; do not declare exploit yet | `skill/anomaly-detection.md` |

---
## Sends to Token Launch
Send to `solana-token-launch-skill` when token, TGE, mint, liquidity, vesting, claim, or treasury integrity is at risk.
Send `INC_TOKEN_CONTRACT_COMPROMISED` when:
- SPL or Token-2022 mint authority is compromised.
- Freeze authority is missing, compromised, or unexpectedly changed.
- Unauthorized minting, burning, or supply inflation occurs.
- Launch pool, bonding curve, vesting escrow, airdrop, or claim distributor is exploited.
- Liquidity is manipulated during TGE or early trading.
- Treasury movement suggests a rugpull attempt.
```text
SIGNAL: INC_TOKEN_CONTRACT_COMPROMISED
TARGET_SKILL: solana-token-launch-skill
LOAD: TGE safety rules / launch authority safety / liquidity controls
MINT: [mint address]
PROGRAM_ID: [program id]
AUTHORITY_AT_RISK: [mint / freeze / upgrade / treasury / vesting / distributor]
FIRST_BAD_SIGNATURE: [signature]
RECOMMENDED_ACTION: [pause mint / freeze accounts / halt claim / notify exchanges / delay TGE]
```
Incident Response keeps severity, evidence, public incident status, and exchange/legal coordination during active exploitation.
Token Launch owns TGE delay, tokenomics impact, vesting/claim/liquidity relaunch, and authority migration to Squads v4 after handoff.

---
## Sends to UX
Send to `solana-ux-skill` when user interaction must become safer immediately.
Send `INC_FRONTEND_COMPROMISED` when:
- DNS, CDN, package, script, wallet adapter, or deployment pipeline is compromised.
- Frontend constructs a transaction different from what the UI displays.
- Wallet-drain signature patterns appear in telemetry.
- Fake claim, refund, migration, support, or phishing links are spreading.
- Users need high-friction warnings before interacting with affected accounts.
```text
SIGNAL: INC_FRONTEND_COMPROMISED
TARGET_SKILL: solana-ux-skill
LOAD: wallet-ux.md drain prevention
DOMAIN: [domain]
AFFECTED_FLOWS: [connect / claim / swap / stake / bridge / governance]
SAFE_MODE: [read-only / disable all txs / disable affected txs]
USER_MESSAGE: [approved warning]
NEXT_UPDATE_UTC: [time]
```
UX should implement connect-wallet disable, transaction delta preview, official-link-only banner, fake-support warning, and status states: `investigating`, `paused`, `degraded`, `resolved`.

---
## Sends to DePIN
Send to `solana-depin-builder-skill` when the incident involves physical nodes, proof generation, oracle feeds, device identity, coverage maps, or reward manipulation.
Send `INC_ORACLE_EXPLOIT` when:
- Reward oracle reports impossible coverage, location, bandwidth, uptime, energy, or sensor data.
- Fake nodes submit valid-looking proofs and earn rewards.
- Oracle signer, aggregator, or publisher key is compromised.
- Node registry accepts spoofed identity or sybil clusters.
- Rewards are minted from manipulated physical-world measurements.
```text
SIGNAL: INC_ORACLE_EXPLOIT
TARGET_SKILL: solana-depin-builder-skill
LOAD: oracle-integration.md
PROGRAM_ID: [program id]
ORACLE_ACCOUNT: [oracle account]
NODE_IDS: [node pubkeys / device IDs]
EVIDENCE_SLOTS: [start slot - end slot]
EXPLOIT_CLASS: [oracle manipulation / fake node / proof spoofing / sybil reward extraction]
RECOMMENDED_ACTION: [quarantine oracle / pause rewards / reject proofs / raise verification threshold]
```
DePIN owns oracle quorum hardening, proof-of-physical-work validation, node quarantine/slashing, reward epoch recalculation, and coverage verification redesign.

---
## Sends to Observability
Send to `Solana-observabilty-skill` after containment or once a new attack pattern is known.
Send `INC_POST_INCIDENT_MONITORING` when the first malicious instruction discriminator, attacker cluster, vulnerable account pattern, or re-entry condition is identified.
```text
SIGNAL: INC_POST_INCIDENT_MONITORING
TARGET_SKILL: Solana-observabilty-skill
PROGRAM_ID: [program id]
MONITOR_TARGETS: [program, vaults, mints, PDAs, oracle accounts, attacker wallets]
PATTERN: [instruction discriminator / account meta shape / balance delta / oracle deviation]
ALERT_THRESHOLD: [first hit / N txs per slot / value delta / supply delta]
RETENTION: [30d / 90d / permanent]
```

---
## Post-Incident Feedback Loop
Every `/post-mortem-template` must create one hardening action for each other skill.
| Recipient skill | Mandatory hardening action |
|---|---|
| `Solana-observabilty-skill` | Add one alert or dashboard for the exact attack vector. |
| `solana-token-launch-skill` | Add one token authority, TGE, liquidity, vesting, or claim safety improvement. |
| `solana-ux-skill` | Add one user-facing safety pattern reducing future loss or confusion. |
| `solana-depin-builder-skill` | Add one oracle, proof, node, or reward hardening action; if irrelevant, mark `not applicable` with reason. |
```text
POST_INCIDENT_ACTION
RECIPIENT_SKILL: [skill name]
SOURCE_INCIDENT: [incident id]
ROOT_CAUSE: [classification]
ACTION: [specific hardening task]
OWNER: [role]
DEADLINE: [date]
VERIFICATION: [test / dashboard / runbook / audit / tx signature]
```

---
## Cross-Skill Queries
Ask Observability:
```text
For [PROGRAM_ID], return Helius Enhanced Transactions, failed signatures, balance deltas, and oracle deviations for slots [START]-[END]. Highlight first occurrence of [PATTERN].
```
Ask Token Launch:
```text
For mint [MINT], list mint authority, freeze authority, launch pool authority, vesting escrow authority, claim distributor authority, Squads v4 threshold, and whether TGE safety mode is active.
```
Ask UX:
```text
For domain [DOMAIN], produce emergency safe-mode UX: disable affected flows, add official-link warning, show expected balance deltas, and route users to [STATUS_URL].
```
Ask DePIN:
```text
For node/oracle set [IDS], verify proof validity, stake status, reward epoch, oracle publisher, and whether coverage-verification.md or oracle-integration.md should be loaded.
```

---
## Shared Vocabulary
- **Epoch:** Slot-bounded accounting or reward period for launch eligibility, DePIN rewards, monitoring windows, and incident timelines.
- **Proof:** Evidence supporting a claim: tx signatures, account snapshots, oracle attestations, or DePIN node proofs.
- **Stake:** Locked economic value securing behavior: validator, DePIN node, governance, or launch lockup stake.
- **Oracle:** Data publisher or aggregation path feeding prices, coverage, rewards, routing, or physical-world measurements.
- **Node:** Validator, RPC node, DePIN device, gateway, oracle publisher, or monitoring endpoint; always specify type.
- **Commitment:** Solana finality level (`processed`, `confirmed`, `finalized`) used for evidence confidence and containment verification.
- **Authority:** Key, PDA, Squads multisig, or governance process allowed to mutate program, mint, vault, treasury, oracle, or UI state.
- **Slot:** Primary Solana ordering unit for forensic timelines; never rely on wall-clock time alone.
- **Program ID:** Deployed executable account; pair with program-data account for upgradeable programs.
- **PDA:** Program-derived account whose seeds and authority constraints must be validated during forensics.

---
## Collaboration Rules
1. Observability alerts do not prove an exploit; they trigger `/incident-triage`.
2. Incident Response owns severity until containment is declared.
3. UX must not publish claim, refund, migration, or recovery links during an active exploit unless Incident Commander and Legal approve.
4. Token Launch must not resume TGE, claims, vesting, or liquidity incentives until Incident Response clears token integrity.
5. DePIN reward epochs affected by oracle or fake-node incidents must be frozen until proof validity is reviewed.
6. Every handoff must include program ID, slot range, signatures, affected accounts, requested action, and next decision deadline.
7. Every post-mortem must create at least one monitoring hardening action.
