# /incident-triage

Run this command when you suspect or have confirmed a security incident.

## What This Does

Walks you through a structured triage in under 5 minutes, assigns a severity level, and gives you an immediate action list.

## Triage Questions

Answer each of these:

**1. Is this confirmed or suspected?**
- Confirmed: I have seen funds moving to attacker wallet
- Suspected: I see anomalous transactions but no confirmed loss

**2. What is the estimated amount affected?**
- Under $10K
- $10K – $100K
- $100K – $1M
- Over $1M

**3. Is the attack ongoing?**
- Yes — program is still accepting transactions and being exploited
- No — attack appears complete
- Unknown

**4. What controls do you have?**
- [ ] Upgrade authority (sole)
- [ ] Upgrade authority (multisig — how many signers reachable right now?)
- [ ] Emergency pause instruction in program
- [ ] Freeze authority on token mint
- [ ] None of the above

**5. Team status**
- How many core team members are currently reachable?
- Is your multisig threshold reachable right now?

## Severity Assignment

Based on your answers:

| Situation | Severity | Primary Action |
|-----------|----------|----------------|
| Confirmed, ongoing, >$100K | CRITICAL | Freeze NOW, load active-exploit-response.md |
| Confirmed, ongoing, <$100K | HIGH | Freeze + assess, load active-exploit-response.md |
| Confirmed, complete | HIGH | Secure remaining funds, load post-mortem-analysis.md |
| Suspected, ongoing | MEDIUM | Monitor closely, prepare to escalate |
| Suspected, possible recon | LOW | Log, investigate next 1 hour |

## Immediate Action List (auto-generated based on severity)

### CRITICAL
1. Wake all multisig signers NOW — call them if needed
2. Load active-exploit-response.md immediately
3. Load program-freeze-and-pause.md and initiate Squads proposal
4. Take forensic snapshot before any state changes
5. Do NOT post publicly yet

### HIGH
1. Convene technical lead and one other team member
2. Take forensic snapshot
3. Load active-exploit-response.md
4. Prepare freeze instructions but do not execute without confirmation
5. Draft initial notice (but do not post yet)

### MEDIUM
1. Assign one technical team member to monitor
2. Load anomaly-detection.md
3. Check last 50 transactions manually on Solscan
4. Set up real-time alerts if not already running
5. Brief leadership — do not post publicly

### LOW
1. Log the observation with timestamp
2. Review in 1 hour
3. No immediate escalation needed
