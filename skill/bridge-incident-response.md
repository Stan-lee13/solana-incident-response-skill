# Bridge Incident Response

> Load this skill when a Solana protocol incident involves wrapped assets, cross-chain messages, bridge guardians, relayers, lockboxes, mint authorities, or canonical/token-bridge integrations.

Bridge incidents are P0 by default until proven otherwise. A bridge failure can convert a local exploit into ecosystem-wide insolvency because the same liability may exist on multiple chains at once.

---

## Activation Conditions

Load this skill immediately when any of these are true:

- Wrapped asset supply changes without matching lock/mint/burn/release events.
- Bridge mint authority, freeze authority, guardian set, relayer, or message verifier is compromised.
- Cross-chain message replay, duplicate VAA/message execution, or nonce reuse is suspected.
- Locked collateral on Solana no longer matches issued wrapped supply elsewhere.
- A bridge partner, exchange, or monitoring system reports invalid deposits or withdrawals.
- Wormhole, deBridge, LayerZero, Mayan, Circle CCTP, or custom bridge routes are involved in fund movement.
- An attacker is bridging stolen funds out of Solana and exchanges need urgent private evidence.

Trigger phrases:
- “Wrapped asset supply mismatch.”
- “Bridge mint compromised.”
- “Guardian signature issue.”
- “VAA replay.”
- “Cross-chain withdrawal exploit.”
- “Bridge collateral mismatch.”

---

## First 10 Minutes

Run in parallel with `skill/active-exploit-response.md`, `skill/program-freeze-and-pause.md`, and `agents/incident-commander.md`.

```text
T+0:00
[ ] Declare P0 unless forensics proves no cross-chain liability.
[ ] Start incident log with UTC time, Solana slot, and source chain block height.
[ ] Identify bridge path: [Wormhole / deBridge / LayerZero / CCTP / custom / aggregator].
[ ] Identify asset: source mint, wrapped mint, custody account, bridge program, destination chain contract.

T+2:00
[ ] Preserve evidence: Solana tx sigs, source chain tx hashes, VAA/message IDs, nonce/sequence, relayer logs.
[ ] Snapshot wrapped supply and custody balances.
[ ] Snapshot mint authority, freeze authority, guardian/validator set, and bridge config accounts.

T+5:00
[ ] Pause local deposits/withdrawals/claims if available.
[ ] Freeze affected mint/token accounts if authority is valid and legal approves.
[ ] Disable frontend bridge routes and aggregator links.
[ ] Notify bridge operator security contact privately.

T+10:00
[ ] Notify exchanges if deposits, withdrawals, or token integrity are affected.
[ ] Prepare public holding statement without exploit mechanics.
[ ] Decide whether to halt all cross-chain messaging or only affected asset routes.
```

---

## Severity Rules

| Condition | Severity | Reason |
|---|---:|---|
| Bridge mint authority compromised | P0 | Infinite wrapped supply risk |
| Guardian/validator signing set compromised | P0 | Cross-chain message validity at risk |
| Custody lockbox drained | P0 | Issued wrapped supply may be unbacked |
| Replayable message confirmed | P0 | Repeatable extraction path |
| Attacker bridging stolen funds to CEX | P0/P1 | Time-sensitive freeze opportunity |
| Single failed bridge tx, no state change | P2 | Investigate before public escalation |
| UI route points to wrong bridge contract | P1 | User-drain risk even without program exploit |

P0 override: if supply parity cannot be proven in 10 minutes, treat as P0.

---

## Bridge Forensics Methodology

### 1. Establish chain-of-custody across chains

For each affected asset, record:

```text
SOURCE_CHAIN: [Ethereum / Solana / Sui / Base / Arbitrum / etc]
SOURCE_ASSET: [contract or mint]
BRIDGE_PROGRAM_OR_CONTRACT: [address]
MESSAGE_ID: [VAA / nonce / sequence / message hash]
SOLANA_TX: [signature]
DESTINATION_TX: [hash]
CUSTODY_ACCOUNT: [address]
WRAPPED_MINT: [mint]
SUPPLY_BEFORE: [amount]
SUPPLY_AFTER: [amount]
```

### 2. Validate supply parity

For lock-and-mint bridges:

```text
locked_source_collateral >= wrapped_destination_supply
```

For burn-and-release bridges:

```text
burned_wrapped_amount == released_source_amount
```

If parity fails:
- classify as token integrity risk
- notify token-launch skill if launch/vesting/LP markets are affected
- notify exchanges privately before public attacker-address disclosure

### 3. Identify the failed validation layer

Classify root cause:

