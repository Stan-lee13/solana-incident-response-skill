# Legal & Regulatory Response

> Load this skill for legal obligations, law enforcement coordination,
> insurance claims, and user compensation frameworks following a security incident.

---

## IMPORTANT DISCLAIMER

This skill provides general frameworks based on publicly known DeFi incident precedents.
It is NOT legal advice. Engage a qualified attorney within 24 hours of a confirmed incident
involving material user funds. Jurisdiction matters enormously.

---

## Immediate Legal Actions (First 24 Hours)

### Engage counsel NOW

If your protocol has lost user funds exceeding $100K, you need a lawyer within 24 hours.
Not because you have done something wrong — because every statement you make publicly
and every action you take on-chain may become evidence.

Firms with DeFi incident experience:
- Debevoise & Plimpton: https://www.debevoise.com — major protocol incidents
- Willkie Farr: https://www.willkie.com — crypto enforcement experience
- Fenwick & West: https://www.fenwick.com — crypto-native firm
- DLx Law: https://dlxlaw.com — DeFi specialist
- Kelman Law: https://www.kelman.law — DeFi regulatory

### Document preservation

Your counsel will tell you this immediately — we are telling you now.

*Do NOT delete:*
- Server logs
- Discord/Telegram messages
- Internal communications about the vulnerability (even if embarrassing)
- Any code review discussions
- Smart contract deployment history
- Audit communications

*Do preserve:*
- Screenshots of all on-chain attack transactions
- Records of when team members were notified
- Records of every action taken and when
- All communications with security researchers

---

## Reporting Obligations by Jurisdiction

### United States

*FinCEN — Money Services Business obligations*
If your protocol qualifies as a MSB (money transmission, exchange), you may have a Suspicious Activity Report (SAR) filing obligation within 30 days.

*SEC*
If any lost tokens may be deemed securities: contact counsel immediately. SEC has increased DeFi enforcement in 2025-2026.

*CISA notification*
Not required for most DeFi protocols, but recommended for incidents affecting critical infrastructure.

*State-level*
New York: BitLicense holders have specific breach notification requirements
California: CCPA data breach notifications if personal data affected

### European Union

*MiCA (Markets in Crypto-Assets) — Effective 2024*
If your protocol has MiCA registration:
- Notify your competent authority within 24 hours of awareness of a significant incident
- Provide full report within 72 hours
- User notification required if funds affected

Article 23 MiCA: significant operational incidents must be reported to the competent authority (national financial regulator).

### United Kingdom

FCA-regulated entities: notify the FCA within 24 hours.
Non-regulated DeFi: no mandatory reporting, but engage counsel on civil liability exposure.

### FATF / International

If the attacker is moving funds cross-border, coordinate with:
- Financial Intelligence Units of relevant countries
- INTERPOL Financial Crimes: https://www.interpol.int/Crimes/Financial-crime
- The Egmont Group (for cross-border coordination)

---

## Law Enforcement Engagement

### When to contact law enforcement

Contact law enforcement if:
- Funds stolen exceed $250K
- You have identified the attacker's real-world identity
- The attacker is moving funds to exchanges (time-sensitive)
- You have received threats or extortion demands

Do NOT wait to "see if funds are returned" before contacting law enforcement. Early engagement preserves options.

### How to contact law enforcement

*United States — FBI*
- IC3 (Internet Crime Complaint Center): https://ic3.gov
- FBI Cyber Division field office: https://www.fbi.gov/contact-us/field-offices
- For urgent cases with active fund movement: call your local FBI field office directly

*United States — Secret Service*
The USSS Electronic Crimes Task Force handles financial cybercrime:
https://www.secretservice.gov/investigation/cyber

*Europol*
For incidents affecting EU users or with attacker in EU:
https://www.europol.europa.eu/report-a-crime/report-cybercrime-online

*Chainalysis*
Working with law enforcement directly on blockchain analytics:
https://www.chainalysis.com/chainalysis-crypto-incident-response/
Chainalysis has relationships with law enforcement globally and can act as a bridge.

### What to prepare for law enforcement

```
LAW ENFORCEMENT BRIEFING DOCUMENT

Incident Summary:
- Protocol name and description
- Date/time of incident (UTC)
- Estimated loss amount
- Attack description (non-technical summary)

Technical Evidence:
- Attack transaction signatures (list all)
- Attacker wallet addresses (all identified)
- Fund movement trace (as far as you can trace)
- Smart contract addresses

Organization Information:
- Entity name and registration (if any)
- Registered address
- Contact person and legal counsel details

Affected Users:
- Number of affected users (approximate)
- Total user funds at risk
- Any known user information
```

