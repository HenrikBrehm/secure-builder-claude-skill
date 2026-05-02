# 1. Security planning before coding

Before writing code, quickly identify:

- **Entry points:** API routes, forms, CLI args, uploaded files, webhooks, background jobs, parsers, third-party callbacks, GitHub Actions workflows.
- **Trust boundaries:** browser/client to server, server to database, server to third-party API, server to filesystem, CI/CD to repository, local config to production config, secrets/config to runtime.
- **Assets:** user accounts, sessions, access tokens, refresh tokens, passwords, personal data, payment data, API keys, database content, admin actions, audit logs, uploaded files.
- **Likely risks:** injection, auth bypass, broken authorization, XSS, CSRF, SSRF, file upload abuse, insecure defaults, secret leaks, dependency/supply-chain risk, unsafe GitHub Actions, unsafe Docker config, unsafe error handling.

Then build the feature with controls for those risks.

For non-trivial web apps, APIs, auth systems, payment flows, multi-user systems, admin panels, file upload systems, or production deployments, create or update:

- `SECURITY.md` — supported versions, vulnerability reporting contact, response SLA.
- `THREAT_MODEL.md` — assets, entry points, trust boundaries, top risks, mitigations, residual risk, out-of-scope items.

Do this **before** writing the bulk of the feature so the controls inform the code, not the other way around.
