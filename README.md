# solana-incident-response-skill

> The Solana AI Kit skill that no one wants to need — and everyone needs to have.

A complete incident response lifecycle for Solana protocols: from the first sign of an active exploit through containment, forensic investigation, crisis communication, fund recovery, post-mortem, legal obligations, and hardened redeployment.

**This skill exists because the gap is real:** when millions of dollars are draining in real time, founders are currently Googling "what to do in a Solana hack" with zero ecosystem-standard guidance. This skill changes that.

---

## The Problem This Solves

Every production Solana protocol is a potential target. The ecosystem has excellent audit resources (Trail of Bits, OtterSec, Neodyme), great monitoring primitives (Helius webhooks), and solid multisig tooling (Squads v4) — but zero unified incident response intelligence.

When Wormhole ($320M), Crema Finance ($9M), Mango Markets ($116M), and dozens of smaller protocols were exploited, their teams were improvising in real time with no structured playbook.

This skill provides that playbook — built into the AI kit every Solana founder already uses.

---

## What's Included

```
solana-incident-response-skill/
├── SKILL.md                          # Entry point — routes to correct sub-skill
├── README.md                         # This file
├── install.sh                        # One-line installer
│
├── skill/
│   ├── active-exploit-response.md    # First 60 minutes: confirm, contain, snapshot
│   ├── program-freeze-and-pause.md   # Squads v4, emergency pause, mint authority freeze
│   ├── liquidity-migration.md        # Drain pools, move funds to safety, trace attacker
│   ├── crisis-communication.md       # Timeline templates for all public comms
│   ├── post-mortem-analysis.md       # Forensic reconstruction + publishable report structure
│   ├── hardened-redeployment.md      # Code fixes, authority hardening, phased relaunch
│   ├── legal-regulatory-response.md  # Reporting obligations, law enforcement, insurance
│   └── anomaly-detection.md          # Pre-exploit detection, monitoring setup
│
├── agents/
│   ├── incident-commander.md         # Decision-maker: triage, role assignment, escalation
│   ├── forensic-investigator.md      # On-chain reconstruction, attack vector classification
│   └── comms-director.md             # All external communications during and after incident
│
├── commands/
│   ├── incident-triage.md            # /incident-triage — severity + immediate action list
│   ├── draft-incident-notice.md      # /draft-incident-notice — ready-to-post in 2 minutes
│   ├── freeze-checklist.md           # /freeze-checklist — step-by-step freeze execution
│   └── post-mortem-template.md       # /post-mortem-template — structured report generator
│
└── rules/
    └── incident-safety.md            # Always-on: no premature disclosure, no speculation
```

---

## Installation

```bash
curl -sSL https://raw.githubusercontent.com/Stan-lee13/solana-incident-response-skill/main/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/Stan-lee13/solana-incident-response-skill.git
cd solana-incident-response-skill
bash install.sh
```

---

## Usage

### Active exploit right now
```
Load agents/incident-commander.md — we have an active exploit on [PROGRAM_ID]
```

### You need to freeze your program
```
Run /freeze-checklist — program is [PROGRAM_ID], authority is Squads multisig with 3 of 5 signers reachable
```

### Writing the incident notice
```
Run /draft-incident-notice — protocol is [NAME], we confirmed exploit 20 minutes ago, deposits are paused, users should not interact
```

### Post-mortem after the incident
```
Load skill/post-mortem-analysis.md — attack was on [DATE], attack vector was [DESCRIPTION]
```

### Run /post-mortem-template
```
Run /post-mortem-template — incident [DATE], lost [AMOUNT], fix was [DESCRIPTION]
```

---

## Coverage Matrix

| Phase | Coverage |
|-------|----------|
| Pre-exploit monitoring | anomaly-detection.md |
| Active exploit (0-60 min) | active-exploit-response.md |
| Program freeze/pause | program-freeze-and-pause.md |
| Fund migration | liquidity-migration.md |
| Crisis communication | crisis-communication.md |
| Forensic investigation | post-mortem-analysis.md |
| Legal/regulatory | legal-regulatory-response.md |
| Hardened redeployment | hardened-redeployment.md |

---

## 2026 Stack Coverage

| Area | Tools |
|------|-------|
| Multisig | Squads v4 |
| Monitoring | Helius webhooks, enhanced transactions API |
| DeFi (withdraw) | Meteora DLMM, Orca Whirlpools, Raydium CLMM |
| MEV protection | Jito bundles |
| Token standards | Token-2022, legacy SPL |
| Oracles | Pyth Network |
| Analytics | Chainalysis, TRM Labs |
| Insurance | Nexus Mutual, InsurAce, Sherlock |
| Security firms | Trail of Bits, OtterSec, Neodyme, Halborn |

---

## Design Principles

**Progressive loading** — Top-level SKILL.md routes to only what is needed. In an active exploit, you load `active-exploit-response.md` — not all 8 skill files.

**Time-aware** — Every skill is aware that time is the most expensive variable in an exploit. Instructions are ordered by urgency.

**Production-grade code** — Every code sample targets current 2026 SDKs: `@sqds/multisig v2+`, `@meteora-ag/dlmm latest`, `@orca-so/whirlpools-sdk v0.13+`, `helius-sdk latest`.

**Opinionated** — The skill gives direct recommendations (use Squads v4, engage Trail of Bits, contact IC3) rather than presenting menus. Founders in a crisis need decisions, not options.

**Safety rules always on** — `rules/incident-safety.md` prevents the skill from producing premature public statements, speculative attacker accusations, or unilateral action recommendations.

---

## License

MIT — free to use, merge, or submodule into the Solana AI Kit.

---

## Author

Built by Victor Stanley (@Stan-lee13) for the Superteam Earn Solana AI Kit bounty.

---

## Why This Deserves a Place in the Standard Kit

The Solana AI Kit helps founders build faster. This skill helps them survive the moment when everything goes wrong. That moment is not hypothetical — it happens to 1 in 10 protocols that reach meaningful TVL. Having this skill in the kit means every Solana founder has a battle-tested playbook loaded into their agent before they ever need it.

That is a skill people will actually reach for.
