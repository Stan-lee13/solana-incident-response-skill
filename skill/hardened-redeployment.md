# Hardened Redeployment

> Load this skill when preparing to redeploy after an incident.
> Never redeploy without completing every section of this skill.

---

## The Redeployment Decision Framework

Before writing a single line of code, answer these questions:

```
Is the original vulnerability fully understood?
└── NO → Do not redeploy. Return to post-mortem-analysis.md

Has an independent security firm reviewed the fix?
└── NO → Do not redeploy. Engage an auditor first.

Is the new architecture meaningfully different from what was exploited?
└── NO → Reconsider. A patch on a fundamentally flawed design is not a fix.

Has the community been informed of the redeployment timeline?
└── NO → Communicate before you deploy, not after.

Do you have an incident response plan in place for the new deployment?
└── NO → Complete this skill first. You are about to use it again.
```

---

## Phase 1 — Code Remediation

### Fix the root cause — do not patch around it

Bad remediation:
```rust
// BAD: Adding a check on top of a fundamentally broken architecture
pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    require!(ctx.accounts.user.key() == ctx.accounts.vault.owner, ErrorCode::Unauthorized);
    // This check can still be bypassed if vault.owner can be set by attacker
    transfer_tokens(ctx, amount)
}
```

Good remediation:
```rust
// GOOD: Restructuring account validation using PDAs that cannot be spoofed
#[derive(Accounts)]
pub struct Withdraw<'info> {
    #[account(
        mut,
        seeds = [b"vault", user.key().as_ref()],
        bump = vault.bump,
        has_one = user,  // enforced by Anchor — vault.user must equal user.key()
        constraint = !config.paused @ ErrorCode::ProtocolPaused
    )]
    pub vault: Account<'info, UserVault>,
    
    #[account(mut)]
    pub user: Signer<'info>,  // Must sign — cannot be spoofed
    
    // ...
}
```

### Mandatory additions after any exploit

*Emergency pause infrastructure*
```rust
#[account]
pub struct ProtocolConfig {
    pub admin: Pubkey,
    pub pause_authority: Pubkey,  // Can be a different key from admin
    pub paused: bool,
    pub emergency_withdraw_only: bool,  // Allow withdrawals but block deposits
    pub bump: u8,
}

// Add to EVERY instruction:
require!(!config.paused, ErrorCode::ProtocolPaused);
```

*Event emission for every state change*
```rust
// Every critical action must emit an event for off-chain monitoring
emit!(Withdrawal {
    user: ctx.accounts.user.key(),
    amount,
    vault_balance_after: ctx.accounts.vault.balance,
    timestamp: Clock::get()?.unix_timestamp,
});

emit!(LiquidityAdded {
    provider: ctx.accounts.provider.key(),
    amount_a,
    amount_b,
    timestamp: Clock::get()?.unix_timestamp,
});
```

*Rate limiting on critical instructions*
```rust
#[account]
pub struct UserState {
    pub last_withdraw_slot: u64,
    pub daily_withdraw_amount: u64,
    pub daily_withdraw_reset_slot: u64,
}

pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    let state = &mut ctx.accounts.user_state;
    let current_slot = Clock::get()?.slot;
    
    // Rate limit: max 1 withdrawal per 10 slots (~4 seconds)
    require!(
        current_slot > state.last_withdraw_slot + 10,
        ErrorCode::WithdrawTooFrequent
    );
    
    // Daily limit: reset every ~86400 seconds (~216000 slots)
    if current_slot > state.daily_withdraw_reset_slot + 216_000 {
        state.daily_withdraw_amount = 0;
        state.daily_withdraw_reset_slot = current_slot;
    }
    
    let daily_limit = ctx.accounts.config.max_daily_withdraw;
    require!(
        state.daily_withdraw_amount + amount <= daily_limit,
        ErrorCode::DailyLimitExceeded
    );
    
    state.last_withdraw_slot = current_slot;
    state.daily_withdraw_amount += amount;
    
    // ... perform withdrawal
}
```

---

## Phase 2 — Authority Architecture Hardening

### Upgrade authority → Squads v4 multisig

```typescript
import { Multisig } from "@sqds/multisig";
import { Connection, Keypair, PublicKey } from "@solana/web3.js";

// Create a new multisig for upgrade authority
async function createSecurityMultisig(
  connection: Connection,
  creator: Keypair,
  members: PublicKey[],
  threshold: number  // e.g., 3 of 5
) {
  const createKey = Keypair.generate();
  const [multisigPda] = Multisig.pda.multisigPda({
    createKey: createKey.publicKey
  });
  
  const { signature } = await Multisig.rpc.multisigCreate({
    connection,
    creator,
    multisigPda,
    configAuthority: null,
    threshold,
    members: members.map((key, i) => ({
      key,
      permissions: Multisig.types.Permissions.all(),
    })),
    timeLock: 86400, // 24-hour timelock on all transactions
    createKey,
    sendOptions: { skipPreflight: false },
  });
  
  console.log("Security multisig created:", multisigPda.toString());
  console.log("Vault address:", Multisig.pda.vaultPda({ multisigPda, index: 0 })[0].toString());
  
  return multisigPda;
}
```

### Transfer upgrade authority to multisig

```bash
# Transfer program upgrade authority to Squads multisig vault
solana program set-upgrade-authority YOUR_PROGRAM_ID \
  --new-upgrade-authority SQUADS_VAULT_ADDRESS \
  --upgrade-authority CURRENT_AUTHORITY_KEYPAIR \
  --url mainnet-beta

# Verify the transfer
solana program show YOUR_PROGRAM_ID --url mainnet-beta
```

