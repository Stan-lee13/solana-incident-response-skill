# /post-mortem-template

Generates a complete post-mortem document in a Google SRE-inspired format adapted for Solana
protocols. Run this command after an incident is contained and root cause is known.

---

## Usage

```text
Run /post-mortem-template — the agent collects ALL of the following before filling in the template.
Required inputs (agent prompts for each in order):

  1. incident_date          — UTC date-time of first attacker action (ISO 8601)
  2. protocol               — Protocol name and program ID(s)
  3. severity               — P0 / P1 / P2 / P3 (see severity matrix in SKILL.md)
  4. status                 — resolved / monitoring / ongoing
  5. user_impact_usd        — confirmed USD value lost (or "unknown")
  6. users_affected         — count or "unknown"
  7. root_cause_category    — oracle manipulation / account confusion / reentrancy-equivalent /
                              upgrade exploit / access control failure / economic attack
  8. remediation_shipped    — yes / no / in-progress
  9. compensation_plan      — yes / no / unknown / pending vote
 10. detection_method       — monitoring alert / user report / partner tip / exchange flag /
                              on-chain bot / internal team / external researcher
 11. escalation_path        — actual path followed (e.g., "on-call -> CTO -> legal -> comms"),
                              not the theoretical runbook path
 12. exchanges_contacted    — list of exchanges, each with: name | contacted_at (UTC) |
                              response_received_at (UTC) | outcome
 13. legal_counsel_engaged  — yes (name firm, when engaged) / no / pending
```

> Agent behaviour: If any required input is missing or ambiguous the agent halts and asks
> before proceeding. The agent never fabricates confirmed facts; it marks gaps as [UNKNOWN -- confirm].

---

## Document Template (Agent Outputs This Filled In)

