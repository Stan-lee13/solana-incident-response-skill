# Runbook: Oracle Price Manipulation

## Severity

P0 if manipulation is causing live liquidations or inflated borrows. P1 if deviation detected but no on-chain impact yet.

## Symptoms

- `solana_oracle_price_deviation_pct > 5` (alert threshold)

- Liquidations firing at unexpected prices

- Borrow amounts suddenly inconsistent with expected collateral ratios

- Flash loan activity immediately preceding or following price deviation

- Switchboard or Pyth feed showing price divergent from CEX reference

## First 5 Minutes

1. Check oracle feed vs CEX reference price

```bash

## Switchboard feed check

curl "https://api.helius.xyz/v0/addresses/ORACLE_FEED_ADDRESS/transactions?api-key=$HELIUS_API_KEY&limit=10" \
  | jq '[.[] | {sig: .signature, time: (.timestamp | todate), type: .type}]'

```

1. Identify: is the deviation real or a stale feed?

2. Check: is there a flash loan in the same block as the anomalous price?

3. If manipulation confirmed → load `skill/active-exploit-response.md`

## Containment Options

| Option | Use when | Risk |
| --- | --- | --- |
| Pause borrow/liquidation instructions | Flash loan oracle attack | Pauses protocol for honest users |
| Switch to backup oracle | Primary feed compromised | Backup may also be manipulated |
| Add circuit breaker (if exists) | Price deviation > threshold | |
| Emergency pause full protocol | Manipulation ongoing + no backup | Highest impact, most protection |

## PromQL

```promql

## Oracle deviation from expected

(solana_oracle_price_usd - solana_oracle_expected_price_usd) 
  / solana_oracle_expected_price_usd * 100

## Liquidation rate (spike = possible manipulation)

rate(solana_liquidation_total[5m])

```

## Resolution Criteria

- Oracle price returns to within 2% of CEX reference for 15 minutes

- No further anomalous liquidations

- Root cause identified (stale feed vs active manipulation)

- If active manipulation: load full incident response lifecycle

## Detection Signals

| Signal | Threshold | Source |
| --- | --- | --- |
| Price deviation from reference feed | > 3% | `anomaly-detection.md` TWAP monitor |
| Unusual borrow/liquidation volume spike | > 5× 24h average | Protocol events |
| Pyth/Switchboard confidence interval widens | > 2% | Oracle health endpoint |

## Escalation

| Time Elapsed | Action | Owner |
| --- | --- | --- |
| 0–5 min | Incident Commander notified; trading/borrowing paused | Incident Commander |
| 5–20 min | Contact Pyth/Switchboard oracle team directly | Recovery Engineer |
| 20–60 min | Assess user losses; prepare compensation framework | Legal Response Agent |
| > 1 hour | Public incident notice with root cause and status | Comms Director |
