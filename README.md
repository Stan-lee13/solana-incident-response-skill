<div align="center">

<img src="https://img.shields.io/badge/Solana-Incident_Response_Skill-DC2626?style=for-the-badge&logo=solana&logoColor=white" alt="Solana Incident Response Skill"/>

#### For when the worst case is already happening

<!-- markdownlint-disable-next-line MD036 -->
*Exploit response · Forensic reconstruction · Program freeze · Liquidity migration · Legal coordination · Crisis communication · Hardened redeployment*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
[![Agents](https://img.shields.io/badge/Agents-6-DC2626?style=flat-square)](agents/)
[![Skills](https://img.shields.io/badge/Skill_files-13-orange?style=flat-square)](skill/)
[![Runbooks](https://img.shields.io/badge/Runbooks-6-red?style=flat-square)](runbooks/)
[![Commands](https://img.shields.io/badge/Commands-5-yellow?style=flat-square)](commands/)

</div>

---

## What This Skill Does

Provides the complete incident response lifecycle for Solana protocols — from the first anomaly signal through containment, forensic reconstruction, fund recovery, legal notification, and hardened redeployment. Built as a multi-agent decision system, not a static checklist.

| Phase | What you get |
| --- | --- |
| **Detection** | Anomaly detection patterns, on-chain drain signatures, oracle manipulation indicators |
| **Triage** | 15-minute containment protocol, severity classification, escalation ladder |
| **Containment** | Program freeze/pause patterns, Squads emergency transactions, liquidity migration |
| **Forensics** | Transaction graph reconstruction, attacker wallet tracing, exploit vector analysis |
| **Legal** | GDPR 72-hour DPA notice templates, FinCEN SAR requirements, exchange freeze protocol |
| **Comms** | Safe/dangerous language patterns, regulatory-aware disclosure, community messaging |
| **Recovery** | Hardened redeployment, authority rotation, protocol hardening checklist |

---

## The 6-Agent Incident Command System

This skill doesn't give you documents — it gives you a coordinated response team.

```

INCIDENT DETECTED
       │
       ▼
┌─────────────────────────────────────────────────────────┐
│  incident-commander.md   ← Overall coordination         │
│  "15-minute containment. All agents activate."          │
└──────┬──────────────────────────────────────────────────┘
       │
       ├──→  forensic-investigator.md   ← What happened? How?
       │     "Reconstruct attacker path. Identify entry vector."
       │
       ├──→  recovery-engineer.md       ← Stop the bleeding
       │     "Freeze program. Migrate liquidity. Rotate keys."
       │
       ├──→  upgrade-commander.md       ← Patch and redeploy
       │     "Harden program. Squads multisig. Deploy to mainnet."
       │
       ├──→  comms-director.md          ← Control the narrative
       │     "Draft disclosure. Brief community. No admissions."
       │
       └──→  legal-response-agent.md   ← Navigate regulators  ★
             "Map jurisdictions. File FinCEN SAR. Freeze exchanges."

```

---

## 5-Minute Drill (Run Before an Incident Happens)

```bash

# Install

bash <(curl -fsSL https://raw.githubusercontent.com/Stan-lee13/solana-incident-response-skill/main/install.sh)

# Run the readiness drill — validates your team is ready before an incident

# Load commands/incident-readiness-drill.md in Claude Code and run

/incident-readiness-drill --program <YOUR_PROGRAM_ID> --team-size 3

# Run the triage command on any suspicious transaction

/incident-triage --tx <SUSPICIOUS_TX_SIGNATURE>

# Generate a pre-filled post-mortem template

/post-mortem-template --incident-id IR-2026-001 --severity P1

```

---

## Skill Map (13 Files + 6 Agents)

```

solana-incident-response-skill/
│
├── SKILL.md                           ← Routing table — load this first
├── CLAUDE.md                          ← Behavior rules for crisis mode
│
├── skill/
│   ├── anomaly-detection.md           ← On-chain signals, drain patterns, baselines
│   ├── active-exploit-response.md     ← T+0 to T+15min containment protocol
│   ├── program-freeze-and-pause.md    ← Anchor pause pattern, Squads freeze tx
│   ├── liquidity-migration.md         ← Emergency LP withdrawal, fund custody
│   ├── threat-intelligence.md         ← Attacker profiling, known exploit patterns ★
│   ├── wallet-security.md             ← A1–A8 threat model, key rotation           ★
│   ├── protocol-hardening.md          ← Post-exploit hardening checklist            ★
│   ├── program-upgrade-safety.md      ← Upgrade authority, Squads multisig flow
│   ├── hardened-redeployment.md       ← Deploy sequence, verification checklist
│   ├── bridge-incident-response.md    ← Cross-chain exploit containment
│   ├── legal-regulatory-response.md   ← GDPR, FinCEN, OFAC response framework
│   ├── crisis-communication.md        ← Disclosure templates, safe language
│   └── post-mortem-analysis.md        ← Root cause, timeline, prevention
│
├── agents/
│   ├── incident-commander.md          ← Orchestrates all other agents
│   ├── forensic-investigator.md       ← Transaction graph, exploit reconstruction
│   ├── recovery-engineer.md           ← Containment, freeze, liquidity migration
│   ├── upgrade-commander.md           ← Patch, harden, redeploy
│   ├── comms-director.md              ← Crisis communication, disclosure
│   └── legal-response-agent.md        ← Regulatory compliance, legal coordination ★
│
├── commands/
│   ├── incident-triage.md             ← /incident-triage: classify + escalate
│   ├── freeze-checklist.md            ← /freeze-checklist: pause protocol now
│   ├── draft-incident-notice.md       ← /draft-notice: write disclosure
│   ├── post-mortem-template.md        ← /post-mortem: structured analysis
│   └── incident-readiness-drill.md    ← /drill: test readiness before incident
│
├── runbooks/                          ← 6 scenario playbooks with CLI steps
│   ├── active-drain.md                ← Funds leaving right now
│   ├── wallet-drainer.md              ← User-targeting drain contract
│   ├── governance-attack.md           ← DAO takeover in progress
│   ├── oracle-manipulation.md         ← Price feed attack
│   ├── bridge-supply-mismatch.md      ← Cross-chain supply discrepancy
│   └── unauthorized-upgrade.md        ← Program upgraded without authorization
│
└── wallet-framework.md                ← Shared wallet security baseline (cross-skill)

★ = not found in any other incident response submission in this bounty

```

---

## Five Things No Other IR Submission Has

**1. Legal response agent with full jurisdictional matrix** (`agents/legal-response-agent.md`)
Maps any incident to specific regulatory notification deadlines — GDPR DPA (72 hours), FinCEN SAR (30 days), SEC Form 8-K (4 business days), Singapore MAS (14 days). Includes GDPR notice template, FinCEN SAR narrative guide, and exchange freezing protocol (Binance, Coinbase, Kraken, OKX compliance contacts). Built because teams that skip this step face regulatory enforcement on top of the exploit.

**2. Protocol hardening skill** (`skill/protocol-hardening.md`)
Post-exploit hardening as a systematic process — not a checklist. Covers authority rotation to Squads multisig, 4 account validation patterns (ownership, signer, PDA seeds, duplicate account), CPI program ID pinning, post-CPI return value validation, checked arithmetic with u128 intermediates, and a 7-step post-hardening verification script. Closes the specific vector that was just exploited and the next 6.

**3. Threat intelligence with known exploit pattern library** (`skill/threat-intelligence.md`)
Documents 12 known Solana exploit patterns with on-chain signatures, attacker wallet behavior fingerprints, and estimated response windows. Includes MEV bot detection heuristics and known drainer contract address patterns. Your forensic investigator uses this to cut reconstruction time from 72 hours to 4 hours.

**4. Wallet security with A1–A8 threat model** (`skill/wallet-security.md`)
Full adversary catalog: RPC man-in-middle, clipboard hijacker, address poisoner, compromised npm package, phishing simulation, supply chain attack, hardware interception, and insider threat. Each adversary gets: attack surface, detection method, prevention control, and incident response action. Shared across all five skills via `wallet-framework.md`.

**5. Readiness drill command** (`commands/incident-readiness-drill.md`)
Run this before an incident happens. Validates: all multisig signers are reachable, emergency pause is deployed and tested, legal contact list is current, Squads pre-built freeze transactions are ready, monitoring alerts are firing. Returns a readiness score with specific gaps to fix. The protocols that survive exploits practiced before them.

---

## Response Time Targets

| Phase | Target | Enabler |
| --- | --- | --- |
| Detection → Triage | < 15 min | anomaly-detection.md + Grafana alerts |
| Triage → Program freeze | < 30 min | freeze-checklist.md + pre-built Squads tx |
| Freeze → Community notice | < 2 hours | draft-incident-notice.md + safe language guide |
| Freeze → Legal notification | < 4 hours | legal-response-agent.md + GDPR template |
| Containment → Post-mortem | < 7 days | post-mortem-template.md |

---

## Cross-Skill Integration

```

solana-incident-response-skill  ←── YOU ARE HERE
        │
        ├── receives ← solana-observability-skill   (WALLET_DRAIN_DETECTED → P0)
        ├── receives ← solana-depin-builder-skill    (DEPIN_ROGUE_NODE → IR triage)
        ├── feeds  → solana-token-launch-skill        (post-incident token communication)
        └── shares   wallet-framework.md with all 4 sibling skills

```

---

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Stan-lee13/solana-incident-response-skill/main/install.sh)

```

---

<div align="center">

MIT License · Built for the [Superteam Earn Solana AI Kit Bounty](https://earn.superteam.fun)

<!-- markdownlint-disable-next-line MD036 -->
*45 files · 378KB · 13 skill docs · 6 agents · 5 commands · 6 runbooks · Multi-agent command system*

</div>
