# /incident-readiness-drill

Pre-incident readiness drill for Solana protocol teams. Run monthly, before TGE, before major upgrades, and after any security-relevant architecture change.

> Goal: prove the team can detect, decide, pause, communicate, preserve evidence, and recover without improvising.

---

## Usage

```text
Run /incident-readiness-drill
```

Ask for the protocol name, program IDs, upgrade authority setup, emergency contacts, monitoring provider, and whether this is a tabletop or live dry run.

---

## Drill Modes

| Mode | Use when | Allowed actions |
|---|---|---|
| Tabletop | First drill or new team | Discussion only; no transactions |
| Simulation | Mature team | Devnet/localnet txs, mock alerts, fake comms |
| Production dry run | Pre-launch or quarterly | Read-only mainnet checks, unsigned Squads proposals, no state changes |
| Full fire drill | High-risk protocols | Pre-approved safe transaction on devnet or controlled canary program |

Never execute mainnet pause, upgrade, mint freeze, or treasury movement during a drill unless explicitly planned, announced internally, and approved by governance/multisig policy.

---

## Readiness Intake

```text
1) Program IDs and critical mints:
2) Upgrade authority: [single key / Squads v4 / SPL Governance / immutable]
3) Pause authority and instruction:
4) Treasury / vault authority:
5) Monitoring provider: [Helius / QuickNode / Triton / custom]
6) Frontend kill switch owner:
7) Exchange / market-maker / partner contacts:
8) Legal counsel contact:
9) Security firm or auditor contact:
10) Status page and official comms channels:
```

If any answer is missing, create a P0 readiness action item.

---

## Drill Scenario Selection

Pick one scenario per drill.

| Scenario | Primary files to load | Success condition |
|---|---|---|
| Active vault drain | `skill/active-exploit-response.md`, `commands/freeze-checklist.md` | P0 declared and pause path identified within 5 min |
| Oracle manipulation | `skill/anomaly-detection.md`, `skill/program-freeze-and-pause.md` | market/reward pause decision documented |
| Upgrade authority compromise | `agents/incident-commander.md`, `skill/program-freeze-and-pause.md` | authority owner and emergency escalation path confirmed |
| Bridge supply mismatch | `skill/bridge-incident-response.md` | supply parity evidence and bridge partner contact package drafted |
| Frontend wallet drain | `agents/comms-director.md`, `ecosystem-signals.md` | UI safe mode and UX handoff drafted |
| Mint authority anomaly | `commands/incident-triage.md`, `skill/legal-regulatory-response.md` | exchange notification package drafted |

---

## Phase 1 — Detection Check

- [ ] Fire or simulate a Helius webhook for the selected scenario.
- [ ] Confirm alert reaches the on-call channel within 2 minutes.
- [ ] Confirm alert includes program ID, slot, signature, account, and severity hint.
- [ ] Confirm on-call can access Helius Enhanced Transactions or equivalent trace data.
- [ ] Confirm Jito/front-running evidence path is known if relevant.
- [ ] Confirm dashboard shows affected vaults, mints, or oracle accounts.

Failure if: alert lacks enough context to run `/incident-triage`.

---

## Phase 2 — Triage Check

- [ ] Run `/incident-triage` using the mock evidence.
- [ ] Classify severity as P0/P1/P2/P3 with a written reason.
- [ ] Identify primary incident type and control path.
- [ ] Assign Incident Commander, Forensic Investigator, Comms Director, and Technical Lead.
- [ ] Start an incident log with UTC timestamps.
- [ ] Set next decision deadline.

Success target: triage output completed in ≤ 5 minutes.

---

## Phase 3 — Authority and Freeze Check

- [ ] Confirm pause instruction name and required accounts from IDL.
- [ ] Confirm upgrade authority and program-data account.
- [ ] Confirm Squads v4 threshold and reachable signers.
- [ ] Draft an unsigned Squads proposal for emergency pause or upgrade authority action.
- [ ] Confirm mint freeze authority for affected SPL/Token-2022 mints.
- [ ] Confirm frontend kill switch can be deployed by the right owner.
- [ ] Confirm automation/keepers can be suspended without disabling observability.

Failure if: no reachable signer quorum or no one knows the pause instruction.

---

## Phase 4 — Evidence Preservation Check

- [ ] Create incident evidence folder using forensic naming convention.
- [ ] Export mock or read-only Helius Enhanced Transactions.
- [ ] Save account snapshots: program, program-data, config PDA, vaults, mints, oracles, Squads state.
- [ ] Record first suspicious signature and slot range.
- [ ] Hash raw evidence files or record immutable storage location.
- [ ] Confirm no one edits raw JSON exports.

Success target: minimum evidence pack assembled in ≤ 10 minutes.

---

## Phase 5 — Communications Check

- [ ] Draft initial holding statement with `commands/draft-incident-notice.md`.
- [ ] Confirm it avoids exploit mechanics, attacker attribution, unverified losses, and restitution promises.
- [ ] Draft Discord/Telegram moderator instructions.
- [ ] Draft exchange partner notice if token or bridge integrity is in scope.
- [ ] Confirm official channels and status page credentials are accessible.
- [ ] Confirm legal review path for public, exchange-private, and white-hat communications.

Failure if: public comms owner or approval chain is unknown.

---

## Phase 6 — Recovery and Handoff Check

- [ ] Identify recovery owner and when `agents/recovery-engineer.md` takes over.
- [ ] Confirm secure recovery treasury address and authority policy.
- [ ] Confirm compensation data source: pre-incident snapshot, indexer, vault accounting, or Merkle distributor.
- [ ] Confirm exchange, analytics, counsel, and insurer escalation paths.
- [ ] Confirm hardened redeployment gate from `skill/hardened-redeployment.md`.

Success target: every post-containment owner has a named role and backup.

---

## Required Drill Output

```text
READINESS SCORE: [0-100]
MODE: [tabletop / simulation / production dry run / full fire drill]
SCENARIO: [vault drain / oracle / authority / bridge / frontend / mint]
TIME_TO_TRIAGE: [minutes]
TIME_TO_PAUSE_PATH: [minutes]
SIGNER_QUORUM: [ready / partial / failed]
COMMS_APPROVAL_PATH: [ready / partial / failed]
EVIDENCE_PACK: [ready / partial / failed]
TOP 5 GAPS:
  1. [gap + owner + deadline]
  2. [gap + owner + deadline]
  3. [gap + owner + deadline]
  4. [gap + owner + deadline]
  5. [gap + owner + deadline]
NEXT DRILL DATE: [date]
```

---

## Scoring Rubric

| Score | Meaning |
|---:|---|
| 90–100 | Production-ready; only minor improvements |
| 75–89 | Good, but one serious gap remains |
| 60–74 | Operationally risky; drill again after fixes |
| <60 | Not ready for mainnet TVL or TGE |

Automatic score caps:
- no reachable signer quorum → max 70
- no working monitoring alert → max 75
- no pause/freeze path documented → max 65
- no comms approval path → max 80
- no evidence preservation process → max 75
- no legal/security escalation contacts → max 80

---

## Follow-Up Rule

Every drill produces action items with owner, deadline, and verification. A gap is not closed until the team proves it in the next drill or with a signed artifact, dashboard, runbook, or transaction simulation.
