# /draft-incident-notice

Generates draft public-facing communications for a Solana protocol security incident. Run immediately after `/classify-incident` confirms severity >= S2. All outputs are **drafts** — legal must review before publish.

---

## WARNING: WHAT NOT TO INCLUDE — READ BEFORE DRAFTING

These errors have compounded real losses. Each entry includes what to say instead.

### Legal Liability Traps — Specific Solana Examples

| Forbidden Phrase | Why It Is Dangerous | Use Instead |
|---|---|---|
| **"Funds are SAFU"** | Cashio (Mar 2022, $48M) published this while the exploit drain was still in progress. Created false confidence, delayed user action, and featured in regulatory correspondence. | *"We are investigating unusual activity. As a precaution, do not interact with the protocol until further notice."* |
| **"We are working to make users whole"** | Forward-looking financial commitment. If recovery fails or is partial, this statement becomes evidence of a broken promise in civil proceedings. Insurance/treasury limits may not cover full losses. | *"We are assessing impact and will communicate options as information becomes available."* |
| **"The vulnerability has been patched"** | Implies the attack vector is fully closed. If a second exploit occurs on the same codebase, this statement is cited to show negligence in your initial assessment. | *"A fix is in review. The program remains paused pending audit confirmation."* |
| **"This was an isolated incident"** | Mango Markets (Oct 2022, $115M) — early statements characterizing the oracle manipulation as isolated contributed to legal complexity around the attacker own on-chain governance proposal. Implies no systemic risk when you cannot yet know that. | *"Our investigation is ongoing. We will publish a full post-mortem within [X] days."* |
| **"[Named party] was responsible"** | Public attribution before law enforcement coordination exposes you to defamation claims if wrong, and tips the actual attacker. Mango legal proceedings were complicated by early community speculation amplified by official channels. | *"The source of the exploit is under investigation."* |
| **"Attacker address: [pubkey]"** | Publishing attacker addresses publicly before coordinating with exchanges gives the attacker advance notice to move funds to CEX accounts. Contact Binance/Coinbase/Kraken security teams via direct channel FIRST. Standard window: 2-4h before any public disclosure of addresses. | *"We have identified on-chain activity and are coordinating with exchange partners. Relevant addresses will be published in our post-mortem."* |
| **"We have recovered/frozen X% of funds"** | Recovery amounts change. Stating a figure before accounting closes creates liability if the final number differs. | *"Recovery efforts are underway. We will provide confirmed figures in our post-mortem."* |
| **"Our smart contracts are audited by [firm]"** | Implies the audit should have caught this. Creates potential liability for the audit firm AND implies your own due diligence was adequate — both claims you cannot fully defend under cross-examination. | Omit audit references entirely from incident notices. |

### Three Phrases That Sound Safe But Create Legal Problems

1. **"We are working to make users whole"** — Forward-looking financial commitment. If recovery is partial or fails, this is actionable. See table above.
2. **"The vulnerability has been patched"** — Premature closure assertion. A second exploit on the same system after this statement is cited as evidence of negligence. See table above.
3. **"This was an isolated incident"** — Scope limitation claim made before investigation is complete. If other components are later found affected, you have publicly misrepresented the incident. See table above.

### Do Not Include In Any Communication

- Loss estimates in dollar terms before accounting closes (use "significant" or omit entirely)
- On-chain attacker addresses before exchange coordination is complete
- Internal Slack/Discord screenshots or logs
- Names of individual team members involved in incident response
- Speculation about attacker identity, nationality, or affiliation
- References to ongoing law enforcement contact ("we have contacted the FBI" creates public expectations)
- Comparisons to other protocols incidents by name
- Promises about timeline for recovery or program resume
- Any commitment to compensate before treasury/insurance review is complete

---

## TIMING MATRIX

Use this table to decide which outputs to publish and what approval gates apply.

