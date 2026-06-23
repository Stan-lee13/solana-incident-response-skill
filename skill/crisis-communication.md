# Crisis Communication

> Load when you need to communicate publicly about a security incident.
> Timing, tone, and honesty are your only tools. Use them precisely.
> Load `agents/comms-director.md` for drafting assistance.

---

## The Communication Timeline

```
T+0    Exploit confirmed or strong suspicion
T+15   War room active — DO NOT post publicly yet
T+30   Initial notice posted — short, factual, user action only
T+60   First containment update
T+4h   Damage scope update (only what is confirmed)
T+24h  Technical disclosure if root cause confirmed
T+72h  If root cause still unclear — post that explicitly
T+7d   Full post-mortem published
```

Do not compress this timeline to look responsive. Incorrect early information destroys trust faster than a delayed accurate statement.

---

## Stage 1: Initial Notice (T+30 — 2 minutes to draft)

### What you need before drafting:
1. Is this confirmed or suspected? (confirmed = you saw funds move)
2. What user action is needed RIGHT NOW?
3. What have you done so far (paused, frozen, nothing)?

### X/Twitter Template (≤280 characters)
```
🚨 Security Notice — [PROTOCOL] [TIME UTC]

We've detected unusual activity on our protocol and are investigating.

[ACTION TAKEN if any: "Deposits suspended" / "Protocol paused"]

Please do not interact with [PROTOCOL] until further notice.

Updates every hour: [discord link]
```

### Discord Template
```
@everyone

🚨 **Security Notice | [DATE TIME UTC]**

We have identified unusual activity on our protocol and are actively investigating.

**What we have done:** [Protocol paused / Deposits suspended / Nothing yet — investigating]

**What you should do right now:**
→ Do not deposit or interact with the protocol
→ [OPTIONAL: "You can withdraw via [EMERGENCY URL]" — only if safe]
→ Follow this channel for updates

**What we do NOT know yet:** The full scope of the impact. We will not speculate.

Next update by **[SPECIFIC TIME UTC]**.

Questions: [#incident-support channel]
```

---

## Stage 2: Containment Update (T+60 minutes)

```
**Update 2 — [PROTOCOL] Security Incident | [TIME UTC]**

**Containment status:**
[The exploit has been stopped — program is paused]
OR [We are still actively containing the situation]
OR [The attack appears complete — no further funds at risk]

**What we know:**
• [Specific confirmed fact]
• [Specific confirmed fact]
• [What we are still investigating — be explicit]

[IF SCOPE CONFIRMED:]
Approximately [AMOUNT] in [TOKEN(S)] was affected across [NUMBER] accounts.

[IF SCOPE NOT CONFIRMED:]
We are still assessing the full scope. We will not speculate on amounts.

**Security assistance:** [We have engaged [FIRM] to assist] OR [Our team is handling investigation]

Next update by **[SPECIFIC TIME + 2h UTC]**.
```

---

## Stage 3: Technical Disclosure (T+24h)

Only post this when you can fill every field with confirmed information.

```
**Full Technical Disclosure — [PROTOCOL] Incident | [DATE UTC]**

**SUMMARY**
On [DATE] at [TIME UTC], our protocol was exploited. [AMOUNT] was extracted 
from [AFFECTED COMPONENT] via [1 SENTENCE NON-TECHNICAL DESCRIPTION].

**WHAT HAPPENED — Non-Technical**
[2-3 sentences readable by non-engineers. What users experienced.]

**WHAT HAPPENED — Technical**
The exploit targeted [INSTRUCTION NAME]. [SPECIFIC TECHNICAL DESCRIPTION — which 
account validation was missing or bypassable, what the attacker did with it].

Vulnerable code: [GITHUB LINK TO THE FIXED COMMIT if safe to share]

**TIMELINE (All UTC)**
[TIME]: First exploit transaction confirmed [SIGNATURE short]
[TIME]: Team notified
[TIME]: Program paused
[TIME]: Attack stopped
[TIME]: Root cause identified
[TIME]: Fix deployed

**IMPACT**
- Funds affected: [AMOUNT TOKEN] ($[USD at time])
- User accounts: [NUMBER]
- Unaffected: [What was NOT drained — if relevant]

**WHAT WE ARE DOING**
• [Specific action 1]
• [Specific action 2]

**COMPENSATION**
[See compensation section below — only include if ready to commit]

Full post-mortem: [date they can expect it]
```

---

## Stage 4: Security Researcher Disclosures

### Pre-exploit Report (Responsible Disclosure)

If a researcher contacts you BEFORE an exploit:

```typescript
// Your security@protocol.com auto-response (configure this NOW, not during incident)
const RESPONSIBLE_DISCLOSURE_AUTORESPONSE = `
Thank you for your security report.

