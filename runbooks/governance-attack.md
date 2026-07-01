# Runbook: Governance Attack / Takeover

## Severity

P0 if an attacker has enough voting power to pass any proposal.
P1 if unusual governance token accumulation is detected before execution.

## Symptoms

- Unusual governance token accumulation from single or coordinated wallets (see `skill/threat-intelligence.md`)

- Unexpected governance proposal created (not authored by core team)

- Flash loan-funded vote on a high-value proposal

- SPL Governance or Realms proposal scheduled to execute outside planned windows

- Treasury transfer proposal to unknown wallets

## First 5 Minutes

1. Identify the suspicious proposal

```bash

## Check recent Realms / SPL Governance activity via Helius

curl "https://api.helius.xyz/v0/addresses/GOVERNANCE_PROGRAM_ADDRESS/transactions?api-key=$HELIUS_API_KEY&limit=20" \
  | jq '[.[] | {sig: .signature, time: (.timestamp | todate)}]'

```

1. Determine: does the attacker have enough votes to pass the proposal?

2. Can the proposal be vetoed or cancelled before execution?

## Mango-Style Flash Loan Vote Attack

```

Attack sequence:

1. Flash loan large amount of governance token

2. Deposit to governance (votes count immediately in some systems)

3. Create and vote for malicious treasury withdrawal proposal

4. Execute in same block (or immediately if no timelock)

5. Repay flash loan

Defense:

- Timelock > flash loan duration (most are same-block)

- Snapshot voting at block BEFORE proposal creation

- Minimum holding period before votes count

```

## Immediate Containment

```

[ ] Can the proposal be cancelled? (requires veto authority or supermajority)
[ ] Contact the governance multi-sig / council members immediately
[ ] Alert community via Discord/Twitter BEFORE execution (users can vote against)
[ ] Check if the protocol has an emergency veto mechanism
[ ] If proposal has execution timelock — you have time; use it
[ ] Load agents/comms-director.md — community must know to vote against

```

## Resolution Criteria

- Malicious proposal cancelled or voted down

- Governance token snapshot voting implemented (if not already)

- Timelock sufficient for community response confirmed

- Governance security review completed

## Detection Signals

| Signal | Threshold | Source |
| --- | --- | --- |
| Governance proposal with quorum met in < 1 hour | Any | On-chain event monitor |
| Large token transfer to voting wallet 24h before proposal | > 5% supply | Helius `getSignaturesForAddress` |
| Proposal calls `setAuthority` or `upgradeProgramData` | Any | Instruction discriminator filter |

## Escalation

| Time Elapsed | Action | Owner |
| --- | --- | --- |
| 0–10 min | Incident Commander activates, notifies core team | Incident Commander |
| 10–30 min | Contact governance platform (Realms/Squads) for emergency veto | Recovery Engineer |
| 30–60 min | Public governance transparency post; engage token holders | Comms Director |
| > 1 hour | Legal regulatory notification if treasury is at risk | Legal Response Agent |
