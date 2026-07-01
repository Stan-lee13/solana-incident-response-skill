# /freeze-checklist

Solana-specific program freeze and pause checklist for active or suspected incidents.

> Use when continued execution is riskier than pausing. Preserve evidence first unless funds are actively draining.

## Required Inputs

```text

1) Program ID(s): [PROGRAM_ID]

2) Upgrade authority: [single key / Squads v4 / SPL Governance / none / unknown]

3) Pause instruction exists? [yes/no/unknown]

4) Affected assets: [SOL / SPL / Token-2022 / LP / collateral / governance]

5) Frontend kill switch exists? [yes/no]

6) Monitoring provider: [Helius / QuickNode / Triton / self-hosted]

7) Exchanges listing affected token: [list / none / unknown]

8) Severity: [P0/P1/P2/P3]

```

## Freeze Decision Gate

```text
Confirmed or likely user-fund risk?
├── NO  → investigate with anomaly-detection; do not freeze yet
└── YES → continue
Can the program be paused without destructive state changes?
├── YES → call emergency pause first
└── NO  → use upgrade-authority freeze or frontend kill switch
Is upgrade authority compromised?
├── YES → do not use normal upgrade flow; escalate to legal/exchanges/Foundation
└── NO  → proceed through Squads, SPL Governance, or authority holder

```

## Step 0 — Evidence Snapshot

- [ ] Save current UTC time and latest slot.

- [ ] Save suspicious transaction signatures and candidate attacker wallets.

- [ ] Pull Helius Enhanced Transactions for affected program, vaults, mint, and attacker addresses.

- [ ] Snapshot program account and program-data account if upgradeable.

- [ ] Snapshot config PDA, vault PDAs, mint accounts, oracle accounts, and Squads v4 multisig state.

- [ ] Record `EVIDENCE_SNAPSHOT_COMPLETE = yes/no`.

- [ ] If funds are actively draining, capture minimum evidence and pause immediately.

## Step 1 — Activate Authority

- [ ] Incident Commander declares `FREEZE DECISION APPROVED` or `FREEZE DECISION PENDING`.

- [ ] Assign Technical Lead to execute transactions.

- [ ] Assign Forensic Investigator to validate evidence preservation.

- [ ] Assign Comms Director to prepare holding statement.

- [ ] Identify pause authority, upgrade authority, Squads signers, SPL Governance council, or mint freeze authority.

- [ ] Record signer availability: `reachable signers ___ / required ___`.

## Step 2 — Emergency Pause Instruction

- [ ] Verify instruction name from IDL: `pause`, `set_paused`, `setPause`, `setEmergencyMode`, or protocol-specific equivalent.

- [ ] Verify pause authority signer and config account.

- [ ] Call pause instruction with `paused = true`.

- [ ] If available, set `emergency_withdraw_only = true` only after confirming withdrawals are not the exploit path.

- [ ] Confirm transaction finalized.

- [ ] Verify config PDA reads `paused: true` or equivalent.

- [ ] Simulate or safely test one blocked instruction path.

- [ ] Record tx signature in incident log.

## Step 3 — Squads v4 / Upgrade Authority Path

- [ ] Open Squads v4 and confirm the controlled address is current upgrade or pause authority.

- [ ] Create proposal: `Emergency pause [PROGRAM_ID]` or `Emergency upgrade freeze [PROGRAM_ID]`.

- [ ] Attach exact pause or upgrade instruction data.

- [ ] Include severity, risk, and incident log excerpt in proposal description.

- [ ] Notify signers through secure signer channel.

- [ ] Collect threshold signatures; do not coordinate in public channels.

- [ ] Execute immediately when threshold is met.

- [ ] Save proposal ID, signer list, approval timestamps, and execution tx.

- [ ] If using `setUpgradeAuthority`, confirm BPFLoaderUpgradeable program-data account control.

- [ ] Set authority to emergency Squads v4 vault if a single key is at risk.

- [ ] Do not set authority to an individual wallet or make immutable during P0 unless approved.

## Step 4 — Mint Freeze / Token Integrity

- [ ] Verify mint address, mint authority, and `freeze_authority`.

- [ ] Freeze compromised token accounts if authority is valid and uncompromised.

- [ ] Stop all mint instructions if unauthorized minting occurred.

- [ ] Snapshot total supply before and after freeze.

- [ ] Notify exchanges of token integrity risk before publishing attacker addresses.

- [ ] Record freeze tx signatures and affected token accounts.

- [ ] Do not burn attacker tokens without legal and forensic approval.

## Step 5 — Frontend Kill Switch

- [ ] Disable deposit, swap, borrow, mint, stake, bridge, and governance buttons.

- [ ] Replace app entry with banner: `Protocol actions are temporarily paused. Do not interact until further notice.`

- [ ] Disable transaction construction APIs for affected instructions.

- [ ] Remove deep links that prefill affected transactions.

- [ ] Keep read-only portfolio pages only if they cannot produce transactions.

- [ ] Invalidate CDN cache and verify from a clean browser session.

- [ ] Record frontend deployment hash and timestamp.

## Step 6 — Helius / Automation Controls

- [ ] Keep Helius webhooks active for affected program, vault, mint, and attacker wallets.

- [ ] Suspend keepers, liquidators, rebalance bots, reward distributors, and auto-retry jobs touching affected instructions.

- [ ] Add alerts for new transactions touching affected vaults.

- [ ] Add alerts for BPFLoaderUpgradeable instructions touching program-data account.

- [ ] Export webhook payloads every 15 minutes during P0.

- [ ] Confirm monitoring still records slot, signature, and balance changes.

## Step 7 — Exchange Notification Sequence

- [ ] Prepare package: token symbol, mint, program ID, incident onset UTC/slot, affected wallets, requested action.

- [ ] Request lowest necessary action: deposit pause, withdrawal pause, then trading halt only if market integrity is compromised.

- [ ] Contact exchange security portal and account manager.

- [ ] Share verified signatures and addresses privately; do not share exploit mechanics.

- [ ] Ask for written receipt and ticket number.

- [ ] Follow up every 30 minutes until acknowledged during P0.

- [ ] Record contact, time, ticket, and response.

## Step 8 — Community Comms Timing

- [ ] If users are at immediate risk, publish holding statement within 15–30 minutes after approval.

- [ ] If pause is complete, say: `The affected program has been paused`.

- [ ] Do not publish exploit instruction, vulnerable account relationship, or attacker strategy.

- [ ] Do not claim all funds are safe unless forensics confirms.

- [ ] Include next update time in UTC and pin on official channels.

## Completion Output

```text
FREEZE STATUS: [complete / partial / failed]
PROGRAM PAUSED: [yes/no/n/a]
UPGRADE AUTHORITY SECURED: [yes/no/n/a]
MINT FREEZE COMPLETE: [yes/no/n/a]
FRONTEND DISABLED: [yes/no]
AUTOMATION SUSPENDED: [yes/no]
EXCHANGES NOTIFIED: [yes/no/n/a]
COMMUNITY HOLDING STATEMENT: [posted/pending/not needed]
REMAINING RISK: [high/medium/low]
NEXT OWNER: [Incident Commander / Recovery Engineer]

```