We are treating this seriously and will review within 24 hours.

Please send full technical details to security@[protocol].com with:
- Affected program/instruction
- Steps to reproduce
- Estimated impact

Please do not disclose publicly while we investigate. We have a responsible disclosure 
program and will respond appropriately to validated, previously unreported vulnerabilities.

You will hear from our team directly at the email you provide.
`;
```

Bounty response tiers (establish these BEFORE an incident, post them publicly):
```
Critical (funds at risk, exploitable on mainnet):  $25,000 – $250,000
High (significant logic flaw, requires conditions): $5,000 – $25,000  
Medium (non-fund-impacting security issue):         $1,000 – $5,000
Low (best practices issue):                         $500 – $1,000

Submit: security@[protocol].com or [Immunefi / Hacken program link]
```

### Post-exploit Whitehat Contact

If a whitehat drained funds to "protect" them (this is legally complex — coordinate with legal counsel BEFORE responding publicly):

```
On-chain memo to whitehat wallet:
"We believe you may have protected funds from [PROTOCOL]. 
Please contact security@[protocol].com. 
We want to work with you to return these to affected users. 
This is confidential communication."

Public post (while negotiating, do NOT confirm amounts or details):
"We are aware of certain transactions from [APPROXIMATE DATE] 
that may have been protective in nature. We are in communication 
with the relevant parties. More information when we can confirm details."
```

### Attacker Bounty Negotiation

If the attacker contacts you offering partial return:

**Before responding:**
1. Get legal counsel on the call
2. Confirm the attacker actually has the funds (on-chain verification)
3. Set a realistic ceiling: returning 85% is better than recovering 0%

**Holding statement while negotiating:**
```
"We are aware of communications from wallets involved in this incident.
We are working with legal counsel and are unable to comment further at this time."
```

**Do NOT:**
- Agree to "no prosecution" — that is not your unilateral decision
- Post negotiation amounts publicly while in progress
- Threaten on social media (undermines negotiation leverage)
- Let the negotiation run more than 72 hours without a clear progress signal

---

## Anti-Patterns From Real Incidents

| Incident | Mistake | Cost |
|----------|---------|------|
| Wormhole (2022) | 3 hours of silence | Community assumed total loss, panic withdrew from related protocols |
| Anonymous protocol | Posted "SAFU" while drain was ongoing | Lost all remaining community trust permanently |
| Mango Markets | Public infighting over attacker negotiation | Decision-making visible to attacker, weakened position |
| Multiple protocols | Deleted initial incorrect post | Screenshots everywhere — worse than correction |
| Infrastructure protocol | Named individual attacker without confirmation | Legal liability, turned out to be wrong wallet attribution |
| DeFi protocol 2025 | First post was 14 hours after incident | Community found out via blockchain explorers first — trust never recovered |

---

## Channel Priority Order

Post in this order — do not skip channels:

```
1. X/Twitter (most discoverable, sets the public record)
2. Discord #announcements (where your users actually are)
3. Telegram (if you have an active Telegram community)
4. Website status page (https://status.yourprotocol.com — set this up now)
5. Email list (if you have one — slower but important for less active users)

Channels you should NOT post during active incident:
❌ Founders' personal Twitter accounts (creates inconsistency)
❌ Discord general/trading channels (noise, hard to pin)
❌ Reddit (too slow for incident communication)
```

---

## AMA Preparation (Post-mortem community call)

Run this 3-7 days after the incident, once you have the full post-mortem published.

```
PREPARATION (24h before AMA):
  [ ] Compile list of 20 most common community questions from Discord/X
  [ ] Prepare written answers to all of them — read them live, don't ad-lib
  [ ] Have technical lead and one other team member present
  [ ] Pre-answer the 5 hardest questions in writing (compensation, timeline, what went wrong)
  [ ] Designate a moderator — they filter questions, you answer
  
DURING AMA:
  [ ] Start by reading the summary of the post-mortem (2-3 minutes)
  [ ] Take questions in this order: user impact → technical cause → compensation → future
  [ ] It is OK to say "I don't know" — it is not OK to speculate
  [ ] Record it — publish the recording

QUESTIONS YOU WILL BE ASKED (prepare these specifically):
  1. "Why did this happen? Was it carelessness?"
     → Specific technical answer. No hedging.
  2. "Will I be compensated? When?"
     → Only answer if you have confirmed the compensation plan.
  3. "Why should I trust you again?"
     → Specific changes made. External audit results. New controls.
  4. "Who is responsible?"
     → Own responsibility as a team. Do not name individuals.
  5. "Are my funds safe now?"
     → Answer with evidence (audit report, verified build, new architecture) not just "yes."
```
