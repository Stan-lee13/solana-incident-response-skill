# Crisis Communication

> Load this skill when you need to communicate publicly about a security incident.
> Timing, tone, and honesty are your only tools. Use them precisely.

---

## The Communication Timeline

```
T+0    Exploit confirmed
T+15   Internal war room active, DO NOT post publicly yet
T+30   Initial notice posted (template below) — brief, factual, no speculation
T+60   First update posted — containment status
T+4h   Second update — damage assessment, what you know
T+24h  Full disclosure — attack vector explained (if safe to disclose)
T+7d   Full post-mortem published
```

Do not compress this timeline to look responsive. Incorrect information in a crisis is worse than silence.

---

## Initial Notice (T+30 Template)

Post this on X/Twitter and your official Discord within 30 minutes of confirming the exploit.
Do not wait until you understand everything. Do not speculate.

```
🚨 Security Notice — [PROTOCOL NAME]

We have identified unusual activity on our protocol and are currently 
investigating.

As a precaution, we have [paused the protocol / suspended deposits / 
taken emergency measures].

User funds: [We are actively assessing the situation.]

We will post updates as we have confirmed information.

Please do not interact with the protocol until further notice.

[TIMESTAMP UTC]
```

*What to include:*
- What you know (unusual activity)
- What action you took (if any)
- Clear instruction to users (do not interact)
- Commit to updates

*What NOT to include:*
- Speculation about attack vector
- Dollar amounts (until confirmed)
- Assurances you cannot keep ("funds are safe")
- Accusations or naming of individuals

---

## 60-Minute Update (T+60 Template)

```
Update 2 — [PROTOCOL NAME] Security Incident — [TIME UTC]

Containment status: [The protocol has been paused / We are working to contain 
the exploit / Deposits and withdrawals are suspended]

What we know:
- [Factual statement 1]
- [Factual statement 2]
- [What is not yet confirmed]

We have engaged [security firm if applicable] to assist with the investigation.

Our team is working around the clock. Next update in [X hours].

[TIMESTAMP UTC]
```

---

## Damage Assessment Update (T+4h Template)

```
Update 3 — [PROTOCOL NAME] Security Incident — [TIME UTC]

We now have a clearer picture of the incident.

Amount affected: [Be precise — e.g., "approximately $X in [TOKEN]"]
User funds affected: [Describe which funds, which pools, which users]

Protocol status: [Paused / Under review / Safe to use for X but not Y]

Investigation: Our team and [SECURITY FIRM] have identified the [general 
category of vulnerability, e.g., "a logic error in our [COMPONENT]"]. 
We will share full technical details in our post-mortem.

What we are doing:
- [Action 1 — e.g., "Working with exchanges to flag attacker wallets"]
- [Action 2 — e.g., "Assessing recovery options for affected users"]
- [Action 3 — e.g., "Preparing a full disclosure"]

We understand this is deeply concerning. We are committed to full transparency.

[TIMESTAMP UTC]
```

---

## Sensitive Communication Rules

### What you cannot legally say

*Do not promise a specific recovery percentage* until you have the funds and a legal framework to deliver it. Promising 100% recovery when you cannot deliver it creates personal liability for founders.

*Do not name the attacker publicly* unless you have confirmed identity. Calling the wrong person an attacker is defamatory.

*Do not discuss active law enforcement cooperation publicly* until law enforcement instructs you to. It can compromise an investigation.

*Do not delete posts.* Every deletion is captured. Deletion signals dishonesty and will be used against you.

### What builds trust

Posting updates even when you have nothing new: "We have no new information but are still actively working."

Acknowledging failure directly: "This happened because of a bug in our code. We take full responsibility."

Specific timelines: "We will post our full post-mortem by [DATE]. If we are delayed, we will say why."

---

## Communicating with Affected Users

For protocols with identifiable affected wallets, direct communication is required.

```typescript
// If you can identify affected wallets via on-chain data
// Use Helius to build the affected user list
const response = await fetch(
  `https://api.helius.xyz/v0/addresses/${PROGRAM_ID}/transactions?api-key=${HELIUS_KEY}&limit=1000`
);

// Then communicate via:
// 1. Your frontend — banner for affected wallets when they connect
// 2. Email (if you collected emails)
// 3. On-chain memo to affected wallets (serious, but done in major incidents)
```

---

## Discord Moderation During a Crisis

Your Discord will be flooded with fear, speculation, and sometimes attackers spreading disinformation.

*Immediate actions:*
- Slow mode: 60 seconds minimum in all channels
- Disable external invites temporarily
- Pin your official statement at the top of #announcements
- Assign 2+ mods to monitor 24/7
- Do not delete negative messages — it inflames the situation

*What your mods should say:*
"The team is aware and actively working. Please refer to the pinned announcement for official updates. We will not respond to DMs about compensation at this time."

*What your mods should NOT say:*
- Anything about amounts or causes before official announcement
- Promises on behalf of the team
- Speculation of any kind

---

## Media & External Inquiries

If journalists contact you:

"We have issued a public statement. We are not providing additional comment while the investigation is ongoing. We will publish a full post-mortem by [DATE]."

Designate ONE person as the media contact. All inquiries route to that person only.

---

## The White Hat Contact Post

If you believe the attacker may be a white hat, post this publicly after your initial notice:

```
🤝 To the individual(s) who exploited [PROTOCOL]:

If you acted as a security researcher or are willing to negotiate, 
please contact us at: security@[DOMAIN].com

We offer a bounty of [10% of funds] for the return of user funds. 
We are committed to a fair resolution.

[72-hour window]
```

---

## Post-Resolution Communication

Once the incident is resolved:

```
✅ [PROTOCOL NAME] — Incident Resolved — [DATE UTC]

We are pleased to confirm that [outcome — e.g., "the protocol has been 
secured and will resume operations on [DATE]"].

Summary:
- Amount lost: [exact amount]
- Recovery: [exact amount recovered, if any]
- User compensation plan: [details]
- Timeline to relaunch: [date]

Our full post-mortem will be published on [DATE]. It will include the 
complete technical breakdown, our response timeline, and the changes we 
are making.

Thank you for your patience. We are sorry this happened.
```

---

## Transition Points

- Incident is contained, need to write the full technical breakdown → `skill/post-mortem-analysis.md`
- Need to rebuild and relaunch → `skill/hardened-redeployment.md`
- Legal obligations and reporting requirements → `skill/legal-regulatory-response.md`
