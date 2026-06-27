# /incident-triage

Systematic triage protocol for Solana incidents. Run this command first — before loading other skills.

> Prime directive: preserve evidence before containment; contain before communication; communicate before recovery.

---

## Usage

```text
Run /incident-triage
```

Ask all 5 questions at once. If a question cannot be answered, record **Unknown**.
Total decision time target: **≤ 3 minutes from first report to output block**.

---

## The 5 Questions

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SOLANA INCIDENT TRIAGE — ANSWER ALL 5 BEFORE PROCEEDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Q1) CONFIRMATION STATUS
    [ ] A — Confirmed    On-chain evidence: unauthorized state change or loss
    [ ] B — Suspected    Anomalous txs flagged; loss not yet verified on-chain
    [ ] C — Unclear      Report received but no verification yet

Q2) SCOPE
    [ ] 1 — Under $10K
    [ ] 2 — $10K – $100K
    [ ] 3 — $100K – $1M
    [ ] 4 — Over $1M
    [ ] 5 — Unknown / still assessing

Q3) ATTACK STATUS
    [ ] X — Ongoing     Attacker txs still appearing
    [ ] Y — Stopped     Last attacker tx > 10 minutes ago; no active drain visible
    [ ] Z — Unknown

Q4) CONTROL SURFACE (check ALL that apply)
    [ ] Program exposes emergency pause / freeze instruction
    [ ] Upgrade authority is a single keypair reachable within 10 min
    [ ] Upgrade authority is Squads v4 multisig
          Threshold: ___ of ___    Reachable signers: ___
    [ ] Mint freeze authority exists (SPL / Token-2022)
    [ ] Program is immutable / no upgrade authority
    [ ] None of the above / unsure

Q5) SIGNAL / ATTACK TYPE
    [ ] 1 — Fund drain from vaults (Cashio-style)
    [ ] 2 — Unauthorized mint / supply inflation
    [ ] 3 — Oracle manipulation / economic attack (Mango-style)
    [ ] 4 — Governance or admin takeover
    [ ] 5 — Frontend / infrastructure compromise
    [ ] 6 — CPI / reentrancy-equivalent exploit
    [ ] 7 — Token-2022 extension exploit
    [ ] 8 — Bridge / cross-chain exploit (Wormhole-style)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Severity Classification Matrix

| Confirmed? | Ongoing? | Scope | Severity | Real-world analog |
|---|---|---|---|---|
| Yes | Yes | Any | **P0** | Wormhole active drain; Cashio live vault drain |
| Yes | No | ≥ $1M | **P0** | Mango oracle loss after state change |
| Yes | No | $100K–$1M | **P1** | Crema Finance stopped exploit |
| Yes | No | < $100K | **P1** | Small vault drain contained |
| Suspected | Yes | Any | **P1** | high-confidence exploit in progress |
| Suspected | No | ≥ $100K | **P1** | significant anomaly requiring rapid response |
| Suspected | No | < $100K | **P2** | local anomaly; may be false positive |
| Unclear | Yes | Any | **P1** | unknown active behavior warrants escalation |
| Unclear | No | Any | **P2** | monitor, investigate |
| Any | Any | N/A | **P3** | no loss confirmed |

> **P0 override:** Rapid Risk Score ≥ 70.

---

## Rapid Risk Score

Compute immediately.

```text
Condition                                               Points
Confirmed on-chain loss or unauthorized state change   +30
Ongoing attacker activity                               +25
Scope ≥ $1M or unknown                                  +20
No pause/freeze available / immutable program           +15
Squads signers unreachable in 10 min                    +10
```

Interpretation:
- ≥ 70 → P0 override
- 50–69 → P1
- 30–49 → P2
- < 30 → P2/P3

---

## Time-Based Urgency Modifier

Ask: **How long ago did the first anomalous signal appear?**

- [ ] < 30 min — normal cadence
- [ ] 30 min – 2 h — caution note, request slot gap analysis
- [ ] > 2 h — DELAYED_TRIAGE = true

If delayed:
1. Add an immediate evidence preservation step for Helius slot range export.
2. Raise severity floor by one level if scope is Unknown.
3. Warn comms: “Do not publish timeline claims until forensics confirms slots.”

---

## Secondary Vector Checklist

If any secondary vector is confirmed, add +10 risk score and load `agents/upgrade-commander.md`.

```text
[ ] UPGRADE AUTHORITY COMPROMISE
      Evidence of unexpected BPFLoaderUpgradeable or upgrade tx near the exploit.
[ ] ORACLE ACCOUNT COMPROMISE
      Pyth/Switchboard account written by unauthorized signer within 30 slots.
[ ] GOVERNANCE COMPROMISE
      SPL Governance or Squads proposal executed in the 24h window.
[ ] FRONTEND COMPROMISE
      Malicious UI, wallet connect prompt mismatch, or API key leak.
```

If two or more are confirmed, escalate to P0.

---

## Canonical Incident Types

| Q5 | Canonical type | Primary skill chain |
|---|---|---|
| 1 | Vault drain / account validation failure | active-exploit-response → program-freeze-and-pause → freeze-checklist |
| 2 | Unauthorized mint / inflation | program-freeze-and-pause → freeze-checklist → anomaly-detection |
| 3 | Oracle manipulation / economic exploit | active-exploit-response → anomaly-detection → liquidity-migration |
| 4 | Governance / admin takeover | legal-regulatory-response → program-upgrade-safety → program-freeze-and-pause |
| 5 | Frontend / infrastructure compromise | crisis-communication → active-exploit-response |
| 6 | CPI / reentrancy-equivalent exploit | active-exploit-response → program-freeze-and-pause → program-upgrade-safety |
| 7 | Token-2022 extension exploit | program-freeze-and-pause → anomaly-detection → active-exploit-response |
| 8 | Bridge / cross-chain exploit | active-exploit-response → legal-regulatory-response → liquidity-migration |

---

## Agent Activation Summary

Always activate for P0 and P1:
- `agents/incident-commander.md`
- `agents/forensic-investigator.md`
- `agents/comms-director.md`
- `agents/recovery-engineer.md` if containment is achieved

### Handoff to Incident Commander

```text
HANDOFF — INCIDENT COMMANDER
Severity: [P0/P1/P2/P3]
Type: [canonical type]
Risk score: [score]/100
Paused? [yes/no/unknown]
Evidence captured: [yes/no/pending]
Primary attack vector: [list]
```

---

## Immediate Actions

1. Preserve evidence before mitigation.
2. Confirm authority and control paths.
3. Execute the fastest containment available.
4. Start the incident log.
5. Route communications through Comms Director.

---

## Output Format

Use this as the final triage block.

```text
INCIDENT STATUS: [P0/P1/P2/P3]
PRIMARY TYPE: [vault drain / mint / oracle / governance / CPI]
RISK SCORE: [score]/100
FUND MOVEMENT: [yes/no/unknown]
PAUSE PATH: [pause / upgrade / none / unknown]
NEXT ACTIONS:
  - [action 1]
  - [action 2]
  - [action 3]
```
