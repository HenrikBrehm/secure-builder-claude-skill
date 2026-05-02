# 5. Hardened project config

For any new project, generate:

## `.gitignore`
See `reference/02-secrets.md` § 2.2.

## `.editorconfig`
```
root = true
[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true
```

## `SECURITY.md`
```markdown
# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| latest  | yes       |

## Reporting a Vulnerability

Please report security issues privately:
- GitHub Security Advisory: use "Report a vulnerability" in the Security tab
- Email: <security@example.com>

Do **not** open public issues for security problems.

We aim to acknowledge within 2 business days and provide a fix or mitigation timeline within 7 days.
```

## `THREAT_MODEL.md`
```markdown
# Threat Model

## Assets
- (e.g., user accounts, session tokens, payment data, uploaded files)

## Entry points
- (e.g., POST /login, POST /upload, GET /docs/:id, GitHub webhook)

## Trust boundaries
- (e.g., browser -> API, API -> DB, API -> Stripe)

## Top risks & mitigations
| Risk | Mitigation | Residual |
|------|------------|----------|
| Credential stuffing on /login | Rate-limit + breached-password check | Some |
| IDOR on /docs/:id | Ownership check in handler | None observed |
| Secret leak in logs | Token-prefix masking + log review | Some |
| SSRF via webhook URL | Egress filter + private-IP block | Low |

## Out of scope
- (e.g., physical access, host OS compromise, supply-chain attack on base image)
```
