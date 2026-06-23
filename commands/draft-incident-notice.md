# /draft-incident-notice

Generates a ready-to-post public incident notice within 2 minutes of confirmation.

## Usage

```
Run /draft-incident-notice — protocol is [NAME], we confirmed [WHAT] at [TIME UTC], we have [ACTION TAKEN], users should [WHAT TO DO NOW].
```

## Required inputs before drafting

The agent will ask for these if not provided:

1. **Protocol name** — exact name as known publicly
2. **What is confirmed** — be precise: "unusual drain from program X", "oracle manipulation detected", "unauthorized mint authority transfer". Do NOT say "hack" if not confirmed
3. **What you have done** — "paused deposits", "frozen mint", "taken site offline", "nothing yet"
4. **What users should do RIGHT NOW** — "do not deposit", "your funds in the protocol are safe", "withdraw via emergency UI at [URL]"
5. **Contact channel** — where users can ask questions (Discord #announcements, Telegram)

## The three versions the agent produces

### Version 1: X/Twitter (≤280 characters)
```
⚠️ [PROTOCOL] Security Notice

We have detected [1-line description]. 
[Action taken].
[What users should do NOW].

Updates: [Discord/Telegram link]
```

### Version 2: Discord Announcement (full)
```
@everyone 

🚨 **Security Notice — [DATE TIME UTC]**

**What we know:**
[2-3 sentences of confirmed facts only. No speculation.]

**What we have done:**
[Bullet list of containment actions taken]

**What you should do:**
[Specific, actionable instructions for users]

**What happens next:**
[Timeline for next update — be specific: "We will post an update in 2 hours"]

**Your funds:**
[Clear statement on fund safety — only if you know for certain]

For questions: [#support-channel]
Post updates: [#announcements]
```

### Version 3: Telegram (formatted)
```
⚠️ *[PROTOCOL] — Security Notice*
[Date Time UTC]

*Situation:* [1-2 sentences]
*Action taken:* [What you did]
*User action needed:* [What they should do]

Next update: [Specific time]
Questions: [Link]
```

## Critical rules the agent enforces

```
NEVER say:
  - "We were hacked" (if not confirmed — use "we detected unusual activity")
  - "All funds are SAFU" (unless you have verified on-chain that funds are protected)
  - "We will make everyone whole" (do not commit before you know the scope)
  - Specific dollar amounts you haven't verified
  - Attacker wallet addresses (tips them off before law enforcement)
  - Root cause (you don't know yet — post-mortem is later)

ALWAYS include:
  - Exact UTC timestamp of the notice
  - What users MUST do right now (even if it's "nothing, just wait")
  - When you will next update (be specific — 2 hours, not "soon")
  - Where to get updates (single channel — don't split attention)
```

## Timing guidance

```
0-15 min:   Post ONLY if you have confirmed something and users need to act
            If no user action needed: wait for more facts
            
15-30 min:  If users are asking on social media, post the minimal version:
            "We are aware of an issue and investigating. Do not interact with [X] until further notice."

30-60 min:  Full initial notice once you have enough facts to be specific

Every 2h:  Update post — even if it's just "investigation ongoing, funds remain secure"

Post-resolution: Full post-mortem within 72 hours
```
