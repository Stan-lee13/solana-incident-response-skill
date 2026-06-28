# Contributing to solana-incident-response-skill

This is a production-grade incident response knowledge base for Solana protocols. Contributions are welcome — but because this skill is used under pressure in real incidents, the quality bar is high.

---

## What Makes a Good Contribution

**Do:**
- Add new attack patterns discovered in real Solana incidents
- Update code snippets when SDK versions change (Helius, Anchor, SPL Token)
- Add jurisdiction-specific legal guidance (we are strong on US/EU, gaps exist elsewhere)
- Add runbooks for incident types not yet covered
- Improve TypeScript examples with better error handling
- Add real post-mortem data (sanitized) to strengthen pattern detection

**Don't:**
- Add generic "blockchain security best practices" — this skill is Solana-specific
- Add untested code without clearly marking it as reference-only
- Add legal advice that could be confused with professional legal counsel
- Remove the DISCLAIMER in `skill/legal-regulatory-response.md`
- Add wallet addresses without confirming they are publicly attributed to incidents

---

## Development Setup

```bash
git clone https://github.com/Stan-lee13/solana-incident-response-skill
cd solana-incident-response-skill
# No npm install needed — this is a markdown knowledge base
# To validate links and markdown:
npm install -g markdownlint-cli
markdownlint "**/*.md" --config .markdownlint.json
```

---

## Contribution Process

1. Fork the repository
2. Create a branch: `git checkout -b feat/your-contribution`
3. Make your changes
4. Run markdown validation: `markdownlint "**/*.md"`
5. Submit a pull request with a clear description of what changed and why
6. Reference the incident source for any new attack patterns

---

## Code Example Standards

All TypeScript/JavaScript examples must:
- Use proper async/await error handling
- Include the dependency name and minimum version in a comment
- Be runnable against Solana devnet (not just mainnet-only)
- Not hardcode real API keys, wallet addresses, or private keys

All Bash examples must:
- Include the prerequisite CLI tools at the top
- Use environment variables for sensitive values (HELIUS_API_KEY, etc.)
- Work on macOS and Linux

---

## Sensitive Information

**Never commit:**
- Real private keys or seed phrases (even from past incidents)
- API keys or webhook secrets
- PII from incident victims
- Unpublished vulnerability details for unpatched programs

---

## Attribution

When adding attack patterns from public post-mortems, include:
- Protocol name (if publicly disclosed)
- Date of incident
- Source URL (post-mortem, Chainalysis report, Twitter thread)
- Amount involved (if publicly reported)

---

## Questions

Open an issue or reach out via GitHub Discussions. For security-sensitive contributions,
use GitHub's private vulnerability reporting.
