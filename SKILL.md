name: solana-incident-response
description: Complete incident response lifecycle for Solana protocols — from active exploit detection through containment, forensic investigation, crisis communication, fund recovery, legal obligations, and hardened redeployment.
user-invocable: true
cross-domain: true

# Solana Incident Response Skill

> Route to the right sub-skill based on what you need.
> Load only what is relevant — do not load all files at once.
> In an active exploit, every second of context loading costs money.

## Extends

- [solana-dev-skill](https://github.com/solana-foundation/solana-dev-skill) — Core Solana development (Anchor programs, PDAs, security patterns)
- [solana-observability-skill](https://github.com/Stan-lee13/Solana-observabilty-skill) — Pre-exploit monitoring and anomaly detection infrastructure

## Cross-Domain Integration Points

This skill is uniquely **cross-domain** — it operates at the intersection of:
- **Security engineering** (exploit mechanics, on-chain forensics)
- **DevOps & SRE** (monitoring, alerting, runbooks)
- **Legal & compliance** (reporting obligations, law enforcement, insurance)
- **Crisis communications** (public disclosure, community management)
- **DeFi protocol operations** (multisig coordination, liquidity migration)

No other single skill in the Solana AI Kit crosses all five domains. This is intentional: real incidents require all five simultaneously.

---

## Routing Table

### 🚨 ACTIVE EXPLOIT RIGHT NOW (ongoing drain)
→ Load `skill/active-exploit-response.md`
→ Load `skill/program-freeze-and-pause.md` (in parallel)
→ Load `agents/incident-commander.md`

Use when: Funds are actively draining, attack is confirmed, every second matters.

---

### 🔍 SUSPICIOUS ACTIVITY — NOT YET CONFIRMED
→ Load `skill/anomaly-detection.md`

Use when: Unusual transaction patterns, unexpected account drains, oracle deviations, governance proposals you didn't initiate, higher-than-normal failed transactions from a single wallet.

---

### 🧊 FREEZE / PAUSE / EMERGENCY CONTROLS
→ Load `skill/program-freeze-and-pause.md`

Use when: You need to invoke emergency pause, freeze mint authority, close or restrict program accounts, coordinate Squads v4 multisig emergency actions. Works for both active exploit and precautionary freeze.

---

### 🏦 LIQUIDITY MIGRATION & FUND RECOVERY
→ Load `skill/liquidity-migration.md`

Use when: Draining pools to safety, migrating protocol-owned TVL to secure multisig, coordinating with Meteora/Orca/Raydium to exit positions under time pressure, tracing attacker funds.

---

### 📢 CRISIS COMMUNICATION
→ Load `skill/crisis-communication.md`
→ Load `agents/comms-director.md`

Use when: Writing initial incident notice, posting updates, coordinating with exchanges, drafting white hat offer, preparing the full post-mortem disclosure.

---

### 🔬 POST-MORTEM & ROOT CAUSE ANALYSIS
→ Load `skill/post-mortem-analysis.md`
→ Load `agents/forensic-investigator.md`

Use when: The immediate crisis is contained and you need to reconstruct the attack timeline, identify the root cause vector, and write the publishable post-mortem report.

---

### 🛡️ HARDENED REDEPLOYMENT
→ Load `skill/hardened-redeployment.md`

Use when: Ready to redeploy after fixing the vulnerability. Covers code remediation patterns, authority hardening, phased relaunch gates, and community relaunch communication.

---

### ⚖️ LEGAL & REGULATORY
→ Load `skill/legal-regulatory-response.md`

Use when: Need to understand reporting obligations, law enforcement coordination, insurance claims, OFAC considerations, or user compensation frameworks.

---

### 🔧 SAFE PLANNED UPGRADE (non-emergency)
→ Load `skill/program-upgrade-safety.md`
→ Load `agents/upgrade-commander.md`

Use when: Planning a deliberate, non-emergency program upgrade that involves account layout changes, IDL drift risk, or Squads multisig coordination. This is NOT the emergency upgrade path.

---

## Detection → Response Time Benchmarks

| Detection time | Response quality | Typical outcome |
|---------------|-----------------|-----------------|
| < 5 min | With this playbook | < 30% of max possible loss |
| 5-20 min | With this playbook | 50-70% of max possible loss |
| 20-60 min | Without playbook | 80-95% of max possible loss |
| > 60 min | Any | Near-total loss likely |

The playbook is worth more in the first 5 minutes than at any other time.

---

## Agent Selection

| Task | Agent | Model |
|------|-------|-------|
| Incident coordination, role assignment, timeline | `incident-commander` | opus |
| On-chain forensics, attack reconstruction | `forensic-investigator` | opus |
| All external communications | `comms-director` | sonnet |
| Safe planned upgrade coordination | `upgrade-commander` | opus |

---

## Rules (always-on)

`rules/incident-safety.md` is auto-loaded and governs all outputs from this skill:
- No premature public disclosure
- No speculation about attack vectors in public statements
- No attacker attribution without confirmed evidence
- No restitution promises without legal review

---

## Quick Start Examples

```
# Active exploit
"Load agents/incident-commander.md — we have an active exploit on [PROGRAM_ID], funds are draining"

# Suspicious but not confirmed
"Load skill/anomaly-detection.md — seeing unusual failed transactions from one wallet on [PROGRAM_ID]"

# Need to freeze now
"Run /freeze-checklist — program is [PROGRAM_ID], upgrade authority is a 3-of-5 Squads multisig"

# Write the notice
"Load agents/comms-director.md — need to write the initial incident notice, exploit confirmed 15 min ago"

# Post-mortem
"Load skill/post-mortem-analysis.md — attack was on [DATE], exploit vector was [DESCRIPTION]"

# Safe upgrade planning
"Load agents/upgrade-commander.md — planning upgrade for [PROGRAM], added 2 new fields to UserVault"
```
