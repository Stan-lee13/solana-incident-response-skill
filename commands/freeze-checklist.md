# /freeze-checklist

Step-by-step Solana-specific program freeze checklist. Outputs a copy/paste-ready checklist with exact instructions based on your authority setup.

## Usage

```text
Run /freeze-checklist — program [PROGRAM_ID], cluster [mainnet-beta], upgrade authority [single keypair / Squads v4], pause switch [yes/no/unknown], mint freeze authority [yes/no], signers reachable [X]
```

## What the agent will produce

A checkbox checklist with:
- Solana-specific containment actions (pause, upgrade-authority actions, mint freeze)
- Frontend + bot kill switch sequence
- Helius webhook/indexer suspension steps
- Exchange notification sequence and comms timing gates
- Verification step after every action
- Explicit branching based on authority and pause capability

---

## Freeze Checklist (Filled In By The Agent)

```text
PROGRAM FREEZE CHECKLIST
Program: [PROGRAM_ID]
Cluster: [mainnet-beta]
UTC start time: [TIME]
Authority: [single keypair / Squads v4]
Pause switch: [yes/no/unknown]
Mint freeze authority: [yes/no + which mint(s)]

PHASE 0 — EVIDENCE FIRST (0–2 minutes)

[ ] 0.1 Create incident log entry with UTC time and scope.
[ ] 0.2 Preserve transaction evidence (do before state changes):
      - Export last ~100 program transactions via Helius Enhanced Transactions API (save JSON).
      - Example pull:
        curl "https://api.helius.xyz/v0/addresses/[PROGRAM_ID]/transactions?api-key=[HELIUS_KEY]&limit=100" > helius_program_txs_[UTC].json
[ ] 0.3 Snapshot critical accounts before mitigation:
      solana account [PROGRAM_ID] --output json > program_account_[UTC].json
      solana program show [PROGRAM_ID] --url mainnet-beta > program_show_[UTC].txt
      - If you know key vault PDAs or fee vault token accounts:
        solana account [VAULT_OR_CONFIG_PDA] --output json > vault_or_config_[UTC].json

PHASE 1 — OFF-CHAIN STOPGAPS (0–5 minutes)

[ ] 1.1 Frontend kill switch (stop new user interactions):
      - Put the app into maintenance mode OR hard-disable all write paths.
      - Remove/disable “deposit”, “borrow”, “swap”, “mint”, “stake” buttons.
[ ] 1.2 Backend write kill switch (if you run a tx relayer or API):
      - Disable any endpoint that returns pre-built transactions for signing.
      - Block any endpoint that submits transactions server-side.
[ ] 1.2 Stop bots/keepers/liquidators/cron jobs controlled by your team.
[ ] 1.3 Suspend any automation that triggers writes based on webhooks/indexers.
[ ] 1.4 Anti-phishing posture:
      - Pin a “do not click links” warning in Discord.
      - Ensure only one official “updates” link is shared by moderators.

PHASE 2 — ON-CHAIN CONTAINMENT (2–20 minutes)

[ ] 2.1 If the program has an emergency pause instruction:
      - Execute pause immediately (single key or via Squads proposal).
      - Typical instruction names (choose the real one from your IDL):
        pause() / set_paused(true) / emergency_pause() / setEmergencyMode(true)
      - Single keypair execution example (Anchor-style):
        anchor run emergency-pause -- --provider.cluster mainnet-beta
      - Squads v4 execution:
        create a multisig proposal that invokes the pause instruction on [PROGRAM_ID]
      - Verification: your own test call to a critical instruction fails with “paused” error.

[ ] 2.2 If mint freeze authority exists for impacted mint(s):
      - Identify impacted mint(s): [MINT_1], [MINT_2]
      - Freeze attacker-associated token accounts when identified.
        spl-token accounts --owner [ATTACKER_WALLET] --mint [MINT]
        spl-token freeze-account [ATTACKER_ATA] --mint [MINT] --freeze-authority [FREEZE_AUTHORITY_KEYPAIR]
      - Freeze protocol-owned token accounts if needed to stop downstream movement.
      - If delegation abuse is suspected:
        spl-token revoke [TOKEN_ACCOUNT]
      - Verification: transfers fail for frozen accounts.

[ ] 2.3 If the exploit path is upgrade-based or you need to prevent further upgrades:
      - Ensure upgrade authority is locked to the correct multisig vault.
      - If your incident plan allows making the program immutable, set upgrade authority accordingly (irreversible).
      - Single keypair (solana CLI):
        solana program set-upgrade-authority [PROGRAM_ID] \
          --new-upgrade-authority [NEW_AUTHORITY_PUBKEY_OR_NONE] \
          --upgrade-authority [CURRENT_AUTHORITY_KEYPAIR] \
          --url mainnet-beta
      - Squads v4 (conceptual instruction to execute via multisig):
        Program: BPFLoaderUpgradeab1e11111111111111111111111111
        Instruction: SetUpgradeAuthority (for the program’s ProgramData account)
      - Verification: solana program show reflects expected authority state.

[ ] 2.4 If there is NO pause mechanism and funds are still at risk:
      - Emergency upgrade path (only if upgrade authority reachable):
        a) deploy a minimal “paused” version that blocks risky instructions
        b) verify every critical instruction now fails safely
      - Anchor-style deployment outline:
        anchor build
        anchor upgrade target/deploy/[PROGRAM].so --program-id [PROGRAM_ID] --provider.cluster mainnet-beta
      - Verification: exploit transaction pattern now fails deterministically.

PHASE 3 — HELIUS / INDEXER SUSPENSION (5–15 minutes)

[ ] 3.1 Disable/suspend Helius webhooks that cause automated writes.
[ ] 3.2 If you cannot “disable” a webhook cleanly, remove its triggering address set:
      - Replace accountAddresses with an empty list or a non-existent address, depending on your integration.
[ ] 3.3 If using Helius dashboard:
      - Webhooks → locate any webhook used by keepers/automation → disable or delete it.
[ ] 3.2 Ensure monitoring webhooks remain active (read-only alerting is allowed).
[ ] 3.3 Verification: no automation is emitting new write transactions.

PHASE 4 — VERIFICATION (10–30 minutes)

[ ] 4.1 Verify containment using evidence:
      - No new successful exploit signatures in the last 5–10 minutes.
[ ] 4.2 Verify that your own “canary” transaction fails safely (if paused) or succeeds safely (if expected).
[ ] 4.2 Record the containment point:
      - containment UTC time + slot number (from forensics).
[ ] 4.3 Preserve post-mitigation snapshots:
      - program/vault/oracle account snapshots for comparison.

PHASE 5 — EXCHANGE NOTIFICATION SEQUENCE (WHEN APPLICABLE)

[ ] 5.1 If funds are moving toward a CEX or your token market is destabilizing:
      - Notify exchanges with an evidence pack (addresses + signatures + UTC/slot).
      - Use the exchange outreach templates in agents/comms-director.md.
[ ] 5.2 If requesting a trading halt:
      - Provide token mint, tickers, primary pools, and what user harm the halt prevents.
[ ] 5.3 Log every outreach:
      - who was contacted, when (UTC), what evidence was provided.

PHASE 6 — COMMUNITY COMMS TIMING (GATED)

[ ] 6.1 Draft initial notice immediately (do not publish without IC approval).
[ ] 6.2 Publish only what is confirmed + user actions + next update time (UTC).
[ ] 6.3 Publish “no links except official” warning to reduce phishing during crisis.
[ ] 6.4 Commit to update cadence and do not miss it.

NEXT FILES

- agents/incident-commander.md (decision gates + escalation)
- agents/forensic-investigator.md (entry point + fund flow)
- agents/comms-director.md (public + exchange comms)
- agents/recovery-engineer.md (accounting + compensation + redeploy)
- skill/program-freeze-and-pause.md (pause patterns)
```
