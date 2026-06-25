# /incident-triage

Systematic triage protocol for Solana incidents. Produces a deterministic classification and
activation plan in under 3 minutes. Run this command first — before loading any other skill.

> **Prime directive:** evidence preservation before containment; containment before communication;
> communication before recovery. Never skip ahead.

---

## Usage

```text
Run /incident-triage
```

Ask all 5 questions simultaneously. Do not wait for answers between questions.
If a question cannot be answered, record **Unknown** — never skip or assume.
Total decision time target: **≤ 3 minutes from first report to output block**.

---

## The 5 Questions (Ask All At Once)

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SOLANA INCIDENT TRIAGE — ANSWER ALL 5 BEFORE PROCEEDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Q1) CONFIRMATION STATUS (pick one)
    [ ] A — Confirmed    On-chain evidence: unauthorized state change or measurable loss
    [ ] B — Suspected    Anomalous txs flagged; loss not yet verified on-chain
    [ ] C — Unclear      Report received but zero on-chain verification done

Q2) SCOPE (pick one)
    [ ] 1 — Under $10K
    [ ] 2 — $10K – $100K
    [ ] 3 — $100K – $1M
    [ ] 4 — Over $1M
    [ ] 5 — Unknown / still assessing

Q3) ATTACK STATUS (pick one)
    [ ] X — Ongoing     Attacker-controlled transactions still appearing in mempool / recent slots
    [ ] Y — Stopped     Last attacker tx > 10 minutes ago; no active drain visible
    [ ] Z — Unknown

Q4) CONTROL SURFACE (check ALL that apply)
    [ ] Program exposes a pause/freeze instruction callable by authority
    [ ] Upgrade authority is a single keypair — holder reachable within 10 min
    [ ] Upgrade authority is Squads v4 multisig
        Threshold: ___ of ___     Signers reachable in 10 min: ___
    [ ] Mint freeze authority exists (SPL Token or Token-2022)
    [ ] Program is immutable — no upgrade authority set
    [ ] None of the above / unsure

Q5) SIGNAL / ATTACK TYPE (pick the closest match — one primary)
    [ ] 1 — Fund drain from program vaults
             (Cashio Mar 2022 $48M style: direct unauthorized vault withdrawal,
              account substitution, missing signer checks)
    [ ] 2 — Unauthorized mint / supply inflation
             (Cashio infinite mint: ghost collateral accepted, new tokens minted,
              treasury drained via redemption)
    [ ] 3 — Oracle manipulation / economic attack
             (Mango Markets Oct 2022 $115M: price oracle pumped, collateral
              inflated, governance treasury borrowed to insolvency)
    [ ] 4 — Governance or admin takeover
             (SPL Governance malicious proposal fast-passed; Squads v4 signer
              set modified; program upgrade authority transferred without approval)
    [ ] 5 — Frontend / infrastructure compromise
             (UI served malicious transaction; API key leaked to drain hot wallet;
              RPC endpoint poisoned; DNS hijack redirecting dApp traffic)
    [ ] 6 — CPI / reentrancy exploit
             (Cross-program invocation abuses invoke ordering or shared account
              state; Anchor missing account constraint; CPI call mutates account
              mid-instruction before balance check; analogous to Crema Finance
              Jul 2022 $8.8M flash-loan tick account abuse)
    [ ] 7 — Token-2022 extension exploit
             (Transfer fee percentage manipulated via fee authority; permanent
              delegate drains holder balances; confidential transfer state
              corrupted; interest-bearing mint rate spiked; CPI guard bypassed)
    [ ] 8 — Bridge / cross-chain exploit
             (Wormhole Feb 2022 $320M: guardian signature validation bypassed,
              VAA forged; Solana-side mint of bridged asset without corresponding
              lock on source chain; relay relayer key compromised)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Severity Classification Matrix (P0–P3)

Three dimensions: confirmation status × attack status × scope. Fourth column maps each row to a
canonical Solana real-world incident for calibration.

