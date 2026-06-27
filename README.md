<p align="center">
  <strong>solana-incident-response-skill</strong><br/>
  The incident playbook for Solana protocols when the worst case is already happening.
</p>

[![MIT License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Solana AI Kit](https://img.shields.io/badge/Solana%20AI%20Kit-compatible-green)](https://github.com/solanabr/solana-ai-kit)

---

# solana-incident-response-skill

A production-grade incident response knowledge base for Solana protocols. It covers the full lifecycle from anomaly detection and triage through containment, forensic reconstruction, crisis communication, fund recovery, legal handoff, and hardened redeployment.

This repo is designed for Claude Code agents and other AI tooling in the Solana AI Kit. It is intentionally operational rather than academic: the agents and commands are written as decision-making playbooks for real incidents such as oracle attacks, governance takeovers, fund drains, and upgrade compromises.

**Why this matters:** teams that survive major Solana exploits rarely do so because they improvise well. They do so because they already have a decision tree, an escalation path, and a communication protocol. This skill provides that structure before the incident begins.

---

## What’s New

This revision upgrades the repo from a collection of strong sub-skills into a coordinated multi-agent incident response system:

- Rebuilt the incident commander, forensic investigator, and communications director agents for real-time crisis orchestration.
- Added a recovery engineer agent for post-containment recovery and redeployment decisions.
- Expanded the commands into full operational triage and incident workflow tools.
- Added ecosystem-signals.md to define handoffs between this skill and the other Solana AI Kit skills.

---

## Repository Layout

```text
solana-incident-response-skill/
├── SKILL.md                           # Router for the correct sub-skill by incident phase
├── README.md                          # This file
├── CLAUDE.md                          # Claude Code configuration
├── install.sh                         # One-command installer
├── LICENSE                            # MIT
├── ecosystem-signals.md              # Cross-skill coordination protocol with other Solana skills
│
├── skill/
│   ├── anomaly-detection.md           # Pre-exploit monitoring and probe detection
│   ├── active-exploit-response.md     # First-hour incident containment playbook
│   ├── program-freeze-and-pause.md    # Squads v4 freeze, pause, and authority controls
│   ├── liquidity-migration.md         # Drain mitigation and fund movement to safety
│   ├── crisis-communication.md        # Stakeholder messaging and incident notice templates
│   ├── post-mortem-analysis.md        # Forensic reconstruction and public timeline guidance
│   ├── hardened-redeployment.md       # Recovery and relaunch hardening checklist
│   ├── legal-regulatory-response.md   # Reporting, insurer, and regulatory obligations
│   └── program-upgrade-safety.md      # Safe planned upgrade coordination
│
├── agents/
│   ├── incident-commander.md          # Incident leadership, severity, escalation, and war-room control
│   ├── forensic-investigator.md       # On-chain evidence capture, fund tracing, and root cause analysis
│   ├── comms-director.md              # Public and private comms, stakeholder handling, and reputation recovery
│   ├── recovery-engineer.md           # Post-containment recovery, white-hat negotiation, and redeployment support
│   └── upgrade-commander.md           # Safe planned upgrades and migration coordination
│
├── commands/
│   ├── incident-triage.md             # /incident-triage — severity classification and activation plan
│   ├── draft-incident-notice.md       # /draft-incident-notice — public notice drafts in multiple formats
│   ├── freeze-checklist.md            # /freeze-checklist — Solana-specific emergency freeze steps
│   └── post-mortem-template.md        # /post-mortem-template — industry-style post-mortem structure
│
└── rules/
    └── incident-safety.md             # Guardrails for legal, disclosure, and operational safety
```

---

## Installation

```bash
# One-line install
curl -sSL https://raw.githubusercontent.com/Stan-lee13/solana-incident-response-skill/main/install.sh | bash

# Into .agents/ for non-Claude tools
curl -sSL https://raw.githubusercontent.com/Stan-lee13/solana-incident-response-skill/main/install.sh | bash -s -- --agents
```

---

## Usage

### 🚨 Active exploit right now

```text
Load agents/incident-commander.md — active exploit on [PROGRAM_ID], funds moving, containment required now.
```

### 🔍 Suspicious activity, not yet confirmed

```text
Load skill/anomaly-detection.md — unusual transaction pattern or authority change detected.
```

### 🧊 Freeze the program immediately

```text
Run /freeze-checklist — program [PROGRAM_ID], upgrade authority is Squads 3-of-5.
```

### 📢 Draft the incident notice

```text
Run /draft-incident-notice — protocol [NAME], confirmed exploit, deposits paused, users need instructions.
```

### 🔬 Reconstruct the exploit

```text
Load agents/forensic-investigator.md — identify the first malicious transaction and attacker timeline.
```

### 🛠️ Recover and redeploy safely

```text
Load agents/recovery-engineer.md — post-containment recovery, compensation, and hardening path.
```

---

## Incident Lifecycle Coverage

| Phase | Primary File | Time Window |
|-------|--------------|-------------|
| Pre-exploit monitoring | `anomaly-detection.md` | Continuous |
| Active exploit detection | `active-exploit-response.md` | Minutes 0–60 |
| Freeze / pause execution | `program-freeze-and-pause.md` | Minutes 5–30 |
| Fund migration and containment | `liquidity-migration.md` | Minutes 15–120 |
| Crisis communications | `crisis-communication.md` | Minutes 30–72h |
| Forensic reconstruction | `post-mortem-analysis.md` | Hours 2–72 |
| Legal and regulatory response | `legal-regulatory-response.md` | Hours 2–30 days |
| Recovery and redeployment | `hardened-redeployment.md` | Days 7–90 |
| Planned upgrade safety | `program-upgrade-safety.md` | Planned |

---

## Cross-Skill Coordination

The repo also includes ecosystem-signals.md, a handoff protocol for the wider Solana AI Kit ecosystem. It defines when this skill passes work to observability, token launch, UX, and DePIN skills, and when it receives incident signals back from them.

Typical handoffs include:
- observability → incident-triage when anomalies exceed severity thresholds
- incident-response → token-launch when a token contract or mint authority is compromised
- incident-response → UX when a frontend or wallet flow is affected
- incident-response → DePIN hardening when an oracle or node network exploit is involved

---

## 2026 Production Stack Coverage

| Area | Tools |
|------|-------|
| Multisig | Squads v4 |
| On-chain monitoring | Helius enhanced transactions and webhooks |
| Fund migration | Meteora DLMM, Orca Whirlpools, Raydium CLMM |
| MEV protection | Jito bundles for protected fund movement |
| Token standards | Token-2022 and legacy SPL |
| Oracles | Pyth Network and Switchboard |
| Analytics | Chainalysis and TRM Labs |
| Insurance | Nexus Mutual, InsurAce, Sherlock |
| Security firms | Trail of Bits, OtterSec, Neodyme, Halborn |
| Legal | Crypto-specialized counsel and incident response advisors |

---

## Why Every Solana Protocol Needs This Loaded

A major exploit is rarely solved by one person. It requires coordinated decisions across engineering, legal, communications, operations, and treasury. This skill gives those teams a shared playbook before they are forced to improvise under pressure.

Every minute of delay during an active exploit can cost real user funds. The goal of this repo is simple: reduce the time from detection to first good decision.

---

## License

MIT — free to use, submodule, or extend.

## Author

Built by Victor Stanley ([@Stan-lee13](https://github.com/Stan-lee13)) for the Superteam Earn Solana AI Kit bounty.
