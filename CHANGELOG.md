# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] — 2026-05-02

Major restructure for context-cost efficiency, plus content modernization
and self-applying CI.

### Changed

- **Split `SKILL.md`** from a 976-line monolith into a thin ~100-line
  core (frontmatter, behavior loop, always-on rules, reference map)
  plus on-demand topic files under `reference/` (31 files, organized
  as `01-13` plus `14-stacks/{node,nextjs,fastapi,django,go,rust,spring,dotnet,rails}.md`).
  Section numbering preserved so existing cross-references resolve.
- **Narrowed activation** in the `description` frontmatter from "every
  coding task" to high-stakes surfaces only (auth, uploads, SSRF,
  secrets, deployment configs, Dockerfiles, CI workflows, dependency
  installs, pre-commit/pre-push reviews). Skips routine refactors,
  renames, typos, and pure UI work.
- **`reference/03-patterns/auth.md`** — argon2id call now ships with
  explicit OWASP 2024 cost params (`memoryCost: 19456, timeCost: 2,
  parallelism: 1`). JWT example pairs the short-lived access token
  with rotating refresh tokens stored hashed server-side. MD5/SHA-256
  rejection reframed: "wrong primitive for password storage," not
  "broken." Algorithm-pinning rule added to verify call.
- **`reference/03-patterns/xss-csrf.md`** — replaced unmaintained
  `csurf` (last release 2022) with `csrf-csrf` (signed double-submit).
  Added `Origin` / `Sec-Fetch-Site` defense-in-depth check.
- **`reference/03-patterns/headers.md`** — expanded one-liner CSP
  guidance into nonce-vs-hash strategies, `'strict-dynamic'`,
  framework caveats (Next.js / Vite HMR / streaming), Report-Only
  rollout, csp-evaluator pointer, anti-patterns.
- **`reference/04-supply-chain.md`** — added install-time code
  execution defense: `npm ci --ignore-scripts` (and `.npmrc`),
  pnpm `onlyBuiltDependencies` allowlist, Yarn 4 `enableScripts: false`.
  Brief SBOM/SLSA pointer (`cyclonedx-npm`, `syft`,
  `actions/attest-build-provenance`).
- **`reference/07-ci-cd.md`** — replaced the legacy branch-protection
  endpoint (which requires GHE/Pro for private repos) with the modern
  Rulesets API. Full sample call provided.
- **`reference/14-stacks/dotnet.md`** — softened the PBKDF2 dismissal:
  ASP.NET Identity's defaults (≥100k iterations) are acceptable per
  OWASP, not broken. Argon2id via `Konscious.Security.Cryptography`
  is now framed as a cross-stack-parity choice, not a fix.
- **`.github/CODEOWNERS`** — replaced 4 redundant lines with
  topic-specific paths (`SKILL.md`, `reference/`, `scripts/`,
  `.github/workflows/`).
- **`README.md`** — repointed at the new layout, added CI badge,
  added "Self-applying" section.
- **`CONTRIBUTING.md`** — relaxed the strict "docs-only skill"
  stance to allow `scripts/` (with shellcheck-clean,
  ask-before-destructive, `--yes` for CI).

### Added

- **`scripts/install-pre-commit.sh`** — drops a gitleaks +
  filename-blocklist pre-commit hook into the current repo.
  Idempotent, refuses to clobber an unrelated existing hook
  without `--force`, `--yes` for CI.
- **`scripts/bootstrap-private-repo.sh`** — deterministic execution
  of `reference/09-new-project-flow.md`: `.gitignore` first,
  `.env.example`, `SECURITY.md`, `gitleaks detect`,
  `gh repo create --private`, branch protection via Rulesets,
  Secret Scanning + Push Protection + Dependabot security updates.
- **`.github/workflows/self-check.yml`** — every push runs the
  same checks SKILL.md prescribes against this repo: gitleaks,
  semgrep (`p/owasp-top-ten` + `p/security-audit`), markdownlint,
  lychee link check, shellcheck. All third-party actions pinned
  to commit SHAs.
- **`.markdownlint-cli2.jsonc`** — config for the markdownlint job.
- **`lychee.toml`** — link-checker config that skips example
  placeholders (`db.internal`, `example.com`, private IPs).

### Removed

- The single-file `curl SKILL.md` install snippet from the README.
  Use the clone or submodule install — Claude needs the `reference/`
  tree and `scripts/` to follow SKILL.md's references.

## [1.0.0] — 2026-05-02

Initial public release.

### Added

- `SKILL.md` — full secure-by-default playbook (14 sections):
  - § 1 Security planning before coding
  - § 2 Secrets protection (`.gitignore`, `.env.example`, scanning, rotation)
  - § 3 Secure-by-default patterns (auth, authz, validation, SQL/NoSQL, XSS, CSRF, SSRF, uploads, errors, logging, headers, rate-limit, crypto)
  - § 4 Dependency & supply-chain hygiene
  - § 5 Hardened project config
  - § 6 Docker hardening
  - § 7 CI/CD hardening (GitHub Actions)
  - § 8 Tests & security checks
  - § 9 New-project flow (private repo, branch protection, secret scanning)
  - § 10 Recommended files (Dependabot, CODEOWNERS, pre-commit, `.dockerignore`)
  - § 11 Commit & push safety
  - § 12 Final summary template
  - § 13 When to pause and ask
  - § 14 Stack quick-reference (Node, Next.js, FastAPI, Django, Go, Rust, Spring, .NET, Rails)
- `README.md` — install/usage/examples.
- `SECURITY.md` — vulnerability reporting policy.
- `CONTRIBUTING.md` — contribution guide and PR checklist.
- `.editorconfig` — consistent line endings, encoding, trailing whitespace.
- `.gitignore` — env files, keys, IDE artifacts, build output.
- `.github/dependabot.yml` — weekly GitHub Actions updates.
- `.github/CODEOWNERS` — single-owner default.
- `.github/ISSUE_TEMPLATE/` — bug report and feature request templates.
- `.github/PULL_REQUEST_TEMPLATE.md` — PR template aligned with CONTRIBUTING.

[Unreleased]: https://github.com/HenrikBrehm/secure-builder-claude-skill/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/HenrikBrehm/secure-builder-claude-skill/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/HenrikBrehm/secure-builder-claude-skill/releases/tag/v1.0.0