| Confirmed? | Ongoing? | Scope      | Severity            | Solana Real-World Analog |
|------------|----------|------------|---------------------|--------------------------|
| Yes        | Yes      | Any        | **P0 — Critical**   | Wormhole Feb 2022 ($320M active bridge drain); Cashio Mar 2022 ($48M vault drain in progress) |
| Yes        | No       | ≥ $1M      | **P0 — Critical**   | Mango Markets Oct 2022 ($115M, oracle manipulation complete but funds still in protocol) |
| Yes        | No       | $100K–$1M  | **P1 — High**       | Crema Finance Jul 2022 ($8.8M stopped, flash loan repaid but protocol state corrupted) |
| Yes        | No       | < $100K    | **P1 — High**       | Isolated pool drain; upgrade authority theft without large fund exposure |
| Suspected  | Yes      | Any        | **P1 — High**       | Anomalous liquidation cascade resembling Mango-style oracle attack, not yet confirmed |
| Suspected  | No       | ≥ $100K    | **P1 — High**       | Unusual mint event flagged by Helius webhook; supply inflation unconfirmed |
| Suspected  | No       | < $100K    | **P2 — Medium**     | Single anomalous vault withdrawal; may be authorized; requires investigation |
| Unclear    | Yes      | Any        | **P1 — High**       | Multiple user reports of fund loss with active tx activity; treat as real until proven otherwise |
| Unclear    | No       | Any        | **P2 — Medium**     | Single report; no corroborating on-chain signal; validate first |
| Any        | Any      | Any        | **P3 — Low**        | False positive confirmed; no on-chain impact; log and improve alert thresholds |

> **P0 override:** Any Rapid Risk Score ≥ 70 (see next section) forces P0 regardless of the matrix
> above.

---

## Rapid Risk Score (0–100)

Compute this score immediately after answering Q1–Q4. Each condition is binary (met = full points,
not met = zero). **Score ≥ 70 triggers automatic P0 override.**

```text
┌─────────────────────────────────────────────────────────────┐
│  RAPID RISK SCORE WORKSHEET                                 │
├──────────────────────────────────────────────┬──────────────┤
│  Condition                                   │  Points      │
├──────────────────────────────────────────────┼──────────────┤
│  Q1 = Confirmed (on-chain evidence of loss)  │  +30         │
│  Q3 = Ongoing (attacker still active)        │  +25         │
│  Q2 = Scope > $1M (or Unknown)               │  +20         │
│  Q4 = No pause available (no freeze instr,   │              │
│       program immutable, single key MIA)     │  +15         │
│  Squads multisig — < threshold signers       │              │
│       reachable within 10 min                │  +10         │
├──────────────────────────────────────────────┼──────────────┤
│  TOTAL (max 100)                             │  ___         │
└──────────────────────────────────────────────┴──────────────┘

Score interpretation:
  ≥ 70  → P0 override. Activate full war room NOW.
  50–69 → P1. Escalate immediately; reassess every 15 min.
  30–49 → P2. Structured investigation; dedicated analyst assigned.
  < 30  → P2/P3. Monitor; re-triage if any new signal.
```

---

## Time-Based Urgency Modifier (Delayed Triage Flag)

Ask immediately after Q3: **"How long ago did the first anomalous signal appear?"**

```text
  [ ] < 30 minutes   — Normal triage cadence applies
  [ ] 30 min – 2 h   — Add CAUTION note; request mempool/slot gap analysis
  [ ] > 2 hours      — Set DELAYED_TRIAGE = true
```

If **DELAYED_TRIAGE = true**, the following modifications apply to the output:

1. **Immediate Actions list is prepended with:**
   `[ ] 0) Run Helius Enhanced Transactions API for the full slot range since first anomaly.
         Endpoint: GET /v0/addresses/{attacker_address}/transactions?limit=100
         Purpose: reconstruct complete attack timeline before any further state changes.`

2. **Evidence window warning is added to comms-director handoff:**
   `"Delayed triage: ≥2h elapsed. Assume on-chain state has changed significantly since
   attack onset. Do NOT publish timeline claims until forensic-investigator confirms slot range."`

3. **Severity floor is raised one level** (P2 → P1 minimum) if scope is Unknown, because extended
   attack duration without detection implies monitoring failure that warrants elevated response.

---

## Secondary Vector Checklist

After classifying the primary attack type from Q5, ask these four secondary questions.
A compound attack (primary + secondary vector) automatically adds **+10 to Rapid Risk Score**
and adds `agents/upgrade-commander.md` to the activation list.

```text
SECONDARY VECTOR CHECK — answer all four:

  [ ] A) UPGRADE AUTHORITY COMPROMISE
         Is there any evidence the program upgrade authority was changed,
         a malicious buffer was deployed, or an unexpected upgrade was committed
         in the same or adjacent slots as the primary exploit?
         → If yes: load skill/program-upgrade-safety.md immediately (parallel to primary).

  [ ] B) ORACLE ACCOUNT COMPROMISE
         Was a Pyth price account or Switchboard feed account written to by an
         unauthorized signer within 30 slots of the exploit?
         Check: solana account <oracle_pubkey> --url mainnet-beta
         → If yes: load skill/anomaly-detection.md; flag all downstream protocols.

  [ ] C) GOVERNANCE COMPROMISE
         Was an SPL Governance proposal created, voted on, or executed in the
         24h window surrounding the primary exploit?
         Check Squads v4: squads multisig show <multisig_pubkey>
         → If yes: load skill/legal-regulatory-response.md; freeze governance execution.

  [ ] D) FRONTEND COMPROMISE
         Are users reporting unexpected transaction approval prompts, wallet drain
         after visiting the dApp, or a change in the dApp's transaction simulation
         output vs. actual on-chain effect?
         → If yes: immediately rotate Vercel/Cloudflare API keys; load skill/crisis-communication.md.
```

