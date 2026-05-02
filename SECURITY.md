# Security Policy

## Supported versions

| Version | Supported |
| ------- | --------- |
| `main`  | yes       |
| `v1.x`  | yes       |
| `< 1.0` | no        |

## Reporting a vulnerability

**Please report security issues privately.** Do **not** open a public GitHub issue or pull request for security problems.

### Preferred — GitHub Security Advisory

1. Go to https://github.com/HenrikBrehm/secure-builder-claude-skill/security/advisories
2. Click **Report a vulnerability**.
3. Fill in the form. The repo maintainers receive a private notification.

This keeps the report confidential, lets us coordinate a fix, and gives you a CVE if applicable.

### What to include

- A description of the issue.
- The file(s) and line(s) of `SKILL.md` (or other repo content) involved.
- A concrete example of how the recommended pattern fails — e.g., "Section 3.7's SSRF allowlist misses `0177.0.0.1`" with a reproducer.
- The version / commit SHA you reviewed.

### What we treat as in-scope

- A pattern in `SKILL.md` that recommends an **insecure** default (e.g., a password hash that's actually broken, a CSP that doesn't actually mitigate XSS, a regex that bypasses).
- A pattern that **claims to mitigate** an attack class but doesn't.
- A code example that, if copy-pasted, introduces a vulnerability.
- A flow that exfiltrates user secrets, leaks data, or weakens the user's repo without their consent.

### What is out of scope

- General disagreement with stylistic choices ("I prefer bcrypt over argon2id"). Open a regular issue or PR with a tradeoff table.
- Vulnerabilities in third-party tools the skill recommends (`gitleaks`, `semgrep`, `helmet`, etc.) — please report those upstream.
- Vulnerabilities in Claude Code itself — report to Anthropic.

## Response SLA

- **Acknowledgement:** within 2 business days.
- **Initial assessment:** within 7 days.
- **Fix or mitigation timeline:** communicated within 14 days; coordinated disclosure window is typically 30–90 days depending on severity.

## Coordinated disclosure

We prefer responsible, coordinated disclosure. If you've already published or you have a hard deadline, tell us in the report — we'll work with whatever timeline is realistic.

Credit is given by default in the release notes. Tell us if you'd prefer to remain anonymous.
