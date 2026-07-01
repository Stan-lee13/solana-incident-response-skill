# Crisis Communication

> Load when you need to communicate publicly about a security incident.
> Load `agents/comms-director.md` for real-time drafting assistance.
>
> Timing, honesty, and precision are your only tools.
> Every word you publish is a public record, a legal document, and a signal to your community.

---

## The Comms Director's First Principles

```

1. NEVER post "funds are SAFU" unless you have on-chain proof that all funds are secured

2. NEVER speculate about the attack vector in early communications

3. NEVER name or imply an individual attacker — legal exposure + you may be wrong

4. NEVER make promises about restitution without legal review + confirmed numbers

5. ALWAYS tell users what action to take — not just what happened

6. ALWAYS give a next update time — silence creates panic faster than bad news

7. ALWAYS post from the official account — community knows fake accounts exist

```

---

## Communication Timeline Framework

Every incident follows a predictable communication arc. Deviate from this only with IC + legal approval.

```

T+0     Exploit confirmed internally
        └── DO NOT post. War room only.

T+15    First draft ready
        └── Comms Lead prepares — does NOT post until IC approves

T+20-45 Initial Notice posted (ONLY if: IC approved, no active drain ongoing)
        └── If drain still ongoing at T+45: post anyway — silence is worse than "we're investigating"

T+60-90 First Update
        └── Either: "Program frozen, investigation ongoing" OR "Attack stopped, we're assessing"

T+2-4h  Situation Update
        └── Scope confirmed, recovery plan outlined, next steps stated

T+24h   Preliminary Post-Mortem
        └── What happened (broad), how much, immediate remediation steps, timeline for full report

T+72h-2wk Full Post-Mortem
        └── Complete technical analysis, root cause, fix description, user impact, recovery plan

```

---

## Template Library

### Template 1: Initial Notice (T+20 to T+45)

Use when: You've confirmed an incident but don't yet have full scope.

```

[PROTOCOL NAME] Security Notice — [DATE]

We have identified a security issue affecting [PROTOCOL NAME] and have paused [DEPOSITS/SPECIFIC FUNCTION/ALL ACTIVITY] as a precaution.

What you should do now:
→ Do not deposit additional funds to [PROTOCOL NAME] until further notice
→ Your existing positions are [BEING ASSESSED / UNAFFECTED BASED ON CURRENT ON-CHAIN REVIEW — we will update within 1 hour]
→ Follow this account for updates — we will post every [30/60] minutes

We are actively investigating. Our next update will be at [SPECIFIC TIME UTC].

[DO NOT ADD MORE DETAIL IN THE INITIAL NOTICE. Every additional detail you add now may need to be corrected later. Short and factual wins.]

```

### What NOT to include in the initial notice

- The attack vector ("we believe there was a reentrancy issue")

- An attacker wallet address (legal exposure + may be wrong)

- A restitution promise ("we will make all users whole")

- A cause ("due to a smart contract vulnerability")

- A scale ("approximately $X has been affected")

---

### Template 2: Containment Update (T+60 to T+90)

Use when: Program is frozen and you've stopped the drain, but full scope not yet known.

```

[PROTOCOL NAME] Update — [TIME UTC]

Update on the security incident from [EARLIER TIME]:

✅ [PROGRAM NAME] has been paused. We have not observed new unauthorized movement from the paused component since [TIME UTC].

Current status:

- We are actively investigating the root cause

- We are auditing all affected accounts to determine the scope

- User funds in [VAULTS/POOLS/STAKING] are [being assessed / confirmed secure at this address: TX_LINK]

Next steps:

1. Complete forensic analysis of the incident

2. Engage an independent security firm for verification

3. Publish a full post-mortem within [24/72] hours

No further action is required from users at this time.

We will post our next update by [SPECIFIC TIME UTC].

```

---

### Template 3: Scope Confirmation (T+2 to T+6h)

Use when: You have confirmed the total impact and the attack is fully contained.

```

[PROTOCOL NAME] Incident Update — [TIME UTC]

We can now confirm the scope of today's security incident:

WHAT HAPPENED
At approximately [TIME UTC], an attacker exploited [a vulnerability in / our] [DESCRIBE FUNCTION — keep it broad: "a deposit function" rather than specific technical details].

IMPACT
Approximately [AMOUNT USD / TOKEN AMOUNT] was affected.
[X] user wallets had positions impacted.
All [remaining / other] funds are [being assessed / confirmed unaffected based on current on-chain review].
No new unauthorized movement has been observed since [TIME UTC].

WHAT WE ARE DOING

1. Independent security audit: We have engaged [FIRM NAME] to conduct a full audit

2. Recovery plan: We are working on options for affected users (full details in post-mortem)

3. Redeployment: We will not relaunch until the audit is complete and the fix is verified

WHAT USERS SHOULD DO
→ No action required at this time
→ Affected users will be contacted directly via [CHANNEL] by [DATE]

Full post-mortem will be published within [72h / 1 week].

[TEAM NAME]

```