| Time Since Incident | Recommended Action | Gate Required |
|---|---|---|
| **0-15 min** | Internal triage only. No public comms. Pause program via upgrade authority or Squads v4 multisig if exploit is live. DM exchange partners directly. | Incident Commander approval |
| **15-30 min** | Post Twitter/X Variant A if exploit is active and users are at risk of ongoing loss. Discord pinned message only — no full announcement yet. | Incident Commander + 1 legal/comms sign-off |
| **30-60 min** | Full Discord announcement. Investor email sent. Exchange deposit freeze requests dispatched with available evidence. | Incident Commander + legal sign-off |
| **1-2 h** | Twitter/X Variant B (if situation is now contained) replaces or supplements Variant A. Exchange trading halt request if token manipulation is confirmed. | Full comms team review |
| **2-6 h** | Status update thread on Twitter/X. Updated Discord announcement with current status. Board call conducted using talking points below. | CEO/Founder sign-off |
| **6-24 h** | Interim post-mortem stub published (title, date, "full report in 72h"). Regulatory notification if jurisdiction requires (consult counsel first). | Legal + CEO sign-off |
| **24-72 h** | Full post-mortem published. Recovery/compensation framework announced if applicable. Exchange restrictions lifted or extended with written justification. | Board + legal sign-off |

---

## OUTPUT 1 — TWITTER/X THREAD

### Variant A: Active Exploit — Users Must Stop Interacting NOW

> Use when: exploit drain is ongoing, users actively transacting are losing funds, program is not yet paused.

**Tweet A1** *(status = first notice, pin immediately)*
```
SECURITY INCIDENT | [PROTOCOL NAME]

We have detected unusual activity affecting [PROGRAM/VAULT NAME].

Immediate precaution: DO NOT interact with [protocol URL] until further notice.

We are investigating. Updates to follow in this thread.
```
*Target: under 200 chars. Pin to profile immediately.*

**Tweet A2** *(what users should do right now)*
```
If you have funds in [protocol]:
- Do NOT attempt to withdraw — txns may fail or be front-run
- Do NOT click links from anyone claiming to offer refunds
- Revoke infinite approvals at revoke.cash if applicable

Official updates: this account only.
```
*Target: under 230 chars. Post within 2 minutes of Tweet A1.*

**Tweet A3** *(scope — state only what you can confirm)*
```
What we can confirm:
- [Program name] is paused / upgrade authority invoked
- [X] pools / [Y] vaults affected [OR: "Scope is being determined"]
- No action required beyond halting new deposits

We will not DM you.
```
*Target: under 220 chars. Use "Scope is being determined" rather than guessing.*

**Tweet A4** *(team status signal)*
```
Full incident response team is active.

We are:
- Coordinating with exchange partners
- Preserving on-chain evidence
- Engaging security researchers

Next update: [TIME UTC / "within 30 minutes"]
```
*Target: under 180 chars. Commit to a specific update time you can meet.*

**Tweet A5** *(anti-phishing close)*
```
Phishing alert: scammers will post fake "refund" links within minutes.

Bookmark only:
Official site: [URL]
Official Discord: [invite link]

We will NEVER ask for your seed phrase or wallet connect to recover funds.
```
*Target: under 260 chars. This tweet saves real money — do not skip it.*

---

### Variant B: Contained Incident — Informational Update

> Use when: exploit is stopped, program is paused, no ongoing drain. Situation is under control. Use this to replace Variant A once contained, or as initial comms if the incident was caught pre-drain.

**Tweet B1** *(status = contained)*
```
Security notice | [PROTOCOL NAME]

We identified and contained a security incident affecting [component].

The [program/vault] has been paused as a precaution. User funds are not currently at risk of further loss.

Full update below.
```
*Target: under 250 chars. "Not currently at risk of further loss" — do not say "funds are safe."*

**Tweet B2** *(what happened — high level only)*
```
Earlier today, our monitoring flagged anomalous on-chain activity in [program name].

The program was paused at slot [XXXXXXXX] via [upgrade authority / Squads multisig].

Investigation is ongoing.
```
*Target: under 210 chars. Include the slot number — it signals technical credibility.*

**Tweet B3** *(current status)*
```
Current status:
- Program: PAUSED
- User withdrawals: [enabled/disabled — specify]
- New deposits: BLOCKED
- Exchange coordination: IN PROGRESS

No interaction with the program is required or recommended at this time.
```
*Target: under 240 chars. Be explicit about withdrawal status — users will ask.*

**Tweet B4** *(next steps and timeline)*
```
What happens next:
- Independent security review of the paused program
- On-chain post-mortem (target: [DATE])
- Compensation/recovery framework (target: [DATE])
- Program resume: only after audit sign-off

Updates to follow in this thread.
```
*Target: under 240 chars. Only commit to timelines you can meet.*

