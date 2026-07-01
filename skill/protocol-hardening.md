# Protocol Hardening

Post-incident hardening playbook for Solana protocols. Covers program upgrade authority management, instruction-level security invariants, account validation patterns, CPI safety, and PDA authority architecture. Applied after an exploit to ensure the same attack vector cannot be reused.

## Hardening Philosophy

> "The goal is not to make your protocol unhackable. The goal is to make the next attack cost more than the value it can extract."

Every hardening step should be evaluated against three questions:

1. **Does it close the specific vector exploited?** (If not, deprioritize)

2. **Does it introduce new attack surface?** (Some "fixes" make things worse)

3. **Can it be deployed without breaking existing user flows?**

---

## Phase 1: Immediate Post-Exploit Hardening (T+0 to T+24h)

### 1.1 Authority Rotation

```bash

## If deploy keypair is compromised or suspected compromised

## Step 1: Generate new multisig via Squads v4

## (Do this on an air-gapped machine if possible)

solana-keygen new --outfile new-emergency-keypair.json

## Step 2: Transfer program upgrade authority to new Squads PDA

## First, identify current upgrade authority

solana program show <PROGRAM_ID> --url mainnet-beta

## Step 3: Transfer via Squads (requires current upgrade authority signature)

## If current upgrade authority is compromised, you CANNOT rotate without their signature

## → This is why pre-deploying to a multisig before launch is critical

## If you still control the upgrade authority key

solana program set-upgrade-authority <PROGRAM_ID> \
  --new-upgrade-authority <NEW_SQUADS_PDA> \
  --url mainnet-beta \
  --keypair old-upgrade-authority.json

## Verify transfer

solana program show <PROGRAM_ID> --url mainnet-beta

## Expected: "Upgrade authority: <NEW_SQUADS_PDA>"

```

### 1.2 Emergency Pause (If Your Program Supports It)

```rust
// programs/your_protocol/src/instructions/admin.rs

use anchor_lang::prelude::*;

#[derive(Accounts)]
pub struct EmergencyPause<'info> {
    #[account(mut)]
    pub protocol_state: Account<'info, ProtocolState>,
    
    // Pause authority must be the multisig PDA — not a hot wallet
    #[account(
        constraint = pause_authority.key() == protocol_state.pause_authority 
            @ ProtocolError::UnauthorizedPause
    )]
    pub pause_authority: Signer<'info>,
}

pub fn emergency_pause(ctx: Context<EmergencyPause>) -> Result<()> {
    let state = &mut ctx.accounts.protocol_state;
    require!(!state.is_paused, ProtocolError::AlreadyPaused);
    
    state.is_paused = true;
    state.pause_timestamp = Clock::get()?.unix_timestamp;
    state.pause_slot = Clock::get()?.slot;
    
    emit!(EmergencyPauseEvent {
        authority: ctx.accounts.pause_authority.key(),
        timestamp: state.pause_timestamp,
        slot: state.pause_slot,
    });
    
    msg!("PROTOCOL PAUSED at slot {}", state.pause_slot);
    Ok(())
}

// In ALL instruction handlers, add this guard as the FIRST check:
pub fn any_instruction(ctx: Context<AnyInstruction>, ...) -> Result<()> {
    require!(
        !ctx.accounts.protocol_state.is_paused,
        ProtocolError::ProtocolPaused
    );
    // ... rest of instruction
}

```

---

## Phase 2: Account Validation Hardening

The most common exploit class in Solana: insufficient account validation.

### 2.1 Ownership Checks

```rust
// VULNERABILITY: Missing owner check allows attacker to pass accounts owned by their program
// HARDENED: Explicit owner check on all accounts that hold value

#[derive(Accounts)]
pub struct WithdrawFunds<'info> {
    // ❌ VULNERABLE — no owner constraint
    // pub vault: Account<'info, TokenAccount>,
    
    // ✅ HARDENED — must be owned by token program, specific mint
    #[account(
        mut,
        token::mint = accepted_mint,
        token::authority = vault_authority,
        owner = anchor_spl::token::ID,  // or TOKEN_2022_PROGRAM_ID
    )]
    pub vault: Account<'info, TokenAccount>,
    
    #[account(
        seeds = [b"vault-authority", protocol_state.key().as_ref()],
        bump = protocol_state.vault_authority_bump,
    )]
    pub vault_authority: SystemAccount<'info>,
    
    pub accepted_mint: Account<'info, Mint>,
    pub protocol_state: Account<'info, ProtocolState>,
}

```

### 2.2 Signer Checks

```rust
// VULNERABILITY: Missing signer check on authority account
// HARDENED: Explicit signer constraint

#[derive(Accounts)]
pub struct AdminAction<'info> {
    // ❌ VULNERABLE — anyone can pass admin_authority without signing
    // pub admin_authority: AccountInfo<'info>,
    
    // ✅ HARDENED — must be a signer AND match protocol_state.admin
    #[account(
        constraint = admin.key() == protocol_state.admin 
            @ ProtocolError::UnauthorizedAdmin,
    )]
    pub admin: Signer<'info>,
    
    pub protocol_state: Account<'info, ProtocolState>,
}

```