---

## Insurance Claims

### DeFi Coverage Options

*Nexus Mutual*
Smart contract cover for protocol hacks.
- File claim: https://app.nexusmutual.io/claims
- Required: proof of exploit, transaction evidence, claim narrative
- Timeline: 30-90 days for assessment

*InsurAce*
Multi-chain DeFi coverage.
- File claim: https://app.insurace.io/Claims
- Required: exploit evidence, post-mortem report
- Timeline: 14-30 days

*Sherlock*
Protocol coverage with independent adjudication.
- If your protocol was audited by Sherlock: https://app.sherlock.xyz/protocols
- Required: exploit details, audit scope confirmation
- Timeline: ~72 hours for initial assessment

*Risk Harbor*
Parametric coverage for specific event types.
- https://www.riskharbor.com

### What insurers need from you

```
INSURANCE CLAIM DOCUMENTATION

1. Policy information
   - Policy number / coverage agreement
   - Covered protocol addresses

2. Incident documentation
   - Date and time of exploit
   - Nature of exploit (matching covered categories)
   - Transaction signatures proving the loss

3. Financial impact
   - Total funds lost (with on-chain proof)
   - Market prices at time of incident
   - Affected user count

4. Technical evidence
   - Smart contract addresses
   - Audit report showing the vulnerability was in audited code
   - Post-mortem report

5. Response actions
   - Timeline of your incident response
   - Actions taken to mitigate
```

---

## User Compensation Frameworks

### Option 1 — Treasury-funded compensation

If the protocol has reserves:

```
User compensation framework:
- Snapshot block: [BLOCK NUMBER immediately before exploit]
- Eligible users: all wallets with positive balances at snapshot
- Compensation ratio: [X]% of affected balance
- Distribution method: airdrop to affected wallets
- Distribution timeline: [DATE]
- Claim process: [none required / users must claim / automatic]
```

### Option 2 — Token issuance (debt tokens)

Used by Bitfinex ($72M hack, 2016), later redeemed at par:

```
Emergency debt token framework:
- Issue [PROTOCOL]-DEBT tokens at 1:1 with affected amounts
- Commit to buyback schedule from protocol revenue
- Make debt tokens tradeable so users can exit at market price
- Publish quarterly redemption reports
```

### Option 3 — Protocol revenue share

Used by Mango Markets and others:

```
Revenue-sharing compensation:
- X% of protocol fees allocated to compensation fund
- Distribute proportionally to affected users monthly
- Publish fund balance publicly
- Estimated full compensation in [X] months at current revenue
```

### Option 4 — Governance-voted compensation

Submit a governance proposal:

```
Template governance proposal:

TITLE: Emergency Compensation Fund — [INCIDENT DATE]

SUMMARY:
On [DATE], [PROTOCOL] was exploited for [AMOUNT]. This proposal establishes
a compensation framework for affected users.

AMOUNT: [TOTAL COMPENSATION AMOUNT]
SOURCE: [Treasury / New token issuance / Revenue allocation]

DISTRIBUTION:
Snapshot: Block [BLOCK_NUMBER]
Eligible: [CRITERIA]
Method: [Pro-rata / Fixed / Capped]
Timeline: [DATE]

RATIONALE:
[Why this amount and method is fair to both affected users and the protocol's sustainability]

VOTE:
FOR: Approve compensation as described
AGAINST: Reject this proposal
ABSTAIN
```

---

## Handling Extortion / Ransom Demands

If the attacker demands payment for silence or fund return:

*Do:*
- Contact law enforcement immediately
- Consult legal counsel before any response
- Document every communication
- Do not publicly acknowledge ransom demand

*Do not:*
- Pay ransom without legal advice (it may constitute sanctions violation if attacker is sanctioned)
- Make promises in writing
- Engage in negotiation without legal counsel
- Ignore it

---

## Limitation of Liability Considerations

Review your terms of service immediately:

*Check:*
- Does your ToS limit protocol liability?
- Does it include a security/hack exclusion?
- Does it specify governing jurisdiction?
- Was it properly displayed to users?

If your ToS does not address hacks/exploits, your legal exposure may be significantly higher. This is a redeployment hardening item.