**Tweet B5** *(accountability signal)*
```
We take full responsibility for the security of this protocol.

A complete post-mortem — including root cause, timeline, and remediation — will be published at [URL] within 72 hours.

Thank you for your patience.
```
*Target: under 230 chars. "Full responsibility" is appropriate. "We apologize" is not — save apologies for the post-mortem.*

---

## OUTPUT 2 — DISCORD ANNOUNCEMENT

### Pinned Message Template

Post this FIRST. Pin it. Then post the full announcement.

```
PINNED — SECURITY INCIDENT NOTICE

Status: [ACTIVE INCIDENT / CONTAINED / RESOLVED]
Last updated: [UTC timestamp]
Program: [NAME] — [PAUSED / OPERATIONAL]

Official updates in this channel only.
No team member will DM you about refunds.
Do not click any links from non-verified members.

Track on-chain activity: [Helius explorer link if address coordination is complete]
```

---

### Full Announcement Template

```
# Security Incident Notice — [PROTOCOL NAME]
**Posted:** [UTC datetime] | **Status:** [Active / Contained / Resolved]

---

## What Happened
[2-3 sentences. State facts only. No attribution. No dollar figures if unconfirmed.]

Example: "We detected anomalous transactions in the [program name] program beginning
at approximately [time] UTC. The program has been paused. Investigation is ongoing."

---

## Immediate Actions for Users
- **STOP** depositing to or interacting with [protocol] until further notice
- **DO NOT** click links from anyone claiming to offer refunds — these are scams
- **REVOKE** infinite approvals if applicable: https://revoke.cash
- **WAIT** for official updates in this channel

---

## What We Are Doing
- [ ] Program paused via [upgrade authority / Squads v4 multisig]
- [ ] On-chain forensics in progress (Helius Enhanced Transactions API)
- [ ] Exchange partners notified — deposit freeze requested
- [ ] Legal counsel engaged
- [ ] Independent security review commissioned

---

## What We Know (Confirmed Only)
[List only confirmed facts. Omit anything unconfirmed.]

---

## What We Do Not Yet Know
[Explicitly listing unknowns builds trust. Example: "The full scope of affected
accounts has not been determined."]

---

## Next Update
We will post an update by [TIME UTC] or sooner if the situation changes.

---

## Anti-Phishing Warning
Scam accounts impersonating [protocol] are active immediately after incidents.

Official communications only:
- This Discord channel: #[channel-name]
- Twitter/X: @[handle]
- Website: [URL]

**No team member will DM you. No refund link is legitimate.**
```

---

### Role Mention Guidance

| Scenario | Mention To Use | Rationale |
|---|---|---|
| Active exploit, funds draining now | @everyone | Maximum urgency; every user must see this immediately |
| Contained incident, no ongoing loss | @[holders-role] or no mention | Avoids panic for non-holders; reduces noise |
| Informational post-mortem | No @ mention | Not urgent; let users discover organically |
| Phishing wave detected | @everyone | Community safety issue affects all members |

Do not use @everyone for contained incidents. Unnecessary pings erode trust and cause members to disable notifications — reducing effectiveness of future urgent alerts.

---

## OUTPUT 3 — INVESTOR / STAKEHOLDER EMAIL

### Subject Line Options

| Severity | Subject Line |
|---|---|
| **Mild** (contained, low impact) | `[Protocol Name] — Security Notice and Program Pause [Date]` |
| **Moderate** (material impact, investigation ongoing) | `[Protocol Name] — Security Incident: Immediate Update Required` |
| **Severe** (material loss confirmed, active response) | `URGENT: [Protocol Name] Security Incident — Board Call [Time] Today` |

---

### Email Body Template

```
[Investor/Partner Name],

I am writing to inform you of a security incident affecting [Protocol Name]
that occurred on [date] at approximately [time] UTC.

CURRENT STATUS
[One sentence. Example: "The affected program has been paused and the situation
is contained."]

WHAT WE KNOW (CONFIRMED)
- [Fact 1]
- [Fact 2]
- [Scope statement or "Scope is being determined"]

WHAT WE ARE DOING
- Incident response team activated at [time]
- Independent security review commissioned
- Exchange partners notified; deposit freezes requested
- Legal counsel engaged
- Law enforcement notification: [pending counsel advice / not applicable]

WHAT WE DO NOT YET KNOW
- [Unknown 1]
- [Unknown 2]
We will share confirmed information as it becomes available.

NEXT COMMUNICATION
We will send a follow-up by [time/date] or sooner if material developments occur.
A board call is scheduled for [time] today. Dial-in: [link/number].

[Name]
[Title], [Protocol Name]
```

