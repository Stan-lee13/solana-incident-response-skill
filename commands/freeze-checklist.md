# /freeze-checklist

Step-by-step Solana-specific program freeze checklist. Outputs a copy/paste-ready checklist with exact instructions based on your authority setup.

## Usage

```text
Run /freeze-checklist — program [PROGRAM_ID], cluster [mainnet-beta], upgrade authority [single keypair / Squads v4], pause switch [yes/no/unknown], mint freeze authority [yes/no], signers reachable [X]
```

## What the agent will produce

A checkbox checklist with:
- Authority classification and execution-path routing before any action is taken
- Solana-specific containment actions (pause, upgrade-authority actions, mint freeze)
- Frontend + bot + CDN kill switch sequence
- Jito bundle submission halt for keeper operations
- Helius webhook/indexer suspension steps
- Oracle suspension via Pyth/Switchboard for price-manipulation exploits
- Exchange notification sequence with compliance portal links
- Verification matrix after every major action
- Explicit branching based on authority and pause capability

---

## AUTHORITY DECISION TREE

> **Run this classification step BEFORE any action below. Choose exactly one path.**

```
AUTHORITY DETECTION
────────────────────────────────────────────────────────────────
Single keypair (emergency) → Fast path: direct CLI execution
                             Skip Squads steps. Sign with hot key.
                             Estimated execution time: 30–90 seconds.

Squads v4 (standard)       → Multisig path: proposal + signers.
                             Estimated execution time: 5–20 minutes
                             (depends on threshold + signer latency).
                             Alert all required co-signers NOW via Signal/phone.

No upgrade authority        → Program is immutable. Cannot upgrade or pause
(immutable program)           via authority transfer. Contact your security firm
                             (Ottersec, Neodyme, OtterSec, Trail of Bits)
                             immediately. All containment is off-chain only.

Authority unknown           → Run FIRST before proceeding:
                               solana program show [PROGRAM_ID] --url mainnet-beta
                             Look for "Upgrade Authority" field in output.
                             If blank → immutable path above.
────────────────────────────────────────────────────────────────
```

> Record detected authority type here: **[FILL IN]** before proceeding to Phase 0.

---

## Freeze Checklist (Filled In By The Agent)