If **two or more** secondary vectors are confirmed: escalate severity to P0 regardless of matrix
or Rapid Risk Score. Record compound attack type in the output block.

---

## Incident Type Classification (Q5 → Canonical Type)

| Q5 Selection | Canonical Incident Type              | Primary Skill Chain |
|:---:|--------------------------------------|---------------------|
| 1 | Vault drain / account validation failure | `active-exploit-response.md` → `program-freeze-and-pause.md` → `freeze-checklist.md` |
| 2 | Unauthorized mint / supply inflation | `program-freeze-and-pause.md` → `freeze-checklist.md` → `anomaly-detection.md` |
| 3 | Oracle manipulation / economic exploit | `active-exploit-response.md` → `anomaly-detection.md` → `liquidity-migration.md` |
| 4 | Governance / admin takeover | `legal-regulatory-response.md` → `program-upgrade-safety.md` → `program-freeze-and-pause.md` |
| 5 | Frontend / infrastructure compromise | `crisis-communication.md` → `active-exploit-response.md` (if funds at risk) |
| 6 | CPI / reentrancy exploit | `active-exploit-response.md` → `program-freeze-and-pause.md` → `program-upgrade-safety.md` |
| 7 | Token-2022 extension exploit | `program-freeze-and-pause.md` → `anomaly-detection.md` → `active-exploit-response.md` |
| 8 | Bridge / cross-chain exploit | `active-exploit-response.md` → `legal-regulatory-response.md` → `liquidity-migration.md` |

---

## Agent Activation and Handoff Messages

### Always activate for P0 and P1:

#### `agents/incident-commander.md`

```text
HANDOFF — INCIDENT COMMANDER

Incident triage complete. You are now the single decision authority.
Severity: [SEVERITY]. Rapid Risk Score: [SCORE]/100.
Type: [CANONICAL TYPE]. Delayed triage: [YES/NO].
Secondary vectors confirmed: [LIST or NONE].

Your first three actions:
1) Acknowledge this handoff and open the incident log (timestamp: UTC now).
2) Confirm Rapid Risk Score and validate severity classification.
3) Issue go/no-go for containment execution within 5 minutes.

You own all escalation and de-escalation decisions. Comms-director
publishes NOTHING without your explicit approval token.
```

#### `agents/forensic-investigator.md`

```text
HANDOFF — FORENSIC INVESTIGATOR

Preserve evidence before any state changes. Do not freeze or upgrade
the program until you have captured the following:

1) All transactions to/from [AFFECTED_PROGRAM_ADDRESS] in the exploit
   window using Helius Enhanced Transactions:
   GET https://api.helius.xyz/v0/addresses/{address}/transactions?limit=100&api-key={KEY}

2) Account state snapshots:
   solana account [AFFECTED_ACCOUNT] --url mainnet-beta --output json

3) Anchor event logs if program uses emit!():
   solana logs --url mainnet-beta | grep [PROGRAM_ID]

4) If bridge exploit (Q5=8): capture VAA bytes from Wormhole guardian network
   before any guardian set rotation.

Type: [CANONICAL TYPE]. Delayed triage: [YES/NO — if YES, extend slot lookback by 2h minimum].
Report timeline to incident-commander within 15 minutes.
```

#### `agents/comms-director.md`

```text
HANDOFF — COMMS DIRECTOR

Do NOT publish anything until incident-commander issues approval token.

Prepare (do not send) the following:
1) Internal war-room notice: [draft-incident-notice.md template]
2) Public holding statement (< 280 chars): "We are aware of a potential issue
   and are investigating. Funds/operations status: [SAFE/AT RISK/UNKNOWN].
   Updates to follow at [STATUS_PAGE_URL]."
3) User action advisory if frontend compromise confirmed (Q5=5 or secondary D):
   "Do not connect your wallet to [DAPP_URL] until further notice."

Delayed triage flag: [YES/NO]. If YES, do not speculate on attack timeline.
Severity: [SEVERITY]. Await IC approval before any external communication.
```

### Activate when attack is stopped or scope is contained:

#### `agents/recovery-engineer.md`

```text
HANDOFF — RECOVERY ENGINEER

Containment confirmed by incident-commander. Begin recovery phase.

Your scope:
1) Load skill/hardened-redeployment.md — do not redeploy until forensic
   root cause is documented and IC signs off.
2) Load skill/liquidity-migration.md if user funds need migration to safe
   vault during investigation window.
3) Load skill/post-mortem-analysis.md — begin collecting data for post-mortem
   immediately; do not wait for full recovery.

Compensation and accounting are secondary to stability. Confirm with IC
before communicating any compensation commitments externally.
```

### Activate only for governance/admin takeover (Q5=4) or secondary vector C:

#### `agents/upgrade-commander.md`

```text
HANDOFF — UPGRADE COMMANDER

Governance or authority compromise detected.

Immediate checks:
1) squads multisig show <MULTISIG_PUBKEY> — confirm current signer set.
2) solana program show <PROGRAM_ID> — confirm upgrade authority pubkey.
3) solana program show <PROGRAM_ID> --buffers — list any deployed buffers.

If upgrade authority has already been transferred to an unknown key:
→ Treat as P0 regardless of current severity.
→ Load skill/program-upgrade-safety.md NOW.
→ Do not attempt on-chain reclaim without IC authorization.

Type: [CANONICAL TYPE]. Multisig threshold: [X of Y]. Signers reachable: [N].
```

---

## Immediate Actions Reference (By Severity)

### P0 — Critical (first 30 minutes)

```text
[ ] 0) IF DELAYED_TRIAGE = true: run Helius slot-range query first (see above).
[ ] 1) Activate agents/incident-commander.md — single decision thread, no exceptions.
[ ] 2) Activate agents/forensic-investigator.md — evidence snapshot before any freeze.
[ ] 3) Execute containment path from skill/program-freeze-and-pause.md.
        Use commands/freeze-checklist.md as the step-by-step execution guide.
[ ] 4) Activate agents/comms-director.md — prepare drafts; no publish without IC token.
[ ] 5) If funds movable safely: run skill/liquidity-migration.md in parallel with freeze.
[ ] 6) If governance vector confirmed: activate agents/upgrade-commander.md immediately.
[ ] 7) When contained: activate agents/recovery-engineer.md.
```

### P1 — High (first 45 minutes)

```text
[ ] 1) Activate agents/incident-commander.md + agents/forensic-investigator.md.
[ ] 2) Determine if attack is truly stopped — re-run Q3 with live mempool check.
        solana-cli: solana transaction-history <attacker_address> --limit 20
[ ] 3) If ongoing confirmed during P1: re-triage → escalate to P0 immediately.
[ ] 4) Prepare comms drafts (no publish). Load primary skill chain from type table.
[ ] 5) Set reassessment alarm: 15 minutes. Re-score Rapid Risk Score.
```

### P2 — Medium (first 2 hours)

```text
[ ] 1) Assign one analyst. Load skill/anomaly-detection.md.
[ ] 2) Validate anomaly: confirm or deny on-chain loss.
        If confirmed: re-triage → P1 minimum.
[ ] 3) Monitor attacker address with Helius webhook:
        POST https://api.helius.xyz/v0/webhooks — type: "enhanced", address: [SUSPECT]
[ ] 4) Document findings in incident log. No comms needed unless user-visible.
```

### P3 — Low (next business cycle)

```text
[ ] 1) Log full investigation notes.
[ ] 2) Improve alert thresholds to catch this signal earlier.
[ ] 3) Consider adding test coverage for the near-miss scenario.
```

---

## Files To Load By Incident Type (Quick Reference)

| Type | Load First | Load Second | Load Third |
|------|-----------|-------------|------------|
| Vault drain (1) | `skill/active-exploit-response.md` | `skill/program-freeze-and-pause.md` | `commands/freeze-checklist.md` |
| Unauthorized mint (2) | `skill/program-freeze-and-pause.md` | `commands/freeze-checklist.md` | `skill/anomaly-detection.md` |
| Oracle/economic (3) | `skill/active-exploit-response.md` | `skill/anomaly-detection.md` | `skill/liquidity-migration.md` |
| Governance (4) | `skill/legal-regulatory-response.md` | `skill/program-upgrade-safety.md` | `skill/program-freeze-and-pause.md` |
| Frontend/infra (5) | `skill/crisis-communication.md` | `skill/active-exploit-response.md` | — |
| CPI/reentrancy (6) | `skill/active-exploit-response.md` | `skill/program-freeze-and-pause.md` | `skill/program-upgrade-safety.md` |
| Token-2022 (7) | `skill/program-freeze-and-pause.md` | `skill/anomaly-detection.md` | `skill/active-exploit-response.md` |
| Bridge (8) | `skill/active-exploit-response.md` | `skill/legal-regulatory-response.md` | `skill/liquidity-migration.md` |
| Secondary: upgrade authority | `skill/program-upgrade-safety.md` | + primary chain | — |
| Secondary: oracle | `skill/anomaly-detection.md` | + primary chain | — |
| Secondary: governance | `skill/legal-regulatory-response.md` | + primary chain | — |
| Secondary: frontend | `skill/crisis-communication.md` | + primary chain | — |

