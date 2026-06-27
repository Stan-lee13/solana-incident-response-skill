# /draft-incident-notice

Generate controlled public and private incident notices for Solana protocol incidents.

> Always ask: **Is this for internal use or public posting?** Public drafts must not reveal exploit mechanics, attacker identity, exact vulnerable instruction paths, or unverified loss figures.

## Usage

Run `/draft-incident-notice` after the Incident Commander classifies severity and the Comms Director owns the message queue.

## Required Inputs

Ask these 4 questions in one message.
```text
1) WHAT HAPPENED?
   - unusual activity / confirmed exploit / oracle manipulation / governance issue / frontend compromise
   - first known UTC time and slot if verified
2) WHAT IS AFFECTED?
   - program ID, pools, vaults, mint, frontend, integrations
   - user funds, treasury funds, token supply, or trading markets
   - what is explicitly NOT affected, if verified
3) WHAT HAS BEEN DONE?
   - paused program / disabled UI / froze mint / contacted exchanges / preserved evidence
   - containment status: ongoing / contained / unknown
4) WHAT SHOULD USERS DO?
   - do not interact with UI / do not deposit / revoke approvals if relevant / watch official channels / no action needed
```

If unknown, write `under investigation` instead of guessing.
## Legal and Security Red Lines

Do NOT include: exploit instruction names, account ordering details, seeds, bumps, CPI chain, Anchor constraint gaps; attacker addresses before exchange/legal coordination; unverified loss amounts; reimbursement, bounty, immunity, or legal promises; “funds are safe” without approval; blame; or “fixed” before review.

Use `unusual activity` until confirmed, `affected component` instead of exact vulnerable path, `scope is being assessed`, and `next update by [UTC]`.

## Output 1 — Twitter/X Thread

```text
1/ SECURITY UPDATE | [PROTOCOL]
We have detected [unusual activity / a security incident] affecting [component]. Out of caution, users should [USER_ACTION]. Investigation is underway. Next update by [TIME UTC].

2/ Current scope: [AFFECTED_COMPONENTS]. Unaffected, based on current verification: [UNAFFECTED_COMPONENTS or "still being assessed"]. We will not share technical details until users are protected.

3/ Actions taken:
- [PAUSE / UI DISABLED / EXCHANGES CONTACTED]
- [FORENSICS STARTED]
- [MONITORING ACTIVE]
Rely only on this account and official Discord/status page.

4/ User guidance:
- [DO_NOT_INTERACT / NO_ACTION_NEEDED]
- Do not trust DMs claiming to be support.
- Do not click claim/refund links unless posted through official channels.
We will never ask for your seed phrase.

5/ Next update: [TIME UTC]. A full post-mortem will be published after containment, forensics, and remediation review are complete.
```

## Output 2 — Discord Announcement

```text
@everyone

Security update for [PROTOCOL]

We are investigating [unusual activity / a security incident] affecting [AFFECTED_COMPONENTS].

What users should do now:
- [USER_ACTION]
- Do not click DMs or unofficial links.
- Use only [OFFICIAL_STATUS_URL] and this channel.

Actions already taken:
- [ACTION_1]
- [ACTION_2]
- [ACTION_3]

Current status: [ONGOING / CONTAINED / ASSESSING]
Next update: [TIME UTC]
```

## Output 3 — Investor Email

```text
Subject: [PROTOCOL] Security Incident Update — [DATE UTC]

Team,

We are managing a [SEVERITY] security incident involving [AFFECTED_COMPONENTS]. It was first detected at [TIME UTC / SLOT] and is currently [ONGOING / CONTAINED / UNDER ASSESSMENT].

Verified facts:
- Affected: [AFFECTED]
- Not affected, if verified: [UNAFFECTED]
- User action: [USER_ACTION]
- Containment actions: [ACTIONS_TAKEN]
- External notifications: [EXCHANGES / PARTNERS / NONE YET]

No root-cause details or loss estimates until on-chain forensics confirms them.

Next investor update: [TIME UTC]
Point of contact: [NAME / EMAIL / SIGNAL]
```

## Output 4 — Exchange Partner Notice

```text
Subject: [URGENT] [PROTOCOL/TOKEN] Security Incident — Requesting [deposit pause / withdrawal pause / trading halt]

Security team,

We are contacting you regarding a security incident affecting [TOKEN_SYMBOL] / [MINT_ADDRESS] / [PROGRAM_ID].

Request: please [REQUESTED_ACTION] for [TOKEN_SYMBOL or affected integration] while we complete containment and forensics.

Verified details:
- Incident onset: [TIME UTC], slot [SLOT]
- Affected asset/program: [DETAILS]
- Known suspicious signatures: [SIGS]
- Known suspicious addresses: [ADDRESSES, if cleared for private sharing]
- Current status: [ONGOING / CONTAINED / ASSESSING]

Please confirm receipt and provide a ticket number.
Incident contact: [NAME / ROLE / EMAIL / SIGNAL]
```

## Approval Checklist

- [ ] Incident Commander approved severity and scope language.
- [ ] Forensic Investigator approved on-chain claims.
- [ ] Legal reviewed material loss, user impact, or exchange halt language.
- [ ] Comms Director verified formatting and next-update time.
- [ ] No exploit mechanics, unverified figures, attacker attribution, or unsafe links.

## Final Output Format

```text
1) TWITTER/X THREAD
2) DISCORD ANNOUNCEMENT
3) INVESTOR EMAIL
4) EXCHANGE PARTNER NOTICE
LEGAL EXCLUSIONS APPLIED:
- [items intentionally omitted]
APPROVALS NEEDED BEFORE POSTING:
- [Incident Commander / Forensics / Legal / Exchange team]
```
