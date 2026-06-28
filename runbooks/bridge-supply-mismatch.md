# Runbook: Bridge Supply Mismatch

## Severity
P0 by default. A bridge supply mismatch means either funds are unlocked without being burned,
or wrapped tokens are circulating without locked collateral. Both are existential.

## Symptoms
- Wrapped asset supply exceeds locked collateral on source chain
- Bridge mint authority issued tokens outside expected lock/mint events
- `solana_bridge_supply_mismatch` alert fires (Observability stack)
- Guardian signatures or relayer activity is anomalous
- Cross-chain messages replayed (same VAA or nonce executed twice)

## First 5 Minutes

1. Identify which bridge is affected (Wormhole, deBridge, LayerZero, CCTP, custom)
2. Compare wrapped supply on Solana vs locked collateral on source chain
```bash
# Wrapped token supply on Solana
spl-token supply WRAPPED_MINT_ADDRESS

# Cross-reference with source chain explorer for locked collateral
# This requires manual verification per bridge
```
3. Check bridge guardian activity and message relay logs
4. Load `skill/bridge-incident-response.md` immediately

## Parallel Contact List (execute simultaneously)

```
INTERNAL:
[ ] IC declares P0
[ ] Load skill/program-freeze-and-pause.md — freeze wrapped mint authority
[ ] Load skill/liquidity-migration.md — move collateral to safety if possible

EXTERNAL (within 30 minutes):
[ ] Contact bridge team's emergency channel (Wormhole Discord #security)
[ ] Alert exchanges to pause deposits/withdrawals of affected wrapped asset
[ ] Notify Solana Foundation security team: security@solana.com
```

## PromQL

```promql
# Bridge supply vs expected (requires custom metric from bridge exporter)
solana_bridge_wrapped_supply - solana_bridge_expected_collateral

# Bridge transaction anomaly rate
rate(solana_bridge_transaction_total{status="anomaly"}[5m])
```

## Resolution Criteria
- Wrapped mint authority frozen (no new issuance possible)
- Collateral accounting reconciled and mismatch explained
- Bridge team has confirmed root cause and patch timeline
- Post-mortem published with supply accounting
