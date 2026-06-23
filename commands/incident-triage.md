# /incident-triage

Classifies severity and generates an immediate action list in under 3 minutes.

## How to Use

Answer the 5 questions below. The agent produces:
1. A severity rating (CRITICAL / HIGH / MEDIUM / LOW)
2. The exact files to load right now
3. A numbered action list with real commands — not generic advice

---

## The 5 Questions

```
1. CONFIRMATION STATUS
   [ ] Confirmed — I see funds moving to an unknown wallet on Solscan/Helius
   [ ] Suspected — I see anomalous transactions but cannot confirm fund loss
   [ ] Unclear — someone reported it but I haven't verified

2. SCOPE
   [ ] Under $10K
   [ ] $10K – $100K  
   [ ] $100K – $1M
   [ ] Over $1M
   [ ] Unknown — still assessing

3. ATTACK STATUS
   [ ] Ongoing — program is still accepting transactions, drain is continuing
   [ ] Complete — attack appears finished
   [ ] Unknown

4. CONTROLS AVAILABLE (check all that apply)
   [ ] Anchor emergency pause instruction in program
   [ ] Upgrade authority — single keypair (I have it)
   [ ] Upgrade authority — Squads multisig (N of M signers)
        If multisig: How many signers are reachable RIGHT NOW? ___
   [ ] Freeze authority on token mint
   [ ] Program was deployed with no upgrade authority (immutable)
   [ ] None of the above

5. TEAM STATUS
   [ ] Core team (≥3 people) available now
   [ ] 1-2 people available
   [ ] Founder only
   [ ] Team is asleep / unreachable
```

---

## Severity Classification

| Confirmed? | Ongoing? | Amount | Severity |
|------------|----------|--------|----------|
| Yes | Yes | Any | **CRITICAL** |
| Yes | No | >$100K | **HIGH** |
| Yes | No | <$100K | **HIGH** |
| Suspected | Yes | Any | **HIGH** |
| Suspected | No | Any | **MEDIUM** |
| Unclear | Any | Any | **MEDIUM** |

---

## CRITICAL — Immediate Action List

**Time budget: 5 minutes to execute steps 1-4**

```
[0:00] WAKE EVERYONE — Send this exact message to all team:
  "SECURITY INCIDENT. Join [CHANNEL] NOW. Do not post publicly.
   Call [NAME] if no response in 2 minutes: [PHONE]"

[0:30] LOAD IMMEDIATELY:
  → skill/active-exploit-response.md
  → skill/program-freeze-and-pause.md
  → agents/incident-commander.md

[1:00] FORENSIC SNAPSHOT — Run before any state changes:
  solana account [PROGRAM_ID] --output json > snapshot_$(date +%s).json
  curl "https://api.helius.xyz/v0/addresses/[PROGRAM_ID]/transactions?api-key=[KEY]&limit=50" > txs_$(date +%s).json

[2:00] START FREEZE — Load program-freeze-and-pause.md
  If pause instruction exists: invoke it NOW
  If Squads multisig: open squads.so and start emergency proposal NOW
  If single keypair: anchor run emergency-pause -- --provider.cluster mainnet-beta

[3:00] START LIQUIDITY MIGRATION in parallel:
  → Load skill/liquidity-migration.md
  → Begin emergency-drain.ts for direct token accounts

[5:00] POST INITIAL NOTICE — Load crisis-communication.md Stage 1 template
  DO NOT post until you have something confirmed to say
  Minimum viable post: "Unusual activity detected. Please do not interact. Updates soon."

LOAD FOR COMMS: agents/comms-director.md
LOAD FOR FORENSICS: agents/forensic-investigator.md
```

---

## HIGH — Immediate Action List

```
[0:00] ASSEMBLE TEAM — Notify core team (not urgent wake, but within 10 minutes)

[2:00] FORENSIC SNAPSHOT:
  solana account [PROGRAM_ID] --output json > snapshot_$(date +%s).json
  
  And capture the suspicious transactions:
  solana transaction [SUSPICIOUS_SIG] --output json > tx_evidence_$(date +%s).json

[5:00] LOAD:
  → skill/anomaly-detection.md (if not yet confirmed)
  → skill/active-exploit-response.md (if confirmed)
  → agents/forensic-investigator.md

[10:00] ASSESS CONTROLS:
  solana program show [PROGRAM_ID] --url mainnet-beta
  Note: Is it upgradeable? Who has upgrade authority?

[15:00] DECISION POINT:
  - If you can confirm the attack vector: proceed to freeze
  - If still unclear: increase monitoring, set 30-minute re-evaluation
  
[20:00] PREPARE COMMUNICATIONS — Do not post yet, but have draft ready
  Load: agents/comms-director.md
```

---

## MEDIUM — Immediate Action List

```
[0:00] ASSIGN ONE TECHNICAL TEAM MEMBER to investigate

[5:00] LOAD:
  → skill/anomaly-detection.md

[10:00] MANUAL TRANSACTION REVIEW:
  Open: https://solscan.io/account/[PROGRAM_ID]#txs
  Look at last 50 transactions:
  - Any unknown wallets with multiple failed attempts?
  - Any unusual instruction combinations?
  - Any accounts being drained?

[20:00] HELIUS ALERT SETUP (if not already running):
  Set up webhook for your program address
  Alert threshold: 10x normal transaction volume
  
[30:00] BRIEF LEADERSHIP — Low key, factual
  "We see [SPECIFIC THING]. Monitoring. Will re-evaluate in 1 hour."

[60:00] ESCALATION CHECK — Has the situation changed? If yes → re-run triage
```

---

## Severity Self-Check

After running triage, verify you classified correctly:

```
If you classified MEDIUM but any of these are true → upgrade to HIGH:
  - The same wallet is now running successful transactions (not just probes)
  - Any token balance in your program has decreased unexpectedly
  - You received a report from a user that their funds are missing
  - The pattern matches a known attack type from anomaly-detection.md

If you classified HIGH but any of these are true → upgrade to CRITICAL:
  - Funds are actively moving to an external wallet right now
  - The attack is still ongoing and you have not paused
  - Over $100K has been confirmed lost
```

---

## After Triage is Complete

| Severity | Next files to load |
|----------|--------------------|
| CRITICAL | `active-exploit-response.md` → `program-freeze-and-pause.md` → `liquidity-migration.md` |
| HIGH | `active-exploit-response.md` → `anomaly-detection.md` → `agents/forensic-investigator.md` |
| MEDIUM | `anomaly-detection.md` → monitor for 60 minutes, re-triage |
| LOW | Log the observation, link to `anomaly-detection.md` for monitoring setup |