---

### Board Call Talking Points (5-Minute Verbal Update)

Each bullet = approximately 45 seconds. Use this verbatim if the call is called on short notice.

1. **What happened:** "At [time] UTC, we detected [anomalous activity / exploit / unauthorized withdrawals] in [program name]. The program is now paused."
2. **Current scope:** "Our current assessment is [X pools/vaults affected / scope TBD]. We are [confirming / cannot yet confirm] user loss figures — we will not state a dollar figure until accounting confirms."
3. **Response actions taken:** "We have paused the program, notified exchange partners, engaged [security firm / internal team], and retained legal counsel."
4. **What is not yet known:** "Root cause, full scope of impact, and recovery options are still being determined. We expect more clarity within [timeframe]. We will not speculate on these points publicly."
5. **Decisions needed from this group:** "[Specific ask: e.g., authorize $X from treasury for security firm, approve public statement, approve law enforcement referral — be specific and actionable.]"

---

### What NOT to Send Over Email

- Dollar loss estimates before accounting review is complete
- Forward-looking statements about compensation or making users whole
- Speculation about attacker identity
- Internal Slack or Discord screenshots or message logs
- Draft post-mortems before security review is complete
- Comparisons to specific other protocol incidents by name
- Any statement that reads as an admission of negligence
- Regulatory breach notifications before counsel advises — timing and form are jurisdiction-specific and filing prematurely can waive rights

---

## OUTPUT 4 — EXCHANGE PARTNER NOTICE

Send to exchange security teams via pre-established direct channels — not public support tickets.
Maintain your exchange emergency contact list in your Squads v4 multisig documentation or incident runbook before an incident occurs.

---

### Variant A: Deposit Freeze Request

> Use when: exploit is active or newly contained, attacker funds may be moving to CEX deposit addresses.

```
TO: [Exchange Name] Security Team
FROM: [Protocol Name] — [Contact Name, Title]
SUBJECT: URGENT — Deposit Freeze Request: [Protocol Name] Security Incident

SUMMARY
[Protocol Name] has experienced a security incident. We believe exploit proceeds
may be moving toward exchange deposit addresses. We are requesting an immediate
deposit freeze on the addresses listed below pending investigation.

INCIDENT DETAILS
Requesting Party: [Protocol Name]
Incident Time: [UTC timestamp]
Program Affected: [Program address / name]
Evidence Tier: [Tier 1 / Tier 2 / Tier 3 — see definitions in runbook]

ADDRESSES TO FLAG
1. [address] — [role: suspected attacker wallet / intermediate hop / destination]
2. [address] — [role]

RELEVANT TRANSACTIONS
- [signature] — [description, e.g., "initial exploit tx, slot XXXXXXXX"]
- [signature] — [description]

On-chain reference (Helius Enhanced Transactions): [link]

We are available immediately for a call.
Contact: [name], [email], [phone or Signal handle]

We will follow up with a formal written request within [X] hours.
```

---

### Variant B: Trading Halt Request

> Use when: token price is being manipulated as part of or as a result of the exploit (cf. Mango Markets oracle manipulation, Oct 2022), or protocol token is being sold in volume by the attacker.

```
TO: [Exchange Name] Security Team
FROM: [Protocol Name] — [Contact Name, Title]
SUBJECT: URGENT — Trading Halt Request: [TOKEN] — Market Manipulation Incident

SUMMARY
We have evidence of on-chain market manipulation affecting [TOKEN] originating
from [program/oracle exploit]. We are requesting a temporary trading halt on
[TOKEN/PAIR] to prevent further harm to market participants.

INCIDENT DETAILS
Token: [NAME] / Mint: [address]
Incident Time: [UTC timestamp]
Nature of Manipulation: [oracle price manipulation / flash loan / collateral exploit]
Evidence Tier: [Tier 1 / Tier 2 / Tier 3]

SUPPORTING EVIDENCE
- [signature] — [description]
- [signature] — [description]
- Price impact observed: [X% move in Y minutes on-chain]
- Pyth/Switchboard oracle feed reference: [link]

SPECIFIC REQUEST (check applicable)
[ ] Halt deposits of [TOKEN]
[ ] Halt withdrawals of [TOKEN]
[ ] Halt spot trading of [TOKEN/USDC] pair
[ ] Halt spot trading of [TOKEN/USDT] pair
[ ] Temporary delist [TOKEN]

Contact: [name], [email], [phone or Signal handle]
```