| Class | Evidence |
|---|---|
| Guardian/signature compromise | valid-looking bridge message signed by unauthorized or compromised set |
| Message replay | same nonce/sequence/message hash executed more than once |
| Finality failure | source-chain tx not final but destination minted/released |
| Relayer compromise | relayer submitted altered payload or wrong recipient |
| Mint authority compromise | supply changed without valid bridge message |
| Custody compromise | lockbox/token account drained directly |
| UI route compromise | users sent funds to wrong route despite bridge core being intact |

### 4. Preserve bridge-specific evidence

Save before any state changes:
- raw Solana transaction JSON and logs
- source-chain transaction receipts
- VAA/message payload bytes
- guardian/validator signature set
- sequence number, nonce, emitter chain, emitter address
- bridge config and guardian-set accounts
- wrapped mint account and token supply snapshots
- custody token account balances
- relayer API logs and request IDs

---

## Containment Decision Tree

```text
Is mint authority or bridge verifier compromised?
├── YES → Freeze mint/accounts if possible; notify exchanges; halt all affected routes.
└── NO
    Is custody collateral at risk?
    ├── YES → Pause withdrawals and move controllable collateral only with IC/legal approval.
    └── NO
        Is exploit limited to frontend route or aggregator config?
        ├── YES → Disable UI route; keep bridge core monitored.
        └── NO → Pause affected bridge program/component pending forensics.
```

---

## Partner Escalation

Contact bridge partners within 15 minutes of P0 classification.

Private package:

```text
SUBJECT: [URGENT] Bridge Security Incident — [ASSET] — Requesting route pause
Protocol: [name]
Affected asset/mint: [mint/contract]
Bridge route: [source chain] → [destination chain]
Incident onset: [UTC] / Solana slot [slot] / source block [height]
Known txs: [Solana sigs + source chain hashes]
Message IDs: [VAA / nonce / sequence]
Requested action: [pause route / freeze relayer / halt mint / reject message IDs]
Point of contact: [name, role, secure channel]
```

Do not post guardian-set, verifier-bypass, or replay details publicly before the bridge partner confirms containment.

---

## Exchange and Market Actions

Notify exchanges when:
- wrapped asset supply may be unbacked
- mint authority is compromised
- attacker funds are moving to deposit addresses
- bridge deposits/withdrawals could credit invalid assets

Request sequence:
1. pause deposits for affected mint/symbol
2. pause withdrawals if invalid assets may leave exchange
3. trading halt only if market integrity or supply validity is compromised
4. provide private tx evidence and ask for ticket number

DEX/aggregator actions:
- ask Jupiter/integrators to disable affected route labels if UI route risk exists
- alert pool operators if LP tokens or wrapped assets are contaminated
- avoid public “blacklist” language unless legal approves

---

## Public Communication Boundaries

Safe early language:

```text
We are investigating a cross-chain asset integrity issue affecting [ASSET/ROUTE].
Out of caution, bridge deposits and withdrawals for the affected route are paused.
Do not use third-party routes involving [ASSET] until further notice.
Next update by [TIME UTC].
```

Do not say:
- “the bridge is hacked” until confirmed
- “wrapped assets are unbacked” until supply parity is verified
- “guardian keys are compromised” before bridge partner/legal approval
- “trading is halted” unless exchanges confirm
- exact replay or signature-validation mechanics before containment

---

## Recovery Paths

| Scenario | Recovery owner | Path |
|---|---|---|
| Invalid wrapped supply minted | Token Launch + Recovery Engineer | freeze/burn plan, exchange reconciliation, user accounting |
| Custody drained | Recovery Engineer + Legal | trace/freeze funds, compensation model, partner liability review |
| Message replay | Bridge partner + Engineering | block executed message IDs, patch verifier, replay scan |
| Relayer compromise | Bridge partner | rotate relayer keys, reject bad payloads, audit logs |
| UI route compromise | UX + Comms | drain-prevention UX, official route warning, domain/package cleanup |

Redeploy or resume only after:
- supply parity is proven or reconciliation plan is approved
- bridge partner confirms route safety
- exchange deposit/withdrawal state is coordinated
- monitoring rules cover replay, supply delta, custody delta, and route anomalies
- public update explains user action without exposing exploit mechanics

---

## Post-Incident Hardening

Every bridge incident post-mortem must produce:

- Observability action: alert on supply/custody parity, sequence reuse, and bridge-program authority changes.
- Token Launch action: mint/freeze/treasury authority review and exchange notification runbook.
- UX action: bridge route risk warnings and official route verification UI.
- DePIN action: if oracle/physical proofs influence bridge eligibility, harden proof quorum and source-of-truth rules.

Minimum monitoring rules:

```text
[ ] Wrapped supply delta without matching source-chain event.
[ ] Custody account balance delta without valid bridge release.
[ ] Duplicate message ID / nonce / sequence execution.
[ ] Guardian set or verifier config change.
[ ] Mint authority or freeze authority change.
[ ] High-value bridge outflow to known CEX cluster.
```
