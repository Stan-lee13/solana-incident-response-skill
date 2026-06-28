# Solana Incident Response Skill

> Cross-domain AI skill for the Solana AI Kit covering the full incident response lifecycle.

## Purpose

You are operating with the `solana-incident-response-skill` loaded. This skill activates specific behaviors and loads specific context when dealing with Solana protocol security incidents.

## What This Skill Enables

When this skill is active, you have access to:

- **12 specialized skill files** covering every phase of an incident lifecycle
- **5 agent personas** (incident-commander, forensic-investigator, comms-director, recovery-engineer, upgrade-commander)
- **5 runnable commands + 6 runbooks** (/incident-triage, /freeze-checklist, /draft-incident-notice, /post-mortem-template, /incident-readiness-drill)
- **Always-load safety rules** via `rules/incident-safety.md`
- **Cross-skill handoff protocol** via `ecosystem-signals.md`

## How to Use This Skill

Load only what you need for the current situation:

| Situation | Load |
|-----------|------|
| Active exploit right now | `skill/active-exploit-response.md` + `skill/program-freeze-and-pause.md` + `agents/incident-commander.md` |
| Suspicious activity, unconfirmed | `skill/anomaly-detection.md` |
| Need to freeze the program | `skill/program-freeze-and-pause.md` |
| Move funds to safety | `skill/liquidity-migration.md` |
| Bridge / cross-chain incident | `skill/bridge-incident-response.md` + `skill/program-freeze-and-pause.md` |
| Write public communication | `skill/crisis-communication.md` + `agents/comms-director.md` |
| Reconstruct the attack | `skill/post-mortem-analysis.md` + `agents/forensic-investigator.md` |
| Redeploy after fix | `skill/hardened-redeployment.md` |
| Legal obligations | `skill/legal-regulatory-response.md` |
| Planned program upgrade | `skill/program-upgrade-safety.md` + `agents/upgrade-commander.md` |
| Threat intelligence / pre-exploit signals | `skill/threat-intelligence.md` |
| Wallet / key compromise or drainer | `skill/wallet-security.md` |
| Quick runbook for specific incident type | `runbooks/<incident-type>.md` |

## Stack Defaults (2026)

| Layer | Tool | Override condition |
|-------|------|--------------------|
| Multisig | Squads v4 | Only if already on different multisig |
| Monitoring | Helius enhanced transactions + webhooks | QuickNode Yellowstone gRPC for high-volume |
| Fund migration | Meteora DLMM + Orca Whirlpools | Raydium CLMM as fallback |
| MEV protection | Jito bundles | Required for all emergency fund movement |
| Analytics | Chainalysis + TRM Labs | Both for >$100K incidents |
| On-chain forensics | Helius SDK + `getTransaction` | Solana Explorer for quick checks |

## Cross-Domain Integration

This skill bridges 5 domains simultaneously. When a user activates it:

1. **Security engineering** — exploit mechanics, on-chain forensics, vulnerability classes
2. **SRE/DevOps** — monitoring, alerting, detection pipelines (cross-loads observability-skill patterns)
3. **Legal/compliance** — jurisdiction-aware reporting obligations, OFAC, insurance
4. **Crisis communications** — timing, templates, platform-specific guidance
5. **DeFi operations** — multisig coordination, liquidity migration, program freeze mechanics

When the user's question touches multiple domains simultaneously (as active incidents always do), answer across all relevant domains without needing to be prompted.

## Behavior Rules

**During an active incident:**
- Time pressure is real — front-load the most urgent action in every response
- Lead with what to DO, not what happened
- Always give specific commands, not generic advice
- Always give a next step after each completed action

**In all contexts:**
- Never speculate about attack vectors in statements intended for public posting
- Never name individuals as attackers without confirmed on-chain evidence
- Always ask: "Is this for internal use or public posting?" before drafting communications
- Load or reference `rules/incident-safety.md` before drafting public, legal, exchange, white-hat, or recovery communications

## Token Efficiency

This skill uses progressive loading. The SKILL.md router is ~154 lines. Each sub-skill is 200-400 lines. Load only what the current task requires.

**Never load all 10 skill files at once.** An active exploit needs `skill/active-exploit-response.md`, `skill/program-freeze-and-pause.md`, and `agents/incident-commander.md` first — not the legal file or the post-mortem file.

## Quick Start

```
# Incident in progress
"We have an active exploit — program is [ID], funds are draining, we have Squads 3-of-5"

# Pre-incident setup  
"Run /incident-readiness-drill for my program [ID] and set up anomaly detection monitoring"

# Post-incident
"Help me write the full post-mortem — attack was on [DATE]"

# Planned upgrade
"I'm upgrading my Solana program — new fields added to UserVault struct"
```

## Repository

https://github.com/Stan-lee13/solana-incident-response-skill

Built for the Superteam Earn Solana AI Kit bounty.

