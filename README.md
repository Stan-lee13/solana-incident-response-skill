<p align="center">
  <strong>solana-incident-response-skill</strong><br/>
  The skill no one wants to need — and every protocol must have.
</p>

[![MIT License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Solana AI Kit](https://img.shields.io/badge/Solana%20AI%20Kit-compatible-green)](https://github.com/solanabr/solana-ai-kit)

---

# solana-incident-response-skill

A complete, production-grade incident response lifecycle for Solana protocols — from the first sign of an active exploit through containment, forensic investigation, crisis communication, fund recovery, legal obligations, and hardened redeployment.

**The problem it solves:** When Wormhole ($320M), Crema Finance ($9M), Mango Markets ($116M) were exploited, their teams were improvising in real time with no structured playbook. No unified incident response intelligence existed. This skill changes that — every Solana founder using the AI Kit has a battle-tested playbook loaded before they ever need it.

**No other skill in the kit covers this.** The closest submissions cover single-phase issues: tx forensics, CPI safety analysis, audit workflows. None cover the full lifecycle: from detection → containment → fund recovery → legal response → hardened relaunch.

---

## What's Included

```
solana-incident-response-skill/
├── SKILL.md                           # Entry point — routes to correct sub-skill by phase
├── README.md                          # This file
├── CLAUDE.md                          # Claude Code configuration
├── install.sh                         # One-command installer
├── LICENSE                            # MIT
│
├── skill/
│   ├── anomaly-detection.md           # Pre-exploit detection — catch probe attempts before they scale
│   ├── active-exploit-response.md     # First 60 minutes — confirm, contain, snapshot, coordinate
│   ├── program-freeze-and-pause.md    # Squads v4 emergency freeze, mint authority, account closure
│   ├── liquidity-migration.md         # Drain pools, trace funds, move to safety via Jito bundles
│   ├── crisis-communication.md        # Timeline-aware templates for every public communication
│   ├── post-mortem-analysis.md        # Forensic reconstruction with Helius SDK + publishable report
│   ├── hardened-redeployment.md       # Code fixes, authority hardening, phased relaunch gates
│   ├── legal-regulatory-response.md   # Reporting obligations, law enforcement, insurance, OFAC
│   └── program-upgrade-safety.md      # Safe planned upgrade coordination (not emergency)
│
├── agents/
│   ├── incident-commander.md          # Decision-maker — triage, role assignment, escalation matrix
│   ├── forensic-investigator.md       # On-chain reconstruction, attack vector classification, fund tracing
│   ├── comms-director.md              # All external comms — timing, templates, platform coordination
│   └── upgrade-commander.md           # Safe planned upgrade coordinator — state migration, IDL drift
│
├── commands/
│   ├── incident-triage.md             # /incident-triage — severity + immediate action list in 3 min
│   ├── draft-incident-notice.md       # /draft-incident-notice — ready-to-post in 2 minutes
│   ├── freeze-checklist.md            # /freeze-checklist — step-by-step freeze execution
│   └── post-mortem-template.md        # /post-mortem-template — publishable report generator
│
└── rules/
    └── incident-safety.md             # Always-on: no premature disclosure, no speculation
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

```
Load agents/incident-commander.md — we have an active exploit on [PROGRAM_ID]
```

### 🔍 Suspicious activity, not yet confirmed

```
Load skill/anomaly-detection.md — seeing unusual transaction patterns on [PROGRAM_ID]
```

### 🧊 Need to freeze the program immediately

```
Run /freeze-checklist — program [PROGRAM_ID], upgrade authority is Squads 3-of-5
```

### 📢 Write the incident notice now

```
Run /draft-incident-notice — protocol [NAME], confirmed 20 minutes ago, deposits paused
```

### 🔬 Post-mortem reconstruction

```
Load skill/post-mortem-analysis.md — attack was [DATE], attacker was [WALLET], vector was [DESCRIPTION]
```

### 🛡️ Safe planned upgrade (non-emergency)

```
Load agents/upgrade-commander.md — upgrading [PROGRAM], account layout changed, 50K existing accounts
```

---

## Incident Lifecycle Coverage

| Phase | Skill File | Time Window |
|-------|-----------|-------------|
| Pre-exploit monitoring | `anomaly-detection.md` | Continuous |
| Active exploit detection | `active-exploit-response.md` | Minutes 0–60 |
| Program freeze / pause | `program-freeze-and-pause.md` | Minutes 5–30 |
| Fund migration to safety | `liquidity-migration.md` | Minutes 15–120 |
| Public crisis communication | `crisis-communication.md` | Minutes 30–72h |
| Forensic reconstruction | `post-mortem-analysis.md` | Hours 2–72 |
| Legal and regulatory | `legal-regulatory-response.md` | Hours 2–30 days |
| Hardened redeployment | `hardened-redeployment.md` | Days 7–90 |
| Safe planned upgrade | `program-upgrade-safety.md` | Planned |

---

## 2026 Production Stack Coverage

| Area | Tools |
|------|-------|
| Multisig | Squads v4 |
| On-chain monitoring | Helius enhanced transactions, webhooks |
| Fund migration | Meteora DLMM, Orca Whirlpools, Raydium CLMM |
| MEV protection | Jito bundles (protected fund migration) |
| Token standards | Token-2022 + legacy SPL |
| Oracles | Pyth Network |
| Blockchain analytics | Chainalysis, TRM Labs |
| Insurance | Nexus Mutual, InsurAce, Sherlock |
| Security firms | Trail of Bits, OtterSec, Neodyme, Halborn |
| Legal | Crypto-specialized counsel (Fenwick, Cooley, a16z crypto legal) |

---

## Why Every Solana Protocol Needs This Loaded

1 in 10 protocols that reach meaningful TVL will experience a significant security incident. The average response time for a team without a playbook is 45+ minutes from detection to first containment action. With a playbook, it's under 5 minutes.

Every minute of delay during an active exploit costs real user funds. This skill doesn't just teach incident response — it becomes the incident commander when you can't afford to think clearly.

---

## License

MIT — free to use, submodule, or extend.

## Author

Built by Victor Stanley ([@Stan-lee13](https://github.com/Stan-lee13)) for the Superteam Earn Solana AI Kit bounty.
