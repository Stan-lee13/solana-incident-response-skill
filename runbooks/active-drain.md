# Runbook: Active Protocol Drain

## Severity

P0 — declare immediately. Every second of delay increases total loss.

## Detection Signals

| Signal | Threshold | Source |
| --- | --- | --- |
| `solana_vault_balance` dropping at > 1 SOL/slot | Immediate | Prometheus `SolanaWalletDrainDetected` alert |
| Repeated withdraw/claim/swap instructions from single wallet | > 3 in 5 min | Helius `getSignaturesForAddress` |
| Failed probe txs followed by successful drain tx | Any pattern | `anomaly-detection.md` probe-then-drain detector |
| Unexpected token outflow from protocol vault | > 1% TVL | On-chain balance monitor |

## Symptoms

- `solana_vault_balance` dropping continuously

- Token transfers to unknown wallets in Helius enhanced transactions

- Repeated calls to withdraw/claim/swap from a single wallet

- Failed probe transactions followed by successful drain transactions

## First 2 Minutes

## First 2 Minutes (Response)

1. Confirm: open Helius or Solscan → are funds visibly moving out of protocol vaults?

2. If confirmed → immediately load `skill/active-exploit-response.md` and `agents/incident-commander.md`

3. Send war room message to core team: **"SECURITY INCIDENT — DO NOT POST PUBLICLY"**

4. Start incident log: UTC time, slot number, suspicious wallet(s), estimated drain so far

## Parallel Actions (T+2 to T+10 min)

```

CONTAINMENT THREAD                    FORENSICS THREAD
load program-freeze-and-pause.md      load forensic-investigator agent
check if emergency pause exists       run Helius tx history on program
prepare Squads proposal if needed     identify first malicious tx + wallet
check if frontend kill switch exists  trace fund flow to destination wallets

```

## Key PromQL (for Observability stack)

```promql

## Vault balance rate of change (negative = drain)

rate(solana_vault_balance_lamports[5m])

## Transfer volume spike

sum(rate(solana_token_transfer_amount[5m])) by (destination)

```

## Escalation

- IC declares P0 → Comms Director on standby

- Exchanges notified within 60 minutes (see `skill/crisis-communication.md`)

- Legal engaged if loss > $100K

## Resolution Criteria

- Program paused OR vulnerability patched and redeployed

- All known attacker addresses confirmed blocked or funds traced

- Post-mortem assigned — load `skill/post-mortem-analysis.md`

- Comms update published — load `agents/comms-director.md`