```markdown
# [PROTOCOL] -- Incident Post-Mortem
**Date of incident:** [INCIDENT DATE UTC]
**Published:** [TODAY UTC]
**Severity:** [P0/P1/P2/P3]
**Status:** [Resolved / Monitoring / Ongoing]
**Author(s):** [names / handles]
**Reviewers:** [names / handles -- must include legal before public release]

---

## Executive Summary

[2-5 sentences, non-technical. Confirmed facts only. No speculation, no mitigation promises
beyond what is committed. Written for a technically literate but non-expert audience.]

**Current user guidance:** [do not interact / withdraw via official path / no action required]
**Confirmed loss:** [$ amount] across [assets], affecting [user count or "unknown"] accounts.
**Root cause (one sentence):** [plain-language summary -- no jargon]
**Remediation shipped:** [yes -- commit/tx / no -- ETA: DATE]
**Compensation plan:** [yes -- link to plan / no / pending governance vote by DATE]

---

## Timeline (UTC)

> Slot numbers are **required** for every on-chain event. "Unknown" is not accepted for slots
> where a transaction signature is available -- use `solana confirm -v <sig>` or the Helius
> Enhanced Transactions API to retrieve the slot.

| Time (UTC) | Slot   | Event                                               | Evidence (sig / link)     |
|------------|--------|-----------------------------------------------------|---------------------------|
| [t0]       | [slot] | First attacker probe tx (failed)                    | [sig]                     |
| [t1]       | [slot] | First successful exploit tx                         | [sig]                     |
| [t2]       | [slot] | Significant drain tx #1                             | [sig]                     |
| [t3]       | [slot] | Significant drain tx #2                             | [sig]                     |
| [t4]       | [slot] | Significant drain tx #N (repeat rows as needed)     | [sig]                     |
| [t5]       | [slot] | Detection (see Detection section for method)        | [alert link / report]     |
| [t6]       | [slot] | Incident response activated                         | [Slack/PD link]           |
| [t7]       | [slot] | First exchange contacted (name exchange)            | [email/ticket ref]        |
| [t8]       | [slot] | First exchange response received                    | [email/ticket ref]        |
| [t9]       | [slot] | First public post (Twitter/Discord/Forum)           | [link]                    |
| [t10]      | [slot] | Containment action executed (pause/freeze/upgrade)  | [tx sig]                  |
| [t11]      | [slot] | Containment verified (funds no longer draining)     | [sig / Helius link]       |
| [t12]      | [slot] | Root cause identified                               | [internal doc link]       |
| [t13]      | [slot] | Remediation deployed to mainnet                     | [tx sig / deploy sig]     |
| [t14]      | N/A    | Legal counsel engaged                               | [date / firm]             |
| [t15]      | N/A    | Post-mortem published (this document)               | [link]                    |

**Time-to-detect (TTD):** [t5 - t1] = [duration]
**Time-to-contain (TTC):** [t10 - t1] = [duration]
**Time-to-resolve (TTR):** [t13 - t1] = [duration]

---

## Detection & Alerting

**Detection method:** [monitoring alert / user report / partner tip / exchange flag / on-chain bot /
internal team / external researcher]

**Detection detail:** [who/what triggered the alert, threshold that fired, or how the report
arrived -- be specific: "Helius webhook on vault account balance < floor_threshold" or
"Discord DM from user 0xABCD at 14:32 UTC"]

**Why detection was delayed (if applicable):**
- [ ] No alert existed for the exploited invariant
- [ ] Alert threshold was set too high (set at [X], drain was [Y])
- [ ] Alert fired but was routed to wrong channel / on-call was not paged
- [ ] No monitoring on oracle deviation bounds
- [ ] No monitoring on vault solvency ratio
- [ ] Other: [describe]

**Escalation path actually followed:**
[e.g., on-call engineer -> CTO (notified at t+12m) -> legal counsel (t+47m) -> comms lead (t+1h3m)]

Contrast with documented runbook path and note any deviations:
- [deviation 1 -- e.g., "Legal not notified until t+47m; runbook says t+15m"]
- [deviation 2]

---

## Impact Assessment

### Summary

| Category                    | Amount / Count | Notes                           |
|-----------------------------|----------------|---------------------------------|
| User funds lost             | [amount USD]   |                                 |
| Protocol treasury affected  | [amount USD]   |                                 |
| Insurance fund applied      | [amount USD]   |                                 |
| Net user loss (post-cover)  | [amount USD]   |                                 |
| **Total**                   | **[amount]**   |                                 |

### Breakdown by User Segment

| Segment                   | Accounts affected | Estimated loss (USD) | Notes                           |
|---------------------------|-------------------|----------------------|---------------------------------|
| Liquidity providers (LPs) | [count]           | [amount]             | [which pools / programs]        |
| Borrowers                 | [count]           | [amount]             | [collateral seized / bad debt]  |
| Depositors                | [count]           | [amount]             | [vaults / accounts drained]     |
| Governance token holders  | [count]           | [amount]             | [dilution / treasury loss]      |
| Other (specify)           | [count]           | [amount]             |                                 |

### Bridge / Cross-Chain Exposure

> Assess whether funds crossed a bridge pre- or post-exploit. Ref: Wormhole Feb 2022 $320M --
> exploited state propagated cross-chain before detection. Leave N/A if no bridge interaction.

- Bridge(s) involved: [Wormhole / Portal / deBridge / Allbridge / N/A]
- Direction of exploit interaction: [Solana -> ETH / ETH -> Solana / N/A]
- Funds bridged out: [amount / N/A]
- Bridge team notified: [yes -- UTC time / no / N/A]
- Cross-chain impact (affected contracts on other chains): [describe / N/A]

### Secondary Market Impact

- [PROTOCOL] token price at time of incident: [price]
- [PROTOCOL] token price 24h post-incident: [price] ([% change])
- DEX liquidity removed during incident window: [amount / N/A]
- DEX pools paused: [pool IDs / N/A]
- Collateral depegs triggered: [describe / N/A]

---

## Technical Analysis (Evidence-Based)

**First malicious signature:** [sig] -- slot [slot]
**Incident slot range:** [start slot] - [end slot]
**Attacker fee payer(s):** [address(es)]
**Sink wallet(s):** [address(es)]
**Terminal destination:** [CEX deposit address / bridge escrow / unknown]

Retrieve full transaction history:

    curl "https://api.helius.xyz/v0/addresses/<ATTACKER_ADDR>/transactions\
    ?api-key=<KEY>&type=TRANSFER&before=<LAST_SIG>"

**Entry point:**
- Instruction: [IDL name / discriminator hex / instruction index]
- Abused account(s): [addresses + roles from IDL]
- Victim vault/account(s): [addresses + balances at time of exploit]

**Exploit narrative:**
1. [t0 -- sig] -- Probe: [what the attacker tested; why it failed; what it revealed]
2. [t1 -- sig] -- First success: [precise mechanic -- e.g., "passed forged PDA as vault
   authority; CPI into token program succeeded because owner check absent in handler"]
3. [t2-tN -- sigs] -- Drain loop: [batch pattern, tx count, per-tx amount, total drained]

**Fund flow (trace to terminal destination):**

    [attacker_fee_payer]
      |-- [intermediate_wallet_1]  (slot [slot], sig [sig])
           |-- [intermediate_wallet_2]
                |-- [CEX_deposit / bridge_escrow / unknown]  (slot [slot], sig [sig])

---

## Root Cause

### Proximate Cause vs Contributing Factors vs Systemic Issues

| Layer                    | Description                                                                              |
|--------------------------|------------------------------------------------------------------------------------------|
| **Proximate cause**      | The single technical failure directly enabling the exploit. One thing. One sentence.     |
| **Contributing factors** | Conditions that made the proximate cause exploitable or undetected. List each.           |
| **Systemic issues**      | Process, culture, or tooling gaps that allowed contributing factors to persist.          |

**Proximate cause:** [exact instruction / function / invariant that failed -- commit hash if available]

**Contributing factors:**
- [e.g., "No solvency invariant check after each CPI call"]
- [e.g., "Oracle TWAP window too short for illiquid asset -- ref Mango Markets Oct 2022 $115M"]
- [e.g., "Program authority held in single-sig wallet, not Squads v4 multisig"]

**Systemic issues:**
- [e.g., "Audit scope excluded cross-program invocation paths"]
- [e.g., "No on-chain circuit breaker for anomalous withdrawal volume"]

### Root Cause Category

Select **exactly one**. The evidence requirement for the selected category must be fully satisfied.

| Category               | Select | Evidence required to select this category                                                                         |
|------------------------|--------|------------------------------------------------------------------------------------------------------------------|
| Oracle manipulation    | [ ]    | On-chain price feed shows deviation >N% from reference; tx ordering confirms sandwich or TWAP manipulation; ref Mango Markets Oct 2022 $115M |
| Account confusion      | [ ]    | IDL shows missing `owner` / `mint` / `authority` constraint; forged PDA or account substitution confirmed in tx trace |
| Reentrancy-equivalent  | [ ]    | CPI call provably precedes state update in same instruction; balance delta occurs mid-instruction; ref Crema Finance Jul 2022 $8.8M |
| Upgrade exploit        | [ ]    | Program upgrade tx sig precedes or is part of exploit chain; `BPFLoaderUpgradeable` invoked by attacker-controlled key |
| Access control failure | [ ]    | Instruction is reachable without expected signer/authority; `has_one`, `constraint`, or `signer` check is absent or bypassable in IDL |
| Economic attack        | [ ]    | No code vulnerability present; exploit is executed via permissioned instructions with adversarial economic parameters; e.g., flash loan + liquidation cascade |

---

## Response & Mitigation

### Immediate (0-2h)

| Time (UTC) | Action taken                                       | Who executed  | Evidence                  |
|------------|----------------------------------------------------|---------------|---------------------------|
| [t]        | [e.g., pause via Squads v4 multisig proposal]      | [name/handle] | [tx sig / proposal link]  |
| [t]        | [e.g., freeze affected mint via freeze_authority]  | [name]        | [tx sig]                  |
| [t]        | [e.g., revoked upgrade authority]                  | [name]        | [tx sig]                  |

### Short-term (2-24h)
- [ ] [Action -- owner -- due time]
- [ ] [Action -- owner -- due time]

### Long-term (>24h)
- [ ] [Architectural change -- owner -- due date]
- [ ] [Process change -- owner -- due date]
- [ ] [Audit engagement -- firm -- due date]

---

## What Went Well / What Went Wrong / Where We Got Lucky

**Went well:**
- [e.g., Pause executed in <8m via pre-staged Squads v4 transaction]
- [e.g., Exchange froze attacker deposit within 23m of outreach]
- [e.g., Comms lead had draft template ready; first public post within 45m of detection]

**Went wrong:**
- [e.g., On-call engineer unreachable for first 18m]
- [e.g., Legal not looped in until t+47m despite runbook requiring t+15m]
- [e.g., No runbook existed for this attack vector]

**Lucky:**
- [e.g., Attacker paused after first drain batch, leaving [X]% of funds untouched]
- [e.g., Terminal CEX has active compliance relationship -- froze within 1h]
- [e.g., Exploit required a Jito bundle; Jito block engine logs preserved precise timing]

---

## What Would Have Changed (Counterfactuals)

> List exactly 3. Each must be specific and quantified. Vague statements are not acceptable.

1. **If [specific control had been in place], impact would have been reduced by [estimated % / amount].**
   [e.g., "If a circuit breaker halting withdrawals >5% of TVL per slot had been deployed
   (recommended in audit report AUDIT-2024-003), the second drain batch (worth $X) would
   have been blocked, reducing total loss by ~60%."]

2. **If [specific detection had existed], time-to-contain would have been reduced by [duration].**
   [e.g., "If the Helius webhook alert on vault solvency ratio <95% had been configured,
   TTD would have dropped from 34m to ~3m, allowing containment before drain tx #3."]

3. **If [specific process had been followed], [specific outcome would have differed].**
   [e.g., "If upgrade authority had been transferred to a Squads v4 multisig (recommended
   18 months prior in internal security review), the attacker could not have deployed the
   malicious program upgrade and the proximate cause would not have been reachable."]

---

## Exchanges Contacted

| Exchange     | Contacted (UTC) | Response received (UTC) | Response time | Outcome                           |
|--------------|-----------------|--------------------------|---------------|-----------------------------------|
| [Exchange 1] | [time]          | [time]                   | [duration]    | [frozen / monitoring / no action] |
| [Exchange 2] | [time]          | [time]                   | [duration]    | [frozen / monitoring / no action] |
| [Exchange N] | [time]          | [time]                   | [duration]    | [frozen / monitoring / no action] |

**Contact method:** [email to compliance@ / SEAL 911 / direct relationship / Chainabuse report]

---

## Disclosure Obligations

> **This section must be reviewed and signed off by legal counsel before publication.**
> The rows below are generic regulatory placeholders. Counsel must confirm applicability,
> thresholds, and exact filing requirements for this specific incident and entity structure.

| Jurisdiction | Reporting threshold                     | Regulator / body                          | Filing timeline (from incident)                                            | Required content (counsel to confirm)                                               |
|--------------|-----------------------------------------|-------------------------------------------|----------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| US           | Counsel to confirm -- FinCEN SAR threshold $5,000 for suspicious activity; SEC 8-K if material to a registered entity | SEC / FinCEN / OFAC      | Counsel to confirm -- SAR within 30 days of awareness; 8-K "as soon as reasonably practicable" | Nature of exploit, assets involved, remediation taken, user notification plan        |
| EU           | Counsel to confirm -- MiCA Art. 71 major incident notification for CASPs | National competent authority per MiCA + ESMA | Counsel to confirm -- initial notification without undue delay (MiCA draft guidance: within 4h for significant incidents) | Incident classification, services affected, measures taken, estimated cross-border impact |
| Singapore    | Counsel to confirm -- MAS PS Act major payment incident reporting for licensed entities | Monetary Authority of Singapore (MAS) | Counsel to confirm -- MAS notice within 1 business day for major incidents | Incident description, customer impact, containment measures, root cause when known   |

**Legal counsel sign-off:** [name] -- [date] -- [confirmed applicable / confirmed not applicable / pending]

**Law enforcement:**
- Reported to: [FBI IC3 / local authority / not yet / N/A]
- Case reference: [ref / pending / N/A]
- Blockchain forensics firm engaged: [Chainalysis / TRM Labs / Elliptic / none]

**Legal counsel:**
- Engaged: [yes / no / pending]
- Firm: [name -- redact from public version if not yet disclosed]
- Engaged at: [UTC time]

---

## Remediation & Prevention

| # | Change                                                  | Owner     | Due date | Verification method                          |
|---|---------------------------------------------------------|-----------|----------|----------------------------------------------|
| 1 | [Exact code/config change -- PR/commit link]            | [name]    | [date]   | [test suite / audit / internal repro fails]  |
| 2 | [Monitoring: alert rule for [invariant]]                | [name]    | [date]   | [alert fires on synthetic test event]        |
| 3 | [Authority hardening: transfer to Squads v4 multisig]   | [name]    | [date]   | [on-chain: multisig address confirmed]       |
| 4 | [Runbook update: add [scenario] to playbook]            | [name]    | [date]   | [reviewed by IR lead]                        |
| 5 | [Audit: engage [firm] for [scope]]                      | [name]    | [date]   | [audit report published]                     |

---

## Action Items (RACI)

> **R** = Responsible (does the work) | **A** = Accountable (owns outcome, exactly one person) |
> **C** = Consulted (input required before/during) | **I** = Informed (notified on completion)

| Priority | Action item                                     | R          | A          | C                     | I                       | Due    | Status |
|----------|-------------------------------------------------|------------|------------|-----------------------|-------------------------|--------|--------|
| P0       | Deploy patched program / execute pause          | [eng lead] | [CTO]      | [auditor]             | [all team]              | [date] | [ ]    |
| P0       | Transfer authority to Squads v4 multisig        | [eng lead] | [CTO]      | [legal]               | [all team]              | [date] | [ ]    |
| P1       | Add solvency / invariant monitoring alerts      | [DevOps]   | [eng lead] | [IR lead]             | [ops team]              | [date] | [ ]    |
| P1       | Draft and publish public post-mortem            | [comms]    | [CEO/lead] | [legal, eng lead]     | [community, investors]  | [date] | [ ]    |
| P1       | File regulatory notifications (per counsel)     | [legal]    | [CEO]      | [counsel]             | [board]                 | [date] | [ ]    |
| P2       | Update incident runbook with new attack vector  | [IR lead]  | [eng lead] | [all responders]      | [eng team]              | [date] | [ ]    |
| P2       | Commission follow-on audit of affected scope    | [eng lead] | [CTO]      | [audit firm]          | [investors, community]  | [date] | [ ]    |
| P2       | Implement circuit breaker / withdrawal limits   | [eng lead] | [CTO]      | [auditor, economist]  | [all team]              | [date] | [ ]    |
| P3       | Run tabletop exercise for [new attack category] | [IR lead]  | [eng lead] | [all responders]      | [eng team]              | [date] | [ ]    |
| P3       | Update user compensation FAQ / claim portal     | [comms]    | [CEO/lead] | [legal, finance]      | [community]             | [date] | [ ]    |

---

## Verification (How We Know the Fix Works)

- [ ] Regression test reproduces the exploit against unpatched program (fails) and patched
      program (passes) -- test PR: [link]
- [ ] Internal red-team attempt against patched mainnet-beta deployment found no exploit path
- [ ] Independent reviewer ([name / firm]) confirmed patch correctness -- report: [link]
- [ ] Monitoring alert for original invariant fires on synthetic test event -- runbook: [link]
- [ ] Squads v4 multisig ownership of upgrade authority confirmed on-chain -- address: [addr]

---

## User Compensation

> Do not make commitments in this section beyond what governance has formally approved.

**Decision:** [approved / pending governance vote / no compensation planned / under discussion]
**Vote / proposal link (if applicable):** [link]
**Eligibility criteria:** [describe -- e.g., "accounts with positive balance at slot [slot]"]
**Snapshot slot:** [slot] -- [UTC time]
**Distribution method:** [airdrop / claim portal / manual / TBD]
**Timeline:** [date / TBD]
**Source of funds:** [insurance fund / treasury / token issuance / TBD]
**Amount per user:** [formula / fixed amount / TBD]

---

## Communications & Disclosure

| Update # | Time (UTC) | Platform           | Link   | Key message                           |
|----------|------------|--------------------|--------|---------------------------------------|
| 1        | [time]     | [Twitter/Discord]  | [link] | Initial notice -- incident acknowledged |
| 2        | [time]     | [Twitter/Discord]  | [link] | Containment confirmed                 |
| 3        | [time]     | [Twitter/Discord]  | [link] | Root cause summary                    |
| 4        | [time]     | [Forum/Blog]       | [link] | Full post-mortem published            |

**Update cadence during incident:** every [X] hours until resolved
**Full disclosure target:** [date]

**Omissions from public version (list what was removed and why):**
- [e.g., "Attacker identity withheld pending law enforcement referral"]
- [e.g., "Exact reproduction steps omitted -- available to auditors under NDA"]

---

## Appendix (Evidence)

**Primary exploit signatures (chronological):**
1. [sig] -- slot [slot] -- role: [probe / first success / drain / containment]
2. [sig] -- slot [slot] -- role: [drain]
3. [sig] -- slot [slot] -- role: [containment tx]

**Attacker / sink addresses:**
- [address] -- role: [fee payer / attacker wallet / intermediate / sink / CEX deposit]

**Programs involved:**
- [Program ID] -- [name / version / last upgrade slot]

**Data sources used:**
- Helius Enhanced Transactions: https://api.helius.xyz/v0/addresses/<addr>/transactions
- Solscan: https://solscan.io/tx/<sig>
- Solana Explorer: https://explorer.solana.com/tx/<sig>
- Internal logging: [link / "not available"]
- Jito block engine logs: [link / "requested -- pending"]
- Pyth / Switchboard oracle price history: [link / N/A]

**Supporting documents (internal -- do not publish without legal review):**
- [ ] Incident Slack / PagerDuty export: [link]
- [ ] Helius CSV export of attacker addresses: [link]
- [ ] Audit report(s) covering affected code: [link]
- [ ] Legal counsel correspondence: [link]
```

