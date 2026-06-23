# /freeze-checklist

Generates a customized step-by-step program freeze checklist based on your authority structure and program type.

## Usage

```
Run /freeze-checklist — program is [PROGRAM_ID], authority is [single keypair / Squads multisig with N signers], program has [Anchor pause / no pause mechanism], I can reach [X] signers right now.
```

## What the agent will produce

A numbered checklist with:
- Exact commands for your setup (Anchor CLI / `solana` CLI / Squads UI)
- Time estimate per step
- Verification command to confirm each step worked
- Fallback action if the step fails
- Who needs to be on the call at each step

---

## Full Checklist Template (filled in by agent at runtime)

### ⏱ Phase 1 — Immediate (0–5 minutes)

```
[ ] 1. STOP all automated bots and cron jobs that interact with the program
        Command: [agent fills based on your infra]
        Verify: confirm no new transactions from your bots in the last 60s

[ ] 2. Kill all frontend deposit/interaction UI
        Action: set environment variable MAINTENANCE_MODE=true or take site offline
        Verify: curl https://yourdapp.com/api/status → returns maintenance response

[ ] 3. Remove or disable program from frontend routing
        Action: remove program calls from frontend code, redeploy with empty state
        Priority: do this even if it takes the whole site down — user safety first

[ ] 4. Alert all team members via emergency channel
        Include: program address, what's happening, who has keys, who's coordinating
```

### ⏱ Phase 2 — Authority Actions (5–20 minutes)

```
[ ] 5. ANCHOR PAUSE (if your program has emergency pause):
        # Single keypair:
        anchor run emergency-pause --provider.cluster mainnet-beta

        # Squads multisig:
        # → Go to https://squads.so/dashboard → your multisig
        # → New transaction → Program Instruction → pause()
        # → Request signatures from [N-of-M] signers
        # Timeline: 5 min (single key) | 15-30 min (multisig, signers must respond)

[ ] 6. FREEZE MINT (if you have mint authority and token is involved):
        spl-token freeze-account [TOKEN_ACCOUNT] --mint [MINT] --freeze-authority [KEYPAIR]
        # For multisig mint authority: initiate via Squads as above
        
[ ] 7. FREEZE ASSOCIATED TOKEN ACCOUNTS (attacker's accounts if identified):
        # Get attacker's ATA:
        spl-token accounts --owner [ATTACKER_WALLET] --mint [MINT]
        # Freeze it:
        spl-token freeze-account [ATTACKER_ATA] --mint [MINT] --freeze-authority [KEYPAIR]
        
[ ] 8. REVOKE DELEGATE (if attacker got a delegation):
        spl-token revoke [TOKEN_ACCOUNT]
```

### ⏱ Phase 3 — Verification (20–30 minutes)

```
[ ] 9. Verify pause is effective:
        # Try to interact with the program yourself — it should fail
        # Check Helius: no new exploit transactions in last 5 minutes
        
[ ] 10. Document the current state:
        - Program address
        - Block height when attack began
        - Block height when pause confirmed
        - Total estimated funds at risk vs protected
        - Attacker wallet(s) identified
        
[ ] 11. Preserve all logs:
        # Do NOT delete any accounts, close any PDAs, or modify state
        # Forensic investigators need the current on-chain state intact
        # Export Helius enhanced transaction history now
```

### If No Pause Mechanism Exists

```
Last resort — upgrade the program with pause logic:
[ ] 1. Write a minimal "pause" version of your program (adds a global pause flag)
[ ] 2. Get upgrade authority signers on a call RIGHT NOW
[ ] 3. Build and deploy the paused version:
        anchor build
        anchor upgrade target/deploy/your_program.so --program-id [PROGRAM_ID] --provider.cluster mainnet-beta
[ ] 4. Verify: all instructions now return error if pause flag is set
WARNING: This is slow (15-30 min) and risky. Mint authority freeze is faster if applicable.
```

## After the checklist is complete

→ Load `skill/liquidity-migration.md` to protect remaining user funds
→ Load `skill/crisis-communication.md` to draft the public notice
→ Run `/draft-incident-notice` to generate immediate public communication