---

### Template 4: White Hat Bounty Offer

Use when: Funds are held by an attacker who may respond to negotiation. Only after legal review.

```

To the individual who exploited [PROTOCOL NAME] on [DATE]:

We are prepared to discuss a coordinated return of funds through a legally reviewed recovery process.

Proposed recovery path, subject to legal review and sanctions screening:
→ Return [X%] of affected funds to: [RECOVERY_ADDRESS]
→ The team will evaluate a bounty of up to [X%] ([AMOUNT USD]) after returned funds are verified
→ We cannot promise immunity, non-reporting, or confidentiality, but constructive cooperation will be documented accurately

This offer expires [DATE + TIME UTC].

Contact: [ENCRYPTED EMAIL / KEYBASE / PGP]

We are monitoring on-chain and are prepared to engage constructively.

```

**Never post a white hat bounty without legal counsel.** The offer itself may affect your legal standing in different jurisdictions.

---

### Template 5: Full Post-Mortem Structure

The full post-mortem is published 72 hours to 2 weeks after the incident. It is the most important document for community trust recovery.

```markdown

## [PROTOCOL NAME] Incident Post-Mortem — [DATE]

## Summary

[3-5 sentence executive summary: what happened, how much was lost, what was fixed]

## Timeline

[Chronological events with UTC timestamps]

- [TIME UTC]: [EVENT]

- [TIME UTC]: [EVENT]

## Technical Root Cause

[Technical description of the vulnerability]
[The exact code path that was exploited — no need to redact; the exploit is already public]
[Why the existing safeguards didn't catch it]

## Impact Assessment

- Total funds affected: [AMOUNT]

- Affected users: [COUNT]

- Breakdown by asset: [TABLE]

## Immediate Response Actions

[Numbered list of containment actions taken, with timestamps]

## Root Cause Fix

[Description of the code change that fixes the vulnerability]
[Link to the audited PR / commit]
[Name of audit firm that reviewed the fix]

## User Recovery Plan

[Specific plan: snapshot date, eligibility criteria, distribution mechanism, timeline]
[If no recovery: honest explanation of why and what alternatives exist]

## Prevention: What We're Changing

[Specific process and code changes to prevent recurrence]
[New monitoring systems]
[New multisig policies]
[Ongoing security partnerships]

## Acknowledgments

[Security firms who helped, community members who reported issues]

---
Published: [DATE]
[TEAM SIGNATURES]

```

---

## Platform-Specific Guidance

### Twitter/X

- First post: Short, factual, official account only

- Thread format: 1st tweet = the most important fact, subsequent tweets = detail

- Pin the incident thread to your profile immediately

- Every major update = reply to the original thread (not a new thread)

### Discord

- Create a `#incident-updates` channel immediately, lock it to team-only posting

- Post every update there — send announcements to all major channels

- Mute `#general` posting if the community is spreading misinformation

### Telegram

- Pin the latest update to the group

- Consider temporarily putting announcement-only mode on main group

### Email (for protocols with user accounts)

- Send to all users with on-chain exposure FIRST — before public tweet

- Include: what happened, what they need to do, when to expect more info

---

## What the Community Will Say — And How to Handle It

### "Funds are SAFU" farming from community members

→ Don't engage. Let official statements stand alone.

### "Rug pull" accusations

→ Your actions speak louder than replies. Execute recovery plan. Let it speak.

### "When refund?"

→ Only respond when you have a confirmed recovery plan. Never speculate.

### "Name the attacker"

→ Only after legal clearance and confirmed identification. Never speculate publicly.

### Competitor protocols amplifying the incident

→ Ignore. Focus on execution.

### Security researchers posting speculation about the attack vector

→ Do not confirm or deny until your post-mortem is ready. Confirming speculation can affect legal proceedings.

---

## Comms Metrics — How to Know You're Doing Well

```

GOOD signs:
□ Community sentiment shifts from "rug pull" to "team is handling it"
□ Questions shift from "where are my funds?" to "when can we use the protocol again?"
□ Independent security researchers are defending the team's transparency
□ 90%+ of community is getting information from your official channel, not CT speculation

BAD signs:
□ Multiple conflicting pieces of information have been posted (different team members posting)
□ Team is responding to individual DMs with different information
□ First notice was posted >90 minutes after incident was confirmed
□ Post-mortem deadline has slipped more than 2 weeks without a dated explanation
□ "Funds are SAFU" was posted before it was confirmed on-chain

```
