# Security Policy

## Scope

This repository is a **knowledge base and AI skill** — it contains documentation,
TypeScript reference examples, and Bash scripts. It does not contain a deployed smart contract,
a production backend service, or a runnable application.

Vulnerabilities in this repo mean: incorrect security guidance, dangerous code examples,
or exploitable install scripts.

---

## Reporting a Vulnerability

If you find:
- A code example that could lead a developer to introduce a vulnerability in their Solana program
- An install script with a command injection or path traversal risk
- Incorrect security guidance that contradicts Solana's current security model
- A link pointing to a malicious or compromised resource

**Please report via GitHub's private vulnerability reporting:**
https://github.com/Stan-lee13/solana-incident-response-skill/security/advisories/new

Do not open a public issue for security concerns.

---

## Response Timeline

| Stage | SLA |
|---|---|
| Acknowledgment | Within 48 hours |
| Assessment | Within 5 business days |
| Fix or guidance update | Within 14 days for critical; 30 days for others |
| Public disclosure | After fix is merged |

---

## Out of Scope

- Theoretical vulnerabilities with no practical exploit path
- Issues in external tools or SDKs referenced (report to the respective maintainer)
- Spelling or grammar in documentation
- Dead links (open a standard issue for these)

---

## Code Example Disclaimer

All TypeScript, Rust, and Bash examples in this repository are **reference implementations**.
They have not been audited as production code. Before using any snippet against mainnet:

1. Confirm SDK and dependency versions are current
2. Test against devnet with small amounts
3. Have the implementation reviewed by a qualified Solana engineer
4. For programs holding user funds, engage a professional security audit firm

See `skill/hardened-redeployment.md` for a list of Solana audit firms.
