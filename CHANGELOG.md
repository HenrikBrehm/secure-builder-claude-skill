# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/HenrikBrehm/secure-builder-claude-skill/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/HenrikBrehm/secure-builder-claude-skill/releases/tag/v1.0.0
