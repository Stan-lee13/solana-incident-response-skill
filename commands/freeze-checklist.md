# /freeze-checklist

Step-by-step program freeze execution checklist.

## Usage

"Run /freeze-checklist — I need to freeze [PROGRAM_ID], my pause authority is [sole keypair / Squads multisig], I have [X] signers reachable."

## Output

Returns a numbered execution checklist customized for your authority structure, with:
- Exact commands to run
- Verification steps after each action
- Estimated time per step
- What to do if each step fails

Covers: Anchor emergency pause, Squads v4 proposal flow, mint authority freeze, token account freeze, upgrade + redeploy as last resort.
