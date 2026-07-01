# Runbook: Wallet Drainer Detected

## Severity

P0 if your frontend is serving drainer transactions.
P1 if a drainer is targeting your users via a look-alike or phishing site.

## Symptoms

- Users report losing funds immediately after interacting with your dApp

- Wallet error spike with SetAuthority or unexpected delegate instructions

- DNS or domain monitoring alerts on look-alike domains

- Multiple users in Discord/Twitter reporting "my wallet was emptied"

- Frontend release or dependency update immediately precedes reports

## First 5 Minutes

1. Confirm: is the drain happening through your legitimate domain or a phishing site?

2. Check your latest frontend deployment — what changed?

3. Reproduce: connect a blank devnet wallet and inspect the transactions being built

4. Load `skill/wallet-security.md` → Drainer Contract Detection section

## If Your Frontend Is Compromised

```

[ ] Take frontend offline IMMEDIATELY (Vercel/Netlify → disable deployment)
[ ] Post on all official channels: "DO NOT interact with [domain] — investigating security issue"
[ ] DO NOT specify what the issue is (attackers are watching)
[ ] Load agents/comms-director.md — draft holding statement
[ ] Audit git history for suspicious commits in last 48 hours
[ ] Rotate all deploy keys, CI/CD secrets, and hosting credentials
[ ] Verify all program IDs in the compromised build vs canonical build
[ ] Alert exchanges with your token address — watch for drainer proceeds

```

## User Recovery Guidance (Post-Containment)

Once frontend is confirmed safe, publish:

```

1. Revoke any outstanding token approvals: https://revoke.cash or https://solanatools.xyz

2. If SetAuthority was called: you must create a new wallet (ownership cannot be reverted)

3. If only tokens were drained via approval: revoke + move remaining assets

4. Report tx signatures to Helius and Chainalysis for tracing

```

## PromQL

```promql

## Wallet error spike (proxy for drainer activity)

rate(solana_wallet_error_total{error_type="SetAuthority"}[5m])

## Unusual delegate approve activity

rate(solana_token_delegate_approve_total[5m])

```

## Resolution Criteria

- Drainer source identified and removed (compromised frontend taken down)

- Clean deployment verified and re-deployed

- All affected users notified with recovery instructions

- Token approvals revoke guide published

- Post-mortem on how the frontend was compromised

## Escalation

| Time Elapsed | Action | Owner |
| --- | --- | --- |
| 0–5 min | Incident Commander notified; `SolanaWalletDrainDetected` alert confirms | Incident Commander |
| 5–15 min | Forensic Investigator traces attacker wallet; block on CEX contacts | Forensic Investigator |
| 15–30 min | Comms Director posts user warning; disable vulnerable UI entry points | Comms Director |
| > 30 min | Law enforcement report (IC3, Chainalysis) | Legal Response Agent |