### Treasury authority → timelocked multisig

All protocol-owned funds should require:
- Multiple signatures (minimum 3 of 5)
- 24-48 hour timelock on treasury movements
- Separate keys for different permission levels

---

## Phase 3 — Pre-Deployment Audit Requirements

### What to audit before redeployment

Minimum requirements after a security incident:

*1. Full audit of the modified code*
The auditor must specifically verify that the exploit is fixed — not just review the new code in isolation.

Request this explicitly: "Please verify that the vulnerability described in [POST-MORTEM LINK] cannot be reproduced on this version."

Top firms for redeployment audits:
- Trail of Bits: https://www.trailofbits.com — 4-6 week timeline
- OtterSec: https://osec.io — fast, Solana-specialized
- Neodyme: https://neodyme.io — deep Solana expertise
- Halborn: https://halborn.com — 2-4 week timeline

*2. Competitive audit / second opinion*
After a major exploit, use two firms. The second firm reviews with knowledge of the first incident — they are specifically looking for related vulnerability classes.

*3. Formal verification (for critical math)*
If the exploit involved arithmetic, price calculations, or invariants:
- Certora: https://certora.com — formal verification for program invariants
- Veridise: https://veridise.com — Solana formal verification

*4. Community audit program*
Open a bug bounty before relaunch. Even 30 days with $50K bounty is meaningful.
- Immunefi: https://immunefi.com — largest DeFi bug bounty platform
- Code4rena: https://code4rena.com — competitive audit
- Sherlock: https://sherlock.xyz — audit + coverage

---

## Phase 4 — Monitoring Infrastructure

Deploy monitoring BEFORE relaunch. Not after.

```typescript
// Helius webhook for real-time transaction monitoring
const webhookConfig = {
  webhookURL: "https://your-monitoring-server.com/solana-webhook",
  transactionTypes: ["ANY"],
  accountAddresses: [
    PROGRAM_ID,
    VAULT_ADDRESS,
    CONFIG_PDA,
    // All critical program accounts
  ],
  webhookType: "enhanced",
  authHeader: "Bearer YOUR_SECRET_TOKEN",
};

const response = await fetch("https://api.helius.xyz/v0/webhooks?api-key=YOUR_KEY", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(webhookConfig),
});
```

```typescript
// Alert thresholds — customize for your protocol
const ALERT_RULES = {
  // Volume spike: more than 10x average in 5 minutes
  volumeSpike: { multiplier: 10, windowMinutes: 5 },
  
  // Large single withdrawal: more than 1% of TVL
  largeWithdrawal: { percentageTVL: 0.01 },
  
  // Rapid sequential transactions: more than 10 from same wallet in 1 minute
  rapidTransactions: { count: 10, windowSeconds: 60 },
  
  // Oracle deviation: price moves more than 5% in one slot
  oracleDeviation: { percentagePerSlot: 0.05 },
};
```

---

## Phase 5 — Phased Relaunch

Do not relaunch at full capacity immediately.

```
Week 1: Restricted relaunch
- Deposit cap: 10% of pre-exploit TVL
- Withdrawal-only mode for first 48 hours
- Maximum position size: 50% of previous limit
- All admin actions require emergency review

Week 2-4: Monitored expansion
- Raise caps 25% per week if no anomalies
- Daily security review
- Bug bounty remains active

Month 2+: Normal operations
- Full capacity restored if no incidents
- Post-incident audit report published
- Community governance vote on final authority structure
```

---

## Community Trust Restoration

Technical fixes alone do not restore trust. Required communication:

*Before relaunch:*
- Full post-mortem published and acknowledged
- Audit report published (full, not summary)
- Compensation plan executed or clearly communicated
- Relaunch timeline communicated 7+ days in advance

*At relaunch:*
- Live AMA or community call
- Real-time monitoring dashboard public
- Explicit acknowledgment of what is different

*30 days post-relaunch:*
- Security update published: "Here is what our monitoring has caught"
- Ongoing bug bounty status
- Roadmap for further hardening

---

## Redeployment Go/No-Go Checklist

```
REDEPLOYMENT CHECKLIST

CODE:
[ ] Root cause fix implemented
[ ] Emergency pause mechanism added
[ ] Event emission on all critical instructions
[ ] Rate limiting on high-value instructions
[ ] Test coverage >90% on modified code
[ ] Fuzz testing run on critical functions

SECURITY:
[ ] Full audit completed — report published
[ ] Audit firm specifically verified the exploit is fixed
[ ] Second opinion audit completed (for major incidents)
[ ] Bug bounty program active

AUTHORITY:
[ ] Upgrade authority transferred to multisig
[ ] Multisig members verified and tested
[ ] Emergency pause authority separate from admin
[ ] Treasury authority timelocked

MONITORING:
[ ] Helius webhooks configured for all program accounts
[ ] Alert thresholds set and tested
[ ] On-call rotation established
[ ] Incident runbook updated

COMMUNICATION:
[ ] Post-mortem published
[ ] Compensation plan executed
[ ] Community notified of relaunch date (7+ days advance notice)
[ ] Audit report published
[ ] AMA or community call completed

LEGAL:
[ ] Legal team reviewed relaunch plan
[ ] Insurance reinstated or applied for
[ ] Regulatory notifications complete (if required)

GO / NO-GO DECISION: ____________
```