### 2.3 PDA Derivation Validation

```rust
// VULNERABILITY: PDA derived from attacker-controlled seeds
// HARDENED: Seeds are canonical and cannot be influenced by the caller

#[derive(Accounts)]
pub struct UserWithdraw<'info> {
    // ❌ VULNERABLE — user_seed is passed in by caller, can be manipulated
    // #[account(seeds = [user_seed.as_ref()], bump)]
    // pub user_vault: Account<'info, TokenAccount>,
    
    // ✅ HARDENED — seeds are canonical: program-defined prefix + user's pubkey
    #[account(
        mut,
        seeds = [
            b"user-vault",           // fixed prefix — cannot be manipulated
            user.key().as_ref(),     // user's verified pubkey (from Signer)
        ],
        bump = user_vault_state.bump,
        constraint = user_vault_state.owner == user.key() @ ProtocolError::VaultOwnerMismatch,
    )]
    pub user_vault: Account<'info, TokenAccount>,
    
    #[account(
        seeds = [b"user-vault-state", user.key().as_ref()],
        bump,
    )]
    pub user_vault_state: Account<'info, UserVaultState>,
    
    pub user: Signer<'info>,  // ← user must sign — prevents spoofing
}

```

### 2.4 Account Reuse / Duplicate Account Attack

```rust
// VULNERABILITY: Same account passed twice in different roles
// Example: attacker passes same TokenAccount as both "from" and "to"
// HARDENED: Explicit not-equal constraint between conflicting accounts

#[derive(Accounts)]
pub struct Transfer<'info> {
    #[account(mut)]
    pub from: Account<'info, TokenAccount>,
    
    #[account(
        mut,
        constraint = to.key() != from.key() @ ProtocolError::SameAccountTransfer,
    )]
    pub to: Account<'info, TokenAccount>,
}

```

---

## Phase 3: CPI (Cross-Program Invocation) Safety

CPIs to arbitrary programs are the second most common exploit class.

### 3.1 Program ID Validation

```rust
// VULNERABILITY: CPI target program not validated — attacker passes their malicious program
// HARDENED: Validate program ID before CPI

// Known program IDs (pin these in your code — do NOT accept dynamically)
pub const JUPITER_V6_PROGRAM: Pubkey = pubkey!("JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4");
pub const SQUADS_V4_PROGRAM:  Pubkey = pubkey!("SMPLecH534NA9acpos4G6x7uf3LWbCAwZQE9e8ZekMu");
pub const METEORA_DLMM:       Pubkey = pubkey!("LBUZKhRxPF3XUpBCjp4YzTKgLccjZhTSDM9YuVaPwxo");

#[derive(Accounts)]
pub struct SwapAndBurn<'info> {
    #[account(
        constraint = jupiter_program.key() == JUPITER_V6_PROGRAM 
            @ ProtocolError::InvalidJupiterProgram,
    )]
    /// CHECK: Jupiter v6 — address constraint validates identity above
    pub jupiter_program: UncheckedAccount<'info>,
}

```

### 3.2 Return Value Validation After CPI

```rust
// VULNERABILITY: CPI "succeeds" but output is not validated
// HARDENED: Validate state change after CPI completes

pub fn swap_fee_to_protocol_token(ctx: Context<SwapAndBurn>) -> Result<()> {
    let balance_before = ctx.accounts.output_vault.amount;
    
    // Execute Jupiter CPI
    invoke(
        &build_jupiter_swap_instruction(/* ... */),
        &[/* accounts */],
    )?;
    
    // ✅ RELOAD AND VALIDATE — CPI may have partially executed
    ctx.accounts.output_vault.reload()?;
    let balance_after = ctx.accounts.output_vault.amount;
    
    require!(
        balance_after > balance_before,
        ProtocolError::SwapProducedZeroOutput
    );
    
    let tokens_received = balance_after - balance_before;
    
    // Validate minimum output (slippage protection)
    let min_output = ctx.accounts.swap_config.min_output_tokens;
    require!(
        tokens_received >= min_output,
        ProtocolError::ExcessiveSlippage
    );
    
    Ok(())
}

```

---

## Phase 4: Arithmetic Safety

### 4.1 Integer Overflow and Precision Loss

```rust
// VULNERABILITY: Unchecked arithmetic — u64 overflow wraps to 0
// HARDENED: checked_* arithmetic on all financial calculations

pub fn calculate_user_reward(
    user_stake: u64,
    total_stake: u64,
    reward_pool: u64,
) -> Result<u64> {
    // ❌ VULNERABLE — division precision loss + potential overflow
    // let reward = user_stake / total_stake * reward_pool;
    
    // ✅ HARDENED — use u128 for intermediate calculation to prevent overflow
    let reward = (user_stake as u128)
        .checked_mul(reward_pool as u128)
        .ok_or(ProtocolError::Overflow)?
        .checked_div(total_stake as u128)
        .ok_or(ProtocolError::DivisionByZero)? as u64;
    
    Ok(reward)
}

pub fn compound_interest(principal: u64, rate_bps: u64, periods: u64) -> Result<u64> {
    // Rate in basis points (1 bps = 0.01%)
    // Use u128 throughout to prevent overflow on large principals
    let mut amount = principal as u128;
    let divisor: u128 = 10_000; // 100% = 10000 bps
    
    for _ in 0..periods {
        let interest = amount
            .checked_mul(rate_bps as u128)
            .ok_or(ProtocolError::Overflow)?
            .checked_div(divisor)
            .ok_or(ProtocolError::Overflow)?;
        
        amount = amount.checked_add(interest).ok_or(ProtocolError::Overflow)?;
    }
    
    // Check if result fits in u64
    require!(amount <= u64::MAX as u128, ProtocolError::Overflow);
    Ok(amount as u64)
}

```