---

## Quality Checklist

> Complete all 10 items before marking the post-mortem as published. Each item must be signed off
> by a named reviewer -- not just checked by the document author.

```text
[ ] 1.  Every on-chain event in the Timeline has a UTC timestamp AND a slot number.
        "Unknown" is not acceptable where a transaction signature is available.

[ ] 2.  Root cause references the exact instruction name, function, or invariant that failed.
        "Smart contract bug" or "logic error" without specifics is not acceptable.

[ ] 3.  Exactly one root cause category is selected and all evidence criteria for that
        category (Root Cause Category table) are satisfied and documented.

[ ] 4.  Proximate cause, contributing factors, and systemic issues are documented in
        separate fields -- not collapsed into a single "root cause" paragraph.

[ ] 5.  All action items have a named owner (not a team name), a due date, a priority,
        and a complete RACI row.

[ ] 6.  All three counterfactuals in "What Would Have Changed" are specific and quantified.
        Vague statements ("better monitoring would have helped") are not acceptable.

[ ] 7.  Disclosure Obligations section has been reviewed and signed off by legal counsel.
        Reviewer name and date of sign-off recorded in that section.

[ ] 8.  Public version has been diff-reviewed against the internal version. Reproduction
        details, unverified attribution, and in-flight legal matters are removed.

[ ] 9.  User Compensation section contains only formally approved commitments.
        All speculative or aspirational language has been removed.

[ ] 10. Post-mortem reviewed by at least one person who was NOT part of the incident
        response. Fresh-eyes reviewer name and date: [name] -- [date]
```
