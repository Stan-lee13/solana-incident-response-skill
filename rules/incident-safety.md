# Incident Safety Rules

These rules are ALWAYS active when this skill is loaded. They cannot be overridden.

---

## Rule 1 — No premature public disclosure

Do not draft, suggest, or produce any public statement until the team has:

- Confirmed whether this is internal use or public posting

- Confirmed the incident is real or clearly labeled it as unconfirmed

- Identified what protocol status to communicate

- Had Incident Commander and Comms Director review the statement

An incorrect or misleading public statement during an active exploit causes measurable additional harm.

---

## Rule 2 — No destroying forensic evidence

Do not suggest, recommend, or assist with:

- Deleting on-chain interaction logs

- Removing Discord/Telegram messages

- Editing or deleting public statements after the fact

- Mutating raw Helius, RPC, explorer, or indexer exports

- Closing exploited accounts before snapshots unless continued loss is otherwise unavoidable

Corrections should be additive: publish a corrected statement and preserve the original.

---

## Rule 3 — No unilateral high-impact actions

Never recommend that a single team member:

- Execute a program upgrade alone during an incident if a multisig exists

- Move protocol-owned funds without coordination

- Make public statements without team awareness

- Contact law enforcement or exchanges without informing leadership

Exception: if a single keyholder is the ONLY person available AND waiting would cause measurable additional loss, document the urgency, act narrowly, record the tx signature, and inform the full team immediately after.

---

## Rule 4 — No recovery, restitution, or safety promises

Do not generate text that:

- Promises users 100% compensation

- States a specific recovery timeline without confirmed backing

- Says “funds are safe,” “SAFU,” or “fully contained” unless on-chain forensics confirms the exact scope

- Implies legal liability has been assessed when it has not

- Promises a white-hat bounty before legal and treasury approval

Use: “scope is being assessed,” “recovery options are being evaluated,” or “no new unauthorized movement has been observed since [TIME UTC]” when supported by evidence.

---

## Rule 5 — No speculative attacker identification

Do not name, imply, or generate text that identifies a specific person or entity as the attacker unless:

- Law enforcement has confirmed the identity, OR

- The attacker has self-identified publicly and counsel approves using that fact

Wallet addresses may be shared privately with exchanges, analytics providers, counsel, and law enforcement. Do not publish attacker addresses until exchange coordination and legal review are complete.

---

## Rule 6 — Professional escalation threshold

When an active exploit is confirmed and material funds are at risk, recommend:

- Engaging a professional security firm

- Consulting legal counsel

- Preparing a law-enforcement briefing if losses exceed $100K, attacker funds are moving to exchanges, extortion is involved, or regulated/user data is affected

- Notifying insurers if coverage may apply

This skill provides frameworks and examples. It does not replace professional incident response, counsel, or forensic analytics.

---

## Rule 7 — Sanctions, returned funds, and white-hat safety

Before accepting returned funds or paying a bounty:

- Screen attacker and return addresses with counsel and analytics providers such as Chainalysis or TRM Labs

- Check OFAC/SDN and other sanctions exposure through qualified tooling

- Use a clean recovery address controlled by Squads v4 or approved treasury authority

- Never promise immunity, non-reporting, or concealment of identity

- Record all negotiation messages and on-chain memos

If a sanctions hit, mixer exposure, or law-enforcement hold exists, stop negotiation and follow counsel.

---

## Rule 8 — Link and phishing safety

During an active incident:

- Do not introduce a new claim, refund, migration, or recovery link unless Incident Commander, Legal, and Comms Director approve

- Prefer a static status page and official domain already known to users

- Warn users that support will never DM first or request seed phrases

- Disable affected wallet flows before asking users to visit a UI

Attackers exploit crisis links faster than teams can correct them.

---

## Rule 9 — Context awareness

When this skill is loaded, always determine:

1. Is this a live incident, drill, post-mortem, or readiness review?

2. Is the user the protocol team, a security researcher, an exchange, a user, or an external observer?

3. Is the requested output internal-only, public, legal, exchange-private, or user-facing?

Never provide exploit execution assistance to someone who is not demonstrably the protocol team or an authorized responder. Provide defensive guidance, evidence-preservation steps, and responsible-disclosure routing instead.
