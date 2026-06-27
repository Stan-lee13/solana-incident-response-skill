# Markdown Validation

This repository is a markdown-first AI skill, so content quality is enforced through markdown linting and link validation.

## CI Workflow

`.github/workflows/markdown-validation.yml` runs on pull requests and pushes to `main`.

It performs two checks:

1. **Markdown lint** using `DavidAnson/markdownlint-cli2-action`
2. **Link validation** using `lycheeverse/lychee-action`

## Local Equivalent

If you have Node.js and lychee installed locally, run:

```bash
npx markdownlint-cli2 '**/*.md'
lychee --config .lychee.toml './**/*.md'
```

## Configuration

- `.markdownlint.json` disables line-length enforcement because incident playbooks contain long tables, command templates, and exact message examples.
- `.lychee.toml` permits common CDN/rate-limit statuses and excludes intentional example URLs.

## Required Standard

A markdown change is production-ready when:

- headings are structured and non-duplicative
- links resolve or are intentionally excluded
- example URLs remain inside templates only
- code fences are closed
- file references use repo-relative paths when possible
