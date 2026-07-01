# Runbook: Unauthorized Program Upgrade

## Severity

P0 — any unexpected program upgrade is a P0 until proven otherwise.
An attacker with upgrade authority can change any instruction behavior silently.

## Symptoms

- `solana_program_upgrade_detected_total` counter increments

- BPFLoaderUpgradeable instruction on your program outside an approved deploy window

- Program data hash no longer matches your expected release artifact

- New transaction failures begin after the unexpected upgrade slot

## First 5 Minutes

1. Identify the upgrade authority that signed the upgrade

```bash

## Who performed the upgrade

solana transaction SUSPICIOUS_TX_SIGNATURE --output json | \
  jq '.transaction.message.accountKeys'

## Current program state

solana program show PROGRAM_ID

```

1. Check if upgrade was in your approved schedule → if YES, false positive

2. If UNKNOWN or NOT scheduled → declare P0

## Detection Signals

| Signal | Threshold | Source |
| --- | --- | --- |
| `BPFLoaderUpgradeable` upgrade instruction detected | Any | `program-upgrade-detected` alert |
| Program data hash change vs pinned baseline | Any | `wallet-observability.md` hash check |
| Upgrade authority changed without Squads multisig tx | Any | `solana_authority_mismatch` Prometheus alert |

## Immediate Actions (Unauthorized Upgrade Confirmed)

```

[ ] Load agents/incident-commander.md — declare P0
[ ] Load skill/program-freeze-and-pause.md — attempt emergency pause
[ ] Check: does your program have an emergency pause instruction?
[ ] Notify all team members via private channel
[ ] Preserve: snapshot the program data account before any changes
[ ] Load skill/wallet-security.md — upgrade authority key may be compromised
[ ] Do NOT re-upgrade until forensics confirms how authority was accessed

```

## If Upgrade Authority Is Compromised

See `skill/wallet-security.md` → Authority Key Compromise section.
The attacker can upgrade again at any time until authority is rotated.
Priority 1 is rotating the authority, not investigating.

## PromQL

```promql

## Unexpected program upgrade counter

increase(solana_program_upgrade_detected_total[1h])

```

## Resolution Criteria

- Upgrade authority confirmed secure (rotated if compromised)

- Program re-deployed with patch or reverted to known-good state

- Forensic investigation complete — how was authority accessed?

- Post-mortem published — load `skill/post-mortem-analysis.md`

## Escalation

| Time Elapsed | Action | Owner |
| --- | --- | --- |
| 0–5 min | Incident Commander declares P0; freeze all downstream integrations | Incident Commander |
| 5–15 min | Forensic Investigator pulls upgrade tx and new program bytecode | Forensic Investigator |
| 15–30 min | Upgrade Commander prepares emergency revert or hotfix | Upgrade Commander |
| > 30 min | Legal notification; preserve all chain-of-custody evidence | Legal Response Agent |