---

## Output Format (Exact Structure Required)

The agent executing `/incident-triage` **must** return exactly this block — no prose before it,
no commentary after it until the block is complete.

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 TRIAGE OUTPUT — [UTC TIMESTAMP]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SEVERITY:          [P0 / P1 / P2 / P3]  [OVERRIDE REASON if P0 via score]
RAPID RISK SCORE:  [0–100]  (Confirmed:[Y/N] +Ongoing:[Y/N] +Scope>$1M:[Y/N]
                             +NoPause:[Y/N] +MultisigMIA:[Y/N])
TYPE:              [canonical incident type from classification table]
DELAYED TRIAGE:    [YES — Xh elapsed since first signal / NO]

SECONDARY VECTORS:
  Upgrade authority compromised:  [YES / NO / UNKNOWN]
  Oracle account compromised:     [YES / NO / UNKNOWN]
  Governance compromised:         [YES / NO / UNKNOWN]
  Frontend compromised:           [YES / NO / UNKNOWN]
  Compound attack:                [YES — score +10 applied / NO]

IMMEDIATE ACTIONS:
  1) [action — be specific: tool, command, or agent to invoke]
  2) [action]
  3) [action]

AGENTS TO ACTIVATE:
  - agents/incident-commander.md        [ALWAYS for P0/P1]
  - agents/forensic-investigator.md     [ALWAYS for P0/P1]
  - agents/comms-director.md            [ALWAYS for P0/P1]
  - agents/recovery-engineer.md         [when contained]
  - agents/upgrade-commander.md         [if Q5=4 or secondary C confirmed]

FILES TO LOAD NOW:
  - skill/[primary].md
  - skill/[secondary].md
  - commands/[checklist].md

FIRST MESSAGE FOR INCIDENT COMMANDER:
  "Severity [P0/P1/P2/P3]. Risk score [N]/100. Type: [TYPE].
   [DELAYED_TRIAGE warning if applicable.]
   [COMPOUND ATTACK warning if applicable.]
   Awaiting your go/no-go for containment. Forensic investigator
   is preserving evidence. Comms drafts are ready, not published.
   Next checkpoint: [UTC + 15 min]."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Decision Flow Summary

```
Q1–Q5 answered?
    │
    ▼
Compute Rapid Risk Score ──── ≥70? ──────────────────────► P0 override
    │                                                           │
    ▼                                                           │
Severity matrix lookup ◄────────────────────────────────────────
    │
    ▼
DELAYED_TRIAGE check (>2h?) ──── YES? ──► prepend action 0, raise floor
    │
    ▼
Secondary vector check (A–D)
    │
    ├── 2+ confirmed? ──────────────────────────────────────► P0 override
    │
    ▼
Incident type → skill chain → agent activation → handoff messages
    │
    ▼
Emit structured output block
    │
    ▼
Incident commander acknowledged? ──── NO? ──► escalate via backup contact
    │
    YES
    ▼
First checkpoint at T+15 min (re-score, re-triage if status changed)
```

---

## Notes on Recurring Failure Modes

- **Missing the compound attack:** Cashio ($48M) involved both a vault drain *and* a mint
  inflation vector simultaneously. Always run the full secondary vector checklist even when the
  primary type is obvious.
- **Trusting "stopped" status too early:** Mango Markets ($115M) appeared stopped after the
  initial oracle pump; the treasury drain happened in a subsequent transaction sequence.
  Re-run Q3 live — do not rely on the reporter's initial assessment.
- **Delayed triage without timeline reconstruction:** Wormhole ($320M) had a post-exploit window
  where guardian key material was at risk. If DELAYED_TRIAGE is true, the forensic slot-range
  query is non-optional.
- **Publishing comms before IC approval:** comms-director holds all drafts. The IC issues a
  single approval token. No exceptions regardless of community pressure.
- **Token-2022 exploits are under-monitored:** permanent delegate and transfer fee authority are
  often held by a single key not in the Squads multisig. Verify Q4 includes these authorities.
