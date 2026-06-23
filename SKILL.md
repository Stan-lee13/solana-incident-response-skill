# Solana Incident Response Skill

> Route to the right sub-skill based on what you need.
> Load only what is relevant — do not load all files at once.

## What this skill covers

A complete incident response lifecycle for Solana protocols — from the first sign of an active exploit through containment, recovery, post-mortem, and hardened re-deployment. This skill exists because when millions of dollars are draining in real time, founders need a battle-tested playbook, not a Google search.

---

## Routing Table

### 🚨 ACTIVE EXPLOIT RIGHT NOW
→ Load `skill/active-exploit-response.md`
→ Load `skill/program-freeze-and-pause.md`
→ Load agents/incident-commander.md

Use when: You believe funds are being drained, an attack is in progress, or you have confirmed anomalous transactions.

---

### 🔍 SUSPICIOUS ACTIVITY / EARLY WARNING
→ Load `skill/anomaly-detection.md`

Use when: You see unusual transaction patterns, unexpected account drains, oracle deviations, or governance proposals you didn't initiate.

---

### 🧊 FREEZE / PAUSE / EMERGENCY CONTROLS
→ Load `skill/program-freeze-and-pause.md`

Use when: You need to invoke emergency pause, freeze mint authority, close or restrict program accounts, or coordinate multisig emergency actions.

---

### 🏦 LIQUIDITY MIGRATION & FUND RECOVERY
→ Load `skill/liquidity-migration.md`

Use when: You need to drain pools, migrate to safe wallets, coordinate with market makers, or protect remaining user funds.

---

### 📢 CRISIS COMMUNICATION
→ Load `skill/crisis-communication.md`

Use when: You need to write the initial incident notice, ongoing updates, post-mortem disclosure, or coordinate with security researchers.

---

### 🔬 POST-MORTEM & ROOT CAUSE ANALYSIS
→ Load `skill/post-mortem-analysis.md`

Use when: The immediate crisis is contained and you need to reconstruct the attack, identify the root cause, and write the public post-mortem report.

---

### 🛡️ HARDENED REDEPLOYMENT
→ Load `skill/hardened-redeployment.md`

Use when: You are preparing to redeploy after an incident — audit requirements, re-architecture decisions, upgrade authority hardening, and community trust restoration.

---

### ⚖️ LEGAL & REGULATORY RESPONSE
→ Load `skill/legal-regulatory-response.md`

Use when: You need to understand reporting obligations, law enforcement coordination, insurance claims, or user compensation frameworks.

---

## Quick Commands

- `/incident-triage` — classify severity, identify attack vector, generate immediate action list
- `/freeze-checklist` — step-by-step program freeze and authority revocation
- `/draft-incident-notice` — generate initial public communication within 15 minutes
- `/post-mortem-template` — structured post-mortem report ready to publish
- `/recovery-plan` — full fund recovery and redeployment roadmap
- `/incident-severity` — classify P0/P1/P2/P3 from your observed signals

---

---

### 🔧 PROGRAM UPGRADE — PLANNED OPERATION (not an incident)
→ Load `skill/program-upgrade-safety.md`
→ Load `agents/upgrade-commander.md`

Use when: You are planning a program upgrade, changing account layouts, 
migrating existing user state, or coordinating a Squads multisig upgrade.
This is NOT for emergency upgrades during active exploits.

---

## Always-On Rules

Rules in `rules/incident-safety.md` are active whenever this skill is loaded.
They enforce: no premature public disclosure, no destroying forensic evidence, no unilateral emergency actions without multisig, and no promises to users about recovery timelines.
