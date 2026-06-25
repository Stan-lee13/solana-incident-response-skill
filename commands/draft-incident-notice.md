# /draft-incident-notice

Generates a ready-to-post incident notice bundle (public + stakeholders) within 2 minutes of confirmation.

## Usage

```text
Run /draft-incident-notice
```

The agent outputs: X thread (5 tweets), Discord announcement, investor email, exchange notice.

---

## Required Inputs (Ask All At Once)

```text
1) What happened (confirmed facts only)?

2) What is affected?
   - product surface + (optional) program/mint IDs

3) What has been done so far?
   - paused protocol / disabled deposits / maintenance mode / mitigation ongoing

4) What should users do right now?
   - do not interact / withdraw via official link / no action required

5) Logistics
   - canonical updates link + next update time (UTC) + security email
```

---

## Output Bundle (Agent Must Produce All 4)

### 1) X/Twitter Thread (5 Tweets)

```text
TWEET 1/5
[PROTOCOL] Security Notice | [UTC time]
We are investigating suspicious activity affecting [surface].
User guidance: [do not interact / specific action].
Updates will be posted here and in [official channel link].
TWEET 2/5
Containment status: [paused / deposits disabled / mitigation ongoing].
We will provide another update by [UTC time].
TWEET 3/5
What we know (confirmed):
- [fact 1]
- [fact 2]
What is still being assessed:
- [unknown 1]
TWEET 4/5
Security reminder:
Do not click “recovery/claim/refund” links shared by anyone.
We will only share official links via [canonical channel].
TWEET 5/5
If you believe you are affected, do not share private keys or seed phrases.
Support: [support channel]  Security: [security email]
Next update by [UTC time].
```

### 2) Discord Announcement (Canonical)

```text
@everyone
🚨 **Security Notice — [PROTOCOL] | [UTC time]**
**Summary (confirmed):**
[2–3 sentences. Confirmed facts only.]
**Immediate user guidance:**
- [Action 1]
- [Action 2]
**Containment status:**
- [paused / deposits disabled / mitigation ongoing]
**What we are doing now:**
- [forensics + mitigation + partner coordination in plain language]
**What we are still assessing:**
- [explicit unknowns]
**Next update:**
[UTC time] (we will post even if investigation is ongoing)
**Security warning:**
Do not trust any “refund” or “claim” links. We will only post official links in this channel.
```

### 3) Email to Investors / Board (Private)

```text
Subject: [PROTOCOL] — Security incident update ([UTC date/time])
We have detected suspicious on-chain activity affecting [surface] of [PROTOCOL].
Current severity (internal): [P0/P1/P2].
Confirmed facts:
- [fact 1]
- [fact 2]
Containment actions taken:
- [paused/disabled/etc]
Current impact assessment:
- Loss estimate: [unknown / bounded range / confirmed amount]
- Users affected: [unknown/estimate]
Next steps:
- [forensics timeline, exchange outreach, legal engagement if applicable]
Next investor update by: [UTC time].
```

### 4) Exchange Partner Notice (Listing / Compliance)

```text
Subject: Urgent — [PROTOCOL] security incident (Solana) — coordination request
We are responding to a security incident affecting [PROTOCOL] on Solana.
Requested action (choose):
- Please monitor and consider freezing deposits/withdrawals for the addresses below.
- Please consider a temporary trading halt for [TOKEN/TICKER] while user guidance is active.
On-chain identifiers:
- Program ID(s): [PROGRAM_IDs]
- Mint ID(s): [MINT_IDs]
- Suspected attacker address(es): [ADDRs] (confidence labeled)
Evidence:
- Signatures: [sig 1], [sig 2], [sig 3]
- Incident window: [UTC start]–[UTC end], slot range [if known]
Point of contact:
- Email: security@[domain]
- Real-time contact: [Signal/Telegram]
We can provide a fuller evidence pack on request.
```

## Critical rules the agent enforces

```text
NEVER: unverified loss totals, “funds are safe”, attribution, reproduction details, compensation promises, attacker addresses.
ALWAYS: UTC timestamp, confirmed facts only, explicit user action, next update time, one canonical updates link, anti-phishing warning.
```

---

## What NOT To Include (Even If Asked)

```text
- Reproduction steps, attribution claims, unverified numbers, compensation promises, or any “claim/refund” links that are not official and verified.
```

---

## Timing Guidance

```
0-30 min: post only if users must act; otherwise draft and prepare.
30-60 min: publish initial notice + next update time (UTC).
Every 2h: publish an update on schedule.
Post-resolution: publish a full post-mortem within 72 hours.
```
