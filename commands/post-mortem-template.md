# /post-mortem-template

Generates a complete post-mortem document pre-filled with your incident details, ready to publish.

## Usage

```
Run /post-mortem-template — incident date [DATE], protocol [NAME], amount lost [AMOUNT or "none"], attack vector [brief description], root cause [what failed], fix deployed [yes/no], compensating users [yes/no, how].
```

## Document Structure (agent generates this filled in)

---

```markdown
# [PROTOCOL] — Incident Post-Mortem
**Date:** [INCIDENT DATE UTC]
**Published:** [TODAY DATE UTC]
**Severity:** [P0 Critical / P1 High / P2 Medium]
**Status:** [Resolved / Ongoing / Monitoring]

---

## Summary

[2-3 sentence non-technical summary. Written for your community, not engineers.
What happened, what was affected, what you did about it, current status.]

---

## Timeline (All times UTC)

| Time | Event |
|------|-------|
| [TIME] | First anomalous transaction detected |
| [TIME] | Internal alert triggered |
| [TIME] | Team notified, incident response began |
| [TIME] | Program paused / mitigation applied |
| [TIME] | Public notice posted |
| [TIME] | Attack confirmed stopped |
| [TIME] | Root cause identified |
| [TIME] | Fix deployed |
| [TIME] | System restored |

---

## Technical Root Cause

[Precise technical explanation. Be specific about the vulnerable code path, 
the exact exploit mechanism, and why it worked. Link to the vulnerable commit if applicable.
If you have a transaction explorer link showing the attack, include it.]

**Vulnerable code (if applicable):**
```code
// The vulnerable pattern
[exact code that was exploited]
```

**Why it was exploitable:**
[Explanation]

---

## Attack Vector

[Describe exactly how the attacker exploited the vulnerability.
Include transaction signatures as evidence. Link to Solscan/SolanaFM.]

**Attacker wallet:** [ADDRESS — only include post-law enforcement coordination]
**Attack transactions:** [List of signatures]
**Funds flow:** [Where funds went — if traceable]

---

## Impact

| Category | Amount |
|----------|--------|
| User funds affected | $[AMOUNT] / [TOKEN AMOUNT] |
| Protocol treasury affected | $[AMOUNT] |
| Total | $[AMOUNT] |
| Users affected | [NUMBER] |
| Duration of exposure | [TIMESPAN] |

---

## What We Did

### Immediate Response (0–2 hours)
- [Action taken and timestamp]
- [Action taken and timestamp]

### Short-term Fix (2–24 hours)
- [Action taken]
- [Action taken]

### Long-term Fix (deployed [DATE])
- [Technical fix description]
- [Audit results]

---

## What We're Changing

[Honest list of process and technical changes. Be specific — not "we'll improve security"
but "we are implementing X specific change by Y date because it would have prevented Z."]

1. **[Specific change]** — [Why this prevents recurrence] — [Timeline]
2. **[Specific change]** — [Why this prevents recurrence] — [Timeline]
3. **[Specific change]** — [Why this prevents recurrence] — [Timeline]

---

## User Compensation

[Clear statement on compensation:
- If compensating: how, when, and how users claim it
- If not compensating: honest explanation (insurance fund depleted, etc.)
- If still determining: timeline for decision]

---

## Acknowledgments

[Credit security researchers who reported, helped, or disclosed responsibly.
Credit other protocols or individuals who assisted in containment.]

---

## Contact

For questions about this incident: [email or Discord]
For security reports: [security@protocol.com]
```

---

## Quality checklist before publishing

```
[ ] Every timeline entry has a specific UTC timestamp (not "around 3pm")
[ ] Root cause is specific — names the exact function/logic that was exploitable
[ ] No promises you can't keep (compensation timelines, "this will never happen again")
[ ] Legal reviewed the compensation section if funds are being returned
[ ] Attack wallet addresses only included if law enforcement coordination is complete
[ ] "What we're changing" items have owners and deadlines
[ ] Published on your official domain — not just Twitter thread
[ ] Translated if significant % of your community is non-English
```

## Post-mortems that set the bar (study these)

- **Wormhole (2022)** — $320M, transparent timeline, specific root cause
- **Crema Finance (2022)** — negotiated return, detailed technical analysis
- **Mango Markets (2022)** — governance manipulation, honest post-mortem
- **Squads (2023)** — near-miss disclosure, exemplary proactive communication

The best post-mortems build MORE trust than existed before the incident. Honesty, speed, and specificity are what separate "they handled it well" from "never using them again."
