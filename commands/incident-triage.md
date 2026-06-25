# /incident-triage

Systematic triage protocol for Solana incidents. Produces a deterministic classification and activation plan in under 3 minutes.

## Usage

```text
Run /incident-triage
```

This command asks exactly 5 questions, then outputs severity, incident type, immediate actions, agents, and the exact files to load next.

---

## The 5 Questions (Ask All At Once)

```text
1) CONFIRMATION STATUS (pick one)
   [ ] Confirmed — on-chain evidence shows loss or unauthorized state change
   [ ] Suspected — anomalous transactions but loss not confirmed
   [ ] Unclear — report received but not verified

2) SCOPE (pick one)
   [ ] Under $10K
   [ ] $10K – $100K
   [ ] $100K – $1M
   [ ] Over $1M
   [ ] Unknown (still assessing)

3) ATTACK STATUS (pick one)
   [ ] Ongoing — attacker activity appears active right now
   [ ] Stopped — attack appears stopped (for now)
   [ ] Unknown

4) CONTROL SURFACE (check all that apply)
   [ ] Program has an emergency pause instruction
   [ ] Upgrade authority is a single keypair (reachable now)
   [ ] Upgrade authority is Squads v4 multisig
       Threshold: ___ of ___   Signers reachable in 10 minutes: ___
   [ ] Mint freeze authority exists (SPL/Token-2022)
   [ ] Program is immutable (no upgrade authority)
   [ ] None of the above / unsure

5) SIGNAL (pick the closest match)
   [ ] Fund drain from program vaults / user positions decreasing
   [ ] Unauthorized mint / supply inflation
   [ ] Oracle manipulation / economic attack (liquidations, insolvency path)
   [ ] Governance or admin takeover (authority change, malicious proposal)
   [ ] Frontend/infrastructure compromise (phishing UI, API key leak, bot misbehavior)
```

---

## Severity Classification (P0–P3)

| Confirmed? | Ongoing? | Scope | Severity |
|------------|----------|-------|----------|
| Yes | Yes | Any | **P0 (Critical)** |
| Yes | No | ≥ $100K | **P1 (High)** |
| Yes | No | < $100K | **P1 (High)** |
| Suspected | Yes | Any | **P1 (High)** |
| Suspected | No | Any | **P2 (Medium)** |
| Unclear | Any | Any | **P2 (Medium)** |

P3 (Low) applies only when you can confidently confirm “false positive / no on-chain impact.”

---

## Incident Type Classification (Solana-Specific)

Map from Signal (Q5) to incident type:
- Fund drain → vault drain / account validation failure
- Unauthorized mint → mint authority / supply integrity incident
- Oracle manipulation → oracle manipulation / economic exploit
- Governance takeover → governance/admin compromise
- Frontend/infra compromise → off-chain compromise

---

## Agents To Activate (Deterministic)

```text
Always activate for P0/P1:
  - agents/incident-commander.md
  - agents/forensic-investigator.md
  - agents/comms-director.md

Activate in parallel when “Contained” or moving into recovery:
  - agents/recovery-engineer.md
```

File routing by incident type:

| Incident type | Load next (execution) |
|---------------|------------------------|
| Vault drain | `skill/active-exploit-response.md` + `skill/program-freeze-and-pause.md` |
| Unauthorized mint | `skill/program-freeze-and-pause.md` + `commands/freeze-checklist.md` |
| Oracle/economic | `skill/active-exploit-response.md` + `skill/anomaly-detection.md` |
| Governance takeover | `skill/legal-regulatory-response.md` + `skill/program-upgrade-safety.md` |
| Frontend/infra | `skill/crisis-communication.md` + disable/rotate infra immediately |

---

## Immediate Actions (By Severity)

### P0 (Critical) — First 30 Minutes

```text
[ ] 1) Activate agents/incident-commander.md (single decision thread).
[ ] 2) Activate agents/forensic-investigator.md (evidence before state changes).
[ ] 3) Execute containment: skill/program-freeze-and-pause.md + commands/freeze-checklist.md.
[ ] 4) Draft comms immediately: agents/comms-director.md (publish only if IC approves).
[ ] 5) If funds are in protocol vaults and can be moved safely: skill/liquidity-migration.md (parallel).
[ ] 6) If contained: activate agents/recovery-engineer.md (accounting/compensation/redeploy).
```

### P1 (High) / P2 (Medium) / P3 (Low)

```text
P1: preserve evidence + determine if ongoing; escalate to P0 if yes; prepare comms drafts.
P2: validate anomalies via skill/anomaly-detection.md; re-triage if any confirmed loss appears.
P3: log + monitor; improve alerts.
```

---

## Output Format (What This Command Returns)

The agent must return exactly this structure:

```text
SEVERITY: [P0/P1/P2/P3]
TYPE: [vault drain / unauthorized mint / oracle manipulation / governance takeover / frontend/infra compromise]

IMMEDIATE ACTIONS:
1) ...
2) ...
3) ...

AGENTS TO ACTIVATE:
- agents/incident-commander.md
- agents/forensic-investigator.md
- agents/comms-director.md
- agents/recovery-engineer.md (if contained / recovery phase)

FILES TO LOAD NOW:
- ...
- ...
```
