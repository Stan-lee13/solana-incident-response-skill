# /post-mortem-template

Generates a complete post-mortem document in a Google SRE-inspired format adapted for Solana protocols.

## Usage

```text
Run /post-mortem-template — incident date [DATE UTC], protocol [NAME], severity [P0/P1/P2/P3], status [resolved/monitoring], user impact [$ / users], root cause [category], remediation shipped [yes/no], compensation plan [yes/no/unknown]
```

## Document Template (Agent Outputs This Filled In)

```markdown
# [PROTOCOL] — Incident Post-Mortem
**Date:** [INCIDENT DATE UTC]  **Published:** [TODAY UTC]
**Severity:** [P0/P1/P2/P3]  **Status:** [Resolved/Monitoring/Ongoing]

## Executive Summary
[2–5 sentences, non-technical. Confirmed facts only.]

**Current user guidance:** [do not interact / withdraw via official path / no action]
**Confirmed impact:** [$ amount] in [assets], [users affected/unknown]

## Timeline (UTC)
| Time | Slot (if known) | Event | Evidence (sig/link) |
|------|------------------|-------|----------------------|
| [t]  | [slot] | Detection | [sig/link] |
| [t]  | [slot] | Incident response activated | |
| [t]  | [slot] | Containment applied (pause/freeze/upgrade) | |
| [t]  | [slot] | First public notice | |
| [t]  | [slot] | Containment verified | |
| [t]  | [slot] | Root cause identified | |
| [t]  | [slot] | Remediation deployed | |

## Detection & Alerting
**How we detected it:** [monitoring alert / user report / partner / exchange]
**Why detection was delayed (if applicable):**
- [missing alert]
- [alert threshold too high]
- [no invariant monitoring for vault balances / oracle deviations]

## Impact Assessment
**Affected surfaces:** [deposits/borrows/swaps/etc]
**Programs/mints:** Program IDs: [...]  Mint IDs: [...]

| Category | Amount | Notes |
|----------|--------|------|
| User funds affected | [amount] | |
| Protocol treasury affected | [amount] | |
| Total | [amount] | |

## Technical Analysis (Evidence-Based)
**First malicious signature:** [sig]
**Incident slot range:** [start slot]–[end slot]

**Entry point (what instruction and what accounts):**
- Instruction: [IDL name / discriminator / instruction index]
- Abused account(s): [...]
- Victim vault/account(s): [...]

**Exploit narrative (technical):**
1) [probe attempt sig/slot] — [what failed]
2) [first success sig/slot] — [what succeeded]
3) [drain batch pattern] — [how funds moved]

**Fund flow summary:**
- Attacker fee payer(s): [...]
- Sink wallet(s): [...]
- Terminal destination (CEX/bridge/unknown): [...]

## Root Cause
**Category:** [oracle manipulation / account confusion / access control failure / upgrade exploit / reentrancy-equivalent / economic attack]
**Failure point:** [exact instruction/function/invariant]
**Why it worked on Solana:** [accounts/signers/CPI/oracle bounds specifics]

## Contributing Factors
- [missing pause / insufficient constraints / missing monitoring / key management weakness]

## Response & Mitigation
**Immediate (0–2h):** [actions + timestamps]
**Short-term (2–24h):** [actions]
**Long-term:** [audits/process changes]

## What Went Well / What Went Wrong / Where We Got Lucky
**Went well:**
- [example: pause executed quickly via Squads]
- [example: monitoring caught drain early]

**Went wrong:**
- [example: signers unreachable]
- [example: unclear ownership of comms]

**Lucky:**
- [example: attacker stopped early]
- [example: funds hit identifiable CEX deposit]

## Remediation & Prevention
1) [Change] — Owner: [name] — Due: [date]
2) [Change] — Owner: [name] — Due: [date]
3) [Change] — Owner: [name] — Due: [date]

## Verification (How We Know The Fix Works)
- [tests added]
- [internal reproduction attempt fails]
- [independent review/audit complete]
- [monitoring alerts added for the original invariant]

## User Compensation
[Plan or decision timeline; no promises beyond what is committed.]

## Action Items (Trackable)
| Priority | Action item | Owner | Due | Status |
|----------|------------|-------|-----|--------|
| P0 | [pause + authority hardening (Squads v4)] | [name] | [date] | |
| P1 | [monitoring/alerts] | [name] | [date] | |
| P2 | [runbooks/docs] | [name] | [date] | |

## Communications & Disclosure
**Public updates:**
- Initial notice: [UTC time] — [link]
- Update cadence: [every X hours]
- Full disclosure target: [date]

**Exchange/partner outreach:**
- Exchanges contacted: [which]
- Partners contacted: [which]

## Disclosure Obligations (Counsel-Reviewed)
- Users notified: [where/when]
- Exchanges notified: [which/when]
- Partners notified: [which/when]
- Law enforcement/regulators: [if applicable]

## Appendix (Evidence)
**Primary signatures:** [...]
**Attacker/sink addresses (if appropriate):** [...]
**Data sources:** [Helius exports, Solscan links, internal logs]
```

## Quality Checklist

```text
[ ] UTC timestamps (and slots where possible) for every key event
[ ] Root cause references exact instruction/function/invariant
[ ] Action items have owners + due dates
[ ] Public version contains no reproduction detail and no unreviewed attribution
```