```text
PROGRAM FREEZE CHECKLIST
Program:             [PROGRAM_ID]
Cluster:             [mainnet-beta]
UTC start time:      [TIME]
Authority type:      [single keypair / Squads v4 / immutable / unknown]
Squads multisig:     [MULTISIG_PUBKEY — leave blank if single keypair]
Pause switch:        [yes / no / unknown]
Mint freeze auth:    [yes / no + which mint(s)]
Signers reachable:   [X of Y]
Jito keeper ops:     [yes / no]
Own RPC node:        [yes / no]
Cloudflare account:  [yes / no]

═══════════════════════════════════════════════════════════════
PHASE 0 — EVIDENCE FIRST (0–2 minutes)
═══════════════════════════════════════════════════════════════

⚠ WHY THIS MATTERS: Accounts closed or overwritten during mitigation
  destroy forensic evidence permanently. During the Cashio exploit
  (Mar 2022, $48M), responders upgraded the program before fully
  capturing account state — key on-chain evidence was lost, complicating
  recovery and attribution. Do NOT skip Phase 0 even if the exploit
  is still active.

[ ] 0.1 Create incident log entry with UTC timestamp and initial scope.
      - File name convention: incident_[YYYYMMDD_HHMM]_[PROGRAM_SHORT].log
      - Record current slot: solana slot --url mainnet-beta

[ ] 0.2 Capture full transaction evidence via Helius Enhanced Transactions API:

      # Pull last 100 transactions for the program, parse key fields
      curl -s "https://api.helius.xyz/v0/addresses/[PROGRAM_ID]/transactions\
?api-key=[HELIUS_KEY]&limit=100&type=UNKNOWN" \
        > helius_program_txs_[UTC].json

      # JQ: extract signatures, timestamps, accounts involved, and fee payers
      jq '[.[] | {
        signature: .signature,
        timestamp: .timestamp,
        slot:      .slot,
        fee_payer: .feePayer,
        accounts:  [.accountData[].account],
        native_transfers: .nativeTransfers,
        token_transfers:  .tokenTransfers
      }]' helius_program_txs_[UTC].json > helius_parsed_[UTC].json

      # JQ: filter to only transactions that succeeded (no error field)
      jq '[.[] | select(.transactionError == null)]' \
        helius_program_txs_[UTC].json > helius_successful_[UTC].json

      # Pull enhanced detail for the single most suspicious transaction:
      curl -s "https://api.helius.xyz/v0/transactions/?api-key=[HELIUS_KEY]" \
        -X POST \
        -H "Content-Type: application/json" \
        -d '{"transactions":["[SUSPICIOUS_SIGNATURE]"]}' \
        > helius_tx_detail_[SUSPICIOUS_SIG_SHORT]_[UTC].json

[ ] 0.3 Snapshot critical accounts before any state change:
      solana account [PROGRAM_ID] --output json-compact \
        > program_account_[UTC].json
      solana program show [PROGRAM_ID] --url mainnet-beta \
        > program_show_[UTC].txt

      # Snapshot known vault/config PDAs (add all that apply):
      solana account [VAULT_PDA]   --output json-compact > vault_[UTC].json
      solana account [CONFIG_PDA]  --output json-compact > config_[UTC].json
      solana account [ORACLE_PDA]  --output json-compact > oracle_[UTC].json

      # If oracle feed accounts are involved:
      solana account [PYTH_PRICE_ACCOUNT]  --output json-compact \
        > pyth_price_[UTC].json

[ ] 0.4 Identify the attacker's wallet and any intermediary wallets:
      - Pull from the transaction log above.
      - Check Solscan or Step Finance for downstream movement.
      - Note: do NOT attempt to interact with attacker wallets yet.

═══════════════════════════════════════════════════════════════
PHASE 1 — OFF-CHAIN STOPGAPS (0–5 minutes, parallel with Phase 0)
═══════════════════════════════════════════════════════════════

[ ] 1.1 Frontend kill switch — halt all new user interactions:
      - Enable hard maintenance mode: return HTTP 503 on all write routes.
      - Remove or disable all transact buttons: deposit / borrow / swap /
        mint / stake / withdraw.
      - If using a feature-flag system (LaunchDarkly, Growthbook, etc.):
        flip the global "disable_writes" flag to true immediately.
      - Verification: attempt a write action manually; confirm 503 or
        "maintenance" UI appears.

[ ] 1.2 Cloudflare / CDN kill switch — activate Under Attack Mode:
      - Log in to dash.cloudflare.com → Security → Settings.
      - Set Security Level to "Under Attack" (JS challenge on all requests).
      - OR: if you have Cloudflare Workers routing write traffic, deploy a
        Worker with:
          return new Response('Maintenance', { status: 503 });
        on all POST routes that build or relay transactions.
      - Alternative (AWS CloudFront): update the distribution behavior to
        return a 503 custom error page; invalidate the cache immediately.
      - Verification: external curl of a write endpoint returns 503 or JS challenge.

[ ] 1.3 Backend write kill switch — disable tx-relay APIs:
      - Block or return 503 on any endpoint that emits pre-built transactions
        for signing or submits transactions server-side.
      - If using a feature flag or env var, set WRITES_ENABLED=false and
        restart the service (or hot-patch with nginx/Caddy block rule).
      - Verification: confirm no server-side tx submissions in logs.

[ ] 1.4 Jito bundle submission halt (if your protocol uses Jito bundles
        for keeper, liquidator, or arbitrage operations):
      - Locate the keeper process / cron that builds and submits bundles.
      - Kill the process: kill -9 [PID] or systemctl stop [keeper-service].
      - If using Jito Block Engine API directly, revoke or rotate the
        Jito auth keypair so in-flight bundles are rejected:
          - Rotate the keypair used to sign bundle submissions.
          - Remove the old key from your secrets manager / env immediately.
      - Disable the cron entry: crontab -e → comment out keeper lines.
      - Verification: no new bundles appear in Jito explorer for your
        auth keypair over the next 60 seconds.

[ ] 1.5 Own RPC node — restrict write-heavy endpoints (if applicable):
      - If running Triton, Helius private RPC, or a self-hosted validator
        RPC, immediately rate-limit or block sendTransaction and
        simulateTransaction endpoints.
      - nginx example (add to server block, reload nginx):
          location /sendTransaction {
              return 503 "Frozen";
          }
      - Alternatively, use your RPC provider's dashboard to disable the
        sendTransaction method or restrict by IP allowlist.
      - Verification: solana transfer attempt via your RPC returns
        503 or method-not-found error.

[ ] 1.6 Stop all team-controlled bots, keepers, liquidators, cron jobs:
      - Use your runbook's "halt all automation" procedure.
      - Confirm via your process monitor (PM2, systemd, k8s) that no
        keeper processes are running.

[ ] 1.7 Suspend webhook-triggered automation:
      - Any automation that listens to Helius/Triton webhooks and submits
        write transactions must be stopped here.
      - See Phase 3 for Helius webhook suspension steps.

[ ] 1.8 Anti-phishing posture in community channels:
      - Pin "Do NOT click any links. We will only post updates at [OFFICIAL_URL]."
        in Discord, Telegram, and X/Twitter.
      - Ensure only incident-commander-approved handles post updates.

═══════════════════════════════════════════════════════════════
PHASE 2 — ON-CHAIN CONTAINMENT (2–20 minutes)
═══════════════════════════════════════════════════════════════

[ ] 2.1 PAUSE INSTRUCTION — execute if the program has one:

    ── SINGLE KEYPAIR PATH ──────────────────────────────────────
      # Anchor-style (common instruction names from your IDL):
      anchor run emergency-pause -- --provider.cluster mainnet-beta

      # Or via direct CLI if you have a dedicated pause script:
      solana program invoke [PROGRAM_ID] \
        --keypair [AUTHORITY_KEYPAIR.json] \
        --url mainnet-beta \
        -- [PAUSE_INSTRUCTION_DISCRIMINATOR_HEX]

    ── SQUADS V4 MULTISIG PATH ──────────────────────────────────
      # Alert co-signers FIRST via Signal emergency group / phone list.
      # Required signers: [LIST NAMES AND SIGNAL HANDLES HERE]
      # Signing threshold: [X of Y]

      // Step 1: Create the proposal (run by any member)
      const tx = await multisig.rpc.proposalCreate({
        connection,
        feePayer:        proposerKeypair.publicKey,
        multisigPda:     new PublicKey("[MULTISIG_PUBKEY]"),
        transactionIndex: await multisig.accounts
                            .multisig.fetch(multisigPda)
                            .then(m => m.transactionIndex + 1n),
        creator:         proposerKeypair,
      });
      console.log("Proposal tx:", tx);

      // Step 2: Attach the pause vault transaction
      await multisig.rpc.vaultTransactionCreate({
        connection,
        feePayer:        proposerKeypair.publicKey,
        multisigPda:     new PublicKey("[MULTISIG_PUBKEY]"),
        transactionIndex: proposalTransactionIndex,
        creator:         proposerKeypair.publicKey,
        vaultIndex:      0,
        ephemeralSigners: 0,
        transactionMessage: pauseTransactionMessage, // your built Message
        memo:            "EMERGENCY PAUSE [UTC_TIME]",
      });

      // Step 3: Each required signer approves
      await multisig.rpc.proposalApprove({
        connection,
        feePayer:        signerKeypair.publicKey,
        multisigPda:     new PublicKey("[MULTISIG_PUBKEY]"),
        transactionIndex: proposalTransactionIndex,
        member:          signerKeypair,
      });

      // Step 4: Execute once threshold is met
      await multisig.rpc.proposalExecute({
        connection,
        feePayer:        executorKeypair.publicKey,
        multisigPda:     new PublicKey("[MULTISIG_PUBKEY]"),
        transactionIndex: proposalTransactionIndex,
        member:          executorKeypair,
      });

      # Co-signer contact list (fill in before incident):
      # Name | Signal handle | Emergency phone | Time zone
      # ─────┼───────────────┼─────────────────┼──────────
      # [1]  | @[handle]     | +X-XXX-XXX-XXXX | [TZ]
      # [2]  | @[handle]     | +X-XXX-XXX-XXXX | [TZ]
      # [3]  | @[handle]     | +X-XXX-XXX-XXXX | [TZ]

    ── VERIFICATION ─────────────────────────────────────────────
      - Submit a canary call to a critical instruction.
      - Confirm it fails with "paused" / "emergency mode" error.
      - Record the pause slot: solana slot --url mainnet-beta

[ ] 2.2 WHAT TO DO IF THE PAUSE TRANSACTION FAILS OR REVERTS:

    [ ] 2.2a Diagnose failure mode:
        solana confirm [PAUSE_TX_SIGNATURE] --url mainnet-beta
        solana logs [PAUSE_TX_SIGNATURE] --url mainnet-beta
        # Look for: program error, fee-payer insufficient, blockhash expired.

    [ ] 2.2b If attacker is front-running your pause tx (sandwich blocking):
        - Use Jito bundles to force-land the pause with a tip:

        // Build the pause instruction as a versioned transaction, then:
        const bundle = new JitoBundle([pauseVersionedTx], connection);
        bundle.addTip({
          tipAccount: getTipAccount(),  // use Jito tip accounts list
          lamports:   1_000_000,        // 0.001 SOL minimum; raise if needed
        });
        const result = await jitoClient.sendBundle(bundle);
        console.log("Bundle UUID:", result.uuid);

        - Poll bundle status:
        curl https://mainnet.block-engine.jito.wtf/api/v1/bundles \
          -X POST -H "Content-Type: application/json" \
          -d '{"jsonrpc":"2.0","id":1,"method":"getBundleStatuses",
               "params":[["[BUNDLE_UUID]"]]}'

    [ ] 2.2c If pause still fails after Jito bundle attempt — emergency upgrade
        (LAST RESORT — requires upgrade authority):
        # Build a minimal "always-paused" program that returns an error
        # on every critical instruction:
        anchor build
        # Review the built .so before deploying:
        ls -lh target/deploy/[PROGRAM].so
        # Deploy the emergency paused binary:
        anchor upgrade target/deploy/[PROGRAM].so \
          --program-id [PROGRAM_ID] \
          --provider.cluster mainnet-beta \
          --provider.wallet [UPGRADE_AUTHORITY_KEYPAIR.json]
        # Verification: every instruction now returns ProgramError::Custom(0)
        # or equivalent "paused" error.

[ ] 2.3 Mint freeze — freeze attacker-associated token accounts:
      # Identify attacker ATAs:
      spl-token accounts --owner [ATTACKER_WALLET] --mint [MINT] \
        --url mainnet-beta
      # Freeze each identified account:
      spl-token freeze-account [ATTACKER_ATA] \
        --mint [MINT] \
        --freeze-authority [FREEZE_AUTHORITY_KEYPAIR.json] \
        --url mainnet-beta
      # If delegation abuse is involved, revoke delegate first:
      spl-token revoke [TOKEN_ACCOUNT] \
        --owner [OWNER_KEYPAIR.json] \
        --url mainnet-beta
      # Verification: token transfer from frozen account fails with
      # "Account is frozen" error.

[ ] 2.4 Upgrade authority lock — prevent unauthorized upgrades:
    ── SINGLE KEYPAIR ───────────────────────────────────────────
      solana program set-upgrade-authority [PROGRAM_ID] \
        --new-upgrade-authority [NEW_AUTHORITY_OR_NONE] \
        --upgrade-authority [CURRENT_AUTHORITY_KEYPAIR.json] \
        --url mainnet-beta
      # Pass --final to make immutable (IRREVERSIBLE — confirm before running).

    ── SQUADS V4 ────────────────────────────────────────────────
      # Instruction target:
      #   Program: BPFLoaderUpgradeab1e11111111111111111111111111
      #   Instruction: SetUpgradeAuthority
      #   Accounts: programData PDA, current authority (multisig vault PDA),
      #             new authority pubkey
      # Build the SetUpgradeAuthority instruction and attach via
      # vaultTransactionCreate (same flow as 2.1 above).

    ── VERIFICATION ─────────────────────────────────────────────
      solana program show [PROGRAM_ID] --url mainnet-beta
      # Confirm "Upgrade Authority" field matches expected new value.

═══════════════════════════════════════════════════════════════
PHASE 3 — HELIUS / INDEXER SUSPENSION (5–15 minutes)
═══════════════════════════════════════════════════════════════

[ ] 3.1 Log in to Helius dashboard → Webhooks.
[ ] 3.2 Disable every webhook that drives automated write transactions:
      - Identify by accountAddresses containing your program/vault addresses.
      - Toggle "Active" off, or click Delete for non-essential webhooks.
[ ] 3.3 If you cannot cleanly disable, neuter the address set:
      - PATCH the webhook's accountAddresses to [] or a known-safe sentinel.
      - Helius API example:
        curl -X PUT "https://api.helius.xyz/v0/webhooks/[WEBHOOK_ID]\
?api-key=[HELIUS_KEY]" \
          -H "Content-Type: application/json" \
          -d '{"accountAddresses":[],"webhookURL":"[YOUR_URL]"}'
[ ] 3.4 Keep read-only monitoring webhooks ACTIVE — alerting is allowed.
[ ] 3.5 Verification: zero new write transactions emitted by your automation
      in the next 60-second observation window.

═══════════════════════════════════════════════════════════════
PHASE 3.5 — ORACLE SUSPENSION (if exploit involves price manipulation)
═══════════════════════════════════════════════════════════════

Trigger this phase if: attacker is manipulating oracle prices to
inflate collateral, drain lending pools, or spoof swap rates.
(Reference: Mango Markets Oct 2022 $115M — oracle price manipulation
of MNGO to inflate collateral and borrow against it.)

[ ] 3.5.1 Identify which oracle(s) are being manipulated:
        - Pyth price accounts: check your config PDA for stored feed pubkeys.
        - Switchboard aggregator accounts: same.
        - Log current reported price vs. true market price.

[ ] 3.5.2 PYTH NETWORK — emergency publisher coordination:
        - Contact: https://pyth.network/contact (use "Security / Emergency"
          category in the subject).
        - Direct Telegram: reach out to the Pyth Discord #emergency-contact
          channel or known Pyth team contacts.
        - Request: flag the feed as "potentially manipulated"; Pyth
          publishers can apply a confidence interval so wide the
          price becomes unusable.
        - Provide: feed account pubkey, suspicious tx signatures,
          reported price vs. true market price, UTC timestamp range.

[ ] 3.5.3 SWITCHBOARD — emergency oracle governance actions:
        - Switchboard aggregators have an "authority" that can lock feeds.
        - If your protocol is also the aggregator authority:
          # Lock the aggregator (stops new rounds):
          switchboard aggregator lock [AGGREGATOR_PUBKEY] \
            --keypair [AUTHORITY_KEYPAIR.json] \
            --cluster mainnet-beta
        - If Switchboard Labs is the authority, contact:
          discord.gg/switchboardxyz → #emergency channel.
        - Provide same evidence package as Pyth above.

[ ] 3.5.4 Disable oracle-dependent instructions via config PDA update:
        - If your program reads a config PDA to determine which oracle
          to consult, update that config to point to a known-safe
          sentinel account (or set an emergency oracle_suspended flag):
          # Example Anchor-style call (adapt to your IDL):
          anchor run set-oracle-config -- \
            --provider.cluster mainnet-beta \
            --oracle-suspended true
        - Alternatively, update the config via Squads proposal (follow
          the vaultTransactionCreate flow from Phase 2.1).
        - Verification: any instruction that reads the oracle now returns
          "oracle suspended" or equivalent error.

[ ] 3.5.5 Record oracle state snapshot:
        solana account [PYTH_PRICE_ACCOUNT] --output json-compact \
          > pyth_price_post_incident_[UTC].json
        solana account [SWITCHBOARD_AGGREGATOR] --output json-compact \
          > switchboard_post_incident_[UTC].json

═══════════════════════════════════════════════════════════════
PHASE 4 — VERIFICATION (10–30 minutes)
═══════════════════════════════════════════════════════════════

[ ] 4.1 Confirm no new successful exploit-pattern transactions in the
      last 5–10 minutes (re-pull Helius enhanced txs, compare).
[ ] 4.2 Submit a canary transaction that should now fail (e.g., the
      exploit instruction); confirm it fails with expected error.
[ ] 4.3 Record containment point:
      - Containment UTC time: [TIME]
      - Containment slot:     solana slot --url mainnet-beta → [SLOT]
[ ] 4.4 Capture post-mitigation account snapshots for diff comparison:
      solana account [PROGRAM_ID]  --output json-compact > program_post_[UTC].json
      solana account [VAULT_PDA]   --output json-compact > vault_post_[UTC].json
      solana account [CONFIG_PDA]  --output json-compact > config_post_[UTC].json
[ ] 4.5 Confirm upgrade authority state reflects intended configuration:
      solana program show [PROGRAM_ID] --url mainnet-beta

═══════════════════════════════════════════════════════════════
PHASE 5 — EXCHANGE NOTIFICATION SEQUENCE (WHEN APPLICABLE)
═══════════════════════════════════════════════════════════════

Trigger if: funds are moving toward a CEX, your token market is
destabilizing, or attacker is attempting to convert via exchange.

[ ] 5.1 Prepare the evidence pack before contacting any exchange:
      - Attacker wallet address(es)
      - Suspicious transaction signatures (list all)
      - UTC slot range of the exploit
      - Token mint address and ticker
      - Amount stolen (USD estimate)
      - On-chain evidence JSON (from Phase 0)

[ ] 5.2 BINANCE — law enforcement / security portal:
      URL:     https://www.binance.com/en/support/law-enforcement
      Method:  Submit via the Law Enforcement Request form.
      Subject: "Security Emergency – [TOKEN] – [PROTOCOL_NAME] – [UTC_DATE]"
      Include: evidence pack from 5.1 above.
      Escalate via: @BinanceHelpDesk on X if no response in 30 minutes.

[ ] 5.3 COINBASE — exchange law enforcement API / security:
      URL:     https://docs.coinbase.com/exchange/reference/exchangerestapi_postlawenforcement
      Method:  POST to the law enforcement endpoint (requires registration).
      Email:   security@coinbase.com as parallel outreach.
      Subject: "Urgent: Stolen Funds – [TOKEN] – [PROTOCOL_NAME] – [UTC_DATE]"
      Include: evidence pack from 5.1 above.

[ ] 5.4 OKX — security team direct contact:
      Email:   security@okx.com
      Subject: "URGENT Security Emergency | [TOKEN] | Stolen Funds |
                [PROTOCOL_NAME] | [UTC_DATE_TIME]"
      Body must include in this exact order:
        1. Protocol name and description
        2. Attacker wallet address(es)
        3. Transaction signatures
        4. Token mint + ticker
        5. USD amount at risk
        6. UTC timestamp of exploit onset
        7. Requested action (freeze deposits / halt trading)

[ ] 5.5 KRAKEN — law enforcement / security portal:
      URL:     https://www.kraken.com/en-us/legal/law-enforcement
      Method:  Submit via the law enforcement request form.
      Subject: "Security Emergency – [TOKEN] – [UTC_DATE]"
      Include: evidence pack from 5.1 above.
      Note:    Kraken requires a point-of-contact name + organization.

[ ] 5.6 Additional exchanges — use comms-director.md exchange contact list.
[ ] 5.7 Log every outreach:
      | Exchange | Contact method | UTC sent | Evidence included | Response |
      |----------|---------------|----------|-------------------|----------|
      | Binance  |               |          |                   |          |
      | Coinbase |               |          |                   |          |
      | OKX      |               |          |                   |          |
      | Kraken   |               |          |                   |          |

[ ] 5.8 If requesting a trading halt:
      - Provide token mint, tickers, primary DEX/CEX pools, and specific
        user harm the halt prevents.
      - Do NOT request a halt without evidence — unsupported requests
        will be ignored and burn future credibility.

═══════════════════════════════════════════════════════════════
PHASE 6 — COMMUNITY COMMS TIMING (GATED)
═══════════════════════════════════════════════════════════════

[ ] 6.1 Draft initial notice immediately (do NOT publish without IC approval).
[ ] 6.2 Publish only: what is confirmed + user actions required + next
      update UTC time. No speculation. No root cause until confirmed.
[ ] 6.3 Publish "no links except official" warning in all channels
      to suppress phishing during the crisis window.
[ ] 6.4 Commit to update cadence (e.g., every 60 minutes) and do not miss it.
[ ] 6.5 Hand off to comms-director.md for full communication runbook.

═══════════════════════════════════════════════════════════════
VERIFICATION MATRIX
═══════════════════════════════════════════════════════════════

| Action taken                          | How to verify it worked                                                     | Time to verify |
|---------------------------------------|-----------------------------------------------------------------------------|----------------|
| Program pause instruction executed    | Submit canary tx to a critical instruction; confirm "paused" error returned | 2 min          |
| Mint freeze on attacker ATA           | Transfer attempt from frozen ATA returns "Account is frozen" error          | 1 min          |
| Upgrade authority changed             | solana program show [PROGRAM_ID] — "Upgrade Authority" matches expected     | 1 min          |
| Program made immutable                | solana program show [PROGRAM_ID] — "Upgrade Authority: none"                | 1 min          |
| Helius webhook suspended              | 60-second window: zero new write txs from keeper/automation                 | 2 min          |
| Jito bundle submission halted         | No new bundles in Jito explorer for your auth keypair over 60 seconds       | 2 min          |
| Cloudflare Under Attack Mode active   | External curl POST to write endpoint returns 403/503 or JS challenge        | 1 min          |
| Own RPC sendTransaction blocked       | solana transfer attempt via your RPC returns 503 or method-not-found        | 1 min          |
| Emergency upgrade deployed            | Every critical instruction returns error; canary exploit tx fails           | 5 min          |
| Pyth/Switchboard oracle suspended     | Instruction that reads oracle returns "oracle suspended" error              | 5 min          |
| Exchange freeze requested (Binance)   | Confirmation email or ticket number received from exchange                  | 30 min         |
| Exchange freeze requested (Coinbase)  | Confirmation email or ticket number received from exchange                  | 30 min         |
| Exchange freeze requested (OKX)       | Confirmation email or ticket number received from exchange                  | 30 min         |
| Exchange freeze requested (Kraken)    | Confirmation email or ticket number received from exchange                  | 30 min         |

═══════════════════════════════════════════════════════════════
NEXT FILES
═══════════════════════════════════════════════════════════════

- agents/incident-commander.md    — decision gates + escalation
- agents/forensic-investigator.md — entry point + fund flow tracing
- agents/comms-director.md        — public + exchange comms runbook
- agents/recovery-engineer.md     — accounting + compensation + redeploy
- skill/program-freeze-and-pause.md — pause patterns and IDL reference
```