---

### Evidence Quality Tiers

Include the tier designation explicitly in every exchange notice. Exchanges use this to calibrate response speed and action scope.

| Tier | Definition | What to Include |
|---|---|---|
| **Tier 1** | Transaction signatures + confirmed attacker addresses + on-chain proof of exploit path | Full signatures, Helius Enhanced Transaction links showing pre/post balances, Anchor program logs confirming unauthorized instruction execution |
| **Tier 2** | Slot range of exploit + suspected addresses, no confirmed full tx path yet | Slot range, suspected addresses, brief explanation of why addresses are suspected, commitment to provide Tier 1 within [X] hours |
| **Tier 3** | Addresses only, provisional — investigation in early stage | Address list marked PROVISIONAL — UNDER INVESTIGATION, explicit acknowledgment that evidence is not yet confirmed, request for precautionary flag only rather than freeze |

Never present Tier 2 or Tier 3 evidence as Tier 1. Incorrect evidence tiers damage exchange relationships and can create legal liability if a freeze is applied to an uninvolved address.

---

### Escalation: If No Exchange Response Within 4 Hours

1. **Re-send** the original message with subject prefix `[ESCALATION — 4H NO RESPONSE]` to the same channel.
2. **Phone or Signal** the emergency contact from your pre-established exchange contact list. A list with no phone numbers is not a contact list.
3. **Escalate internally:** notify your CEO/Founder to contact their counterpart relationship at the exchange directly. Relationship-level escalation resolves >60% of no-response situations.
4. **Document:** log every contact attempt with timestamp, channel used, and outcome in your incident timeline file. This log is discoverable.
5. **At 8h with no response:** contact the exchange legal or compliance team directly via email. Copy your legal counsel on all correspondence from this point.
6. **Parallel track:** file a report with the appropriate financial intelligence unit (FinCEN for US exchanges, FCA for UK, MAS for Singapore) if funds are material and exchange remains unresponsive. Consult counsel before filing — the timing and form of regulatory reports are jurisdiction-specific.

---

## PRE-PUBLISH CHECKLIST

Complete before publishing any output from this command.

- [ ] Legal has reviewed or explicitly waived review in writing (document the waiver with timestamp)
- [ ] No dollar loss figures in any output unless accounting has confirmed the number
- [ ] No attacker addresses in public outputs unless exchange coordination window is closed (minimum 2h)
- [ ] No attribution language — no named parties, no nationalities, no affiliations
- [ ] No forward-looking financial commitments in any output
- [ ] All official links verified as correct (wrong links are immediately weaponized by phishers)
- [ ] Incident Commander has signed off on the current status level (Active / Contained / Resolved)
- [ ] Discord pinned message is posted and pinned BEFORE the full announcement is sent
- [ ] Twitter/X variant selection matches actual incident status at time of publish
- [ ] Exchange notices dispatched and delivery confirmed before any public address disclosure
- [ ] Anti-phishing warning included in all public outputs

---

## REFERENCE — INCIDENTS CITED IN THIS DOCUMENT

| Incident | Date | Loss | Communication Failure Cited |
|---|---|---|---|
| Cashio | Mar 2022 | $48M | "Funds are SAFU" published mid-drain |
| Wormhole | Feb 2022 | $320M | Attribution uncertainty; no user-facing protocol pause notice |
| Crema Finance | Jul 2022 | $8.8M | Premature "patched" statement before full audit; secondary review found additional issues |
| Mango Markets | Oct 2022 | $115M | Public attacker characterization complicated governance vote and subsequent legal proceedings |

Use these only in post-mortems and internal retrospectives. Do not reference them by name in public incident notices.
