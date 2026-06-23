# /post-mortem-template

Generates a structured post-mortem template pre-filled with your incident details.

## Usage

"Run /post-mortem-template — incident was on [DATE], we lost [AMOUNT], the attack vector was [BRIEF DESCRIPTION], the fix was [BRIEF DESCRIPTION]."

## Output

Returns a complete Markdown post-mortem document ready to publish, with:
- All section headers in place
- Your confirmed facts pre-filled
- Placeholders clearly marked for sections still being finalized
- A checklist of what must be confirmed before publishing

Follows the structure used by the highest-quality post-mortems in Solana history (Wormhole, Crema Finance, Mango Markets).