---

## Phase 5: Upgrade Authority Architecture

The gold standard for post-exploit authority management:

```

AUTHORITY HIERARCHY (most secure):

  Level 0: Emergency multisig (5-of-9, hardware wallets only)
    → Controls: program upgrade authority
    → Use: Only for critical security patches
    → Threshold: 5 signatures, 48h timelock for non-emergency
    
  Level 1: Operations multisig (3-of-5, hardware + Ledger)
    → Controls: protocol admin (fee changes, parameter updates)
    → Use: Regular protocol maintenance
    → Threshold: 3 signatures, 24h timelock
    
  Level 2: Crank/oracle authority (hot wallet, restricted)
    → Controls: permissionless cranks (price updates, liquidations)
    → Use: Automated, high-frequency operations
    → Restrictions: Can ONLY call specific permissionless instructions
    → Rotation: Every 90 days (see oracle-key-compromise.md runbook)
    
  Level 3: Fee recipient (hot wallet)
    → Controls: Receives protocol fees
    → Use: Treasury operations
    → NO program-level authority — cannot upgrade anything

TIMELOCK CONFIGURATION (Squads v4):

```

```typescript
// Configure timelock for operations multisig
import Squads from "@sqds/multisig";

const timeLockConfig = {
  timeLock: 86400, // 24 hours in seconds (operations multisig)
  // Emergency multisig: 0 timelock (urgency requires immediate action)
  // For emergency: require 5/9 instead of 3/5 — higher threshold = security
};

```

---

## Phase 6: Post-Hardening Verification Checklist

```bash

## Run after implementing all hardening changes — before re-opening the protocol

## 1. Anchor build — must succeed with zero warnings

anchor build 2>&1 | grep -E "warning|error" | wc -l

## Expected: 0

## 2. Full test suite

anchor test --skip-deploy

## Expected: All tests pass

## 3. Account validation audit

## For each instruction, verify

grep -n "UncheckedAccount\|AccountInfo" programs/*/src/**/*.rs

## Every UncheckedAccount must have a CHECK comment AND a constraint

## Review each one manually

## 4. Missing signer check audit

grep -n "#\[account" programs/*/src/**/*.rs | grep -v "Signer\|constraint\|seeds\|bump\|mut\|init\|close\|has_one\|token::\|owner =" 

## Any account holding value WITHOUT constraint = potential vulnerability

## 5. Arithmetic audit

grep -n "\* \|/ \|+ \|- " programs/*/src/**/*.rs | grep -v "checked_\|saturating_\|//\|#\[" | head -30

## All arithmetic on u64 should use checked_* variants

## 6. CPI program ID validation

grep -n "invoke\|invoke_signed" programs/*/src/**/*.rs

## Every CPI must have the program_id validated via constraint or explicit check

## 7. Verify upgrade authority is multisig

solana program show <PROGRAM_ID> --url mainnet-beta | grep "Upgrade authority"

## Expected: Squads PDA (not a hot wallet pubkey)

## 8. Integration test: pause mechanism

anchor test --skip-deploy -- --grep "emergency_pause"

## Expected: pause succeeds; all user-facing instructions fail while paused; unpause succeeds

```

---

## Phase 7: Security Disclosure and Patch Communication

```

RESPONSIBLE DISCLOSURE WINDOW (after exploit, before patch publication):

  Day 0:    Exploit detected and contained. Legal hold activated.
  Day 0-1:  Root cause analysis (forensic-investigator.md)
  Day 1-3:  Patch developed, audited on devnet, tested
  Day 3:    Patch deployed to mainnet via Squads multisig
  Day 3:    Protocol unpaused
  Day 3:    FULL post-mortem published (post-mortem-template.md):

              - Exact exploit technique

              - Root cause (with code snippet showing vulnerability)

              - Fix applied (with code snippet showing hardened version)

              - Timeline of all actions taken

              - Amount affected (exact)

              - Reimbursement plan (if applicable)
  Day 3-7:  Coordinated disclosure to security researchers who reported similar issues
  Day 7:    Submit CVE / public disclosure to Solana Foundation security channel

WHAT NOT TO DO:
  ❌ Patch silently without disclosure — community will notice the upgrade
  ❌ Downplay the severity — users need accurate information to assess risk
  ❌ Delay disclosure indefinitely "until we're sure" — 7 days maximum
  ❌ Blame the attacker without disclosing your own vulnerability

```
