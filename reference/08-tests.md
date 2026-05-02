# 8. Tests & security checks

Add tests that fail the build when an authorization or input-validation rule regresses. A passing build should mean "the security invariants still hold," not just "the unit tests pass."

## 8.1 Required test cases for any auth-bearing app

- Anonymous request to a protected route → 401.
- Authenticated request to **another user's** resource → 404 (or 403).
- Expired/tampered token → 401.
- Injection-style input (`' OR 1=1--`, `{"$ne": null}`) is rejected at validation.
- Oversized payload (e.g., 10MB on a JSON endpoint) is rejected before reaching the handler.
- Login rate-limit: 11th attempt within window → 429.
- CSRF (cookie-session apps): state-changing request without token → rejected.
- File upload: wrong MIME, oversized, double-extension (`evil.php.png`), zero-byte — all rejected.
- Password reset token: single-use, expires, scoped to user.

## 8.2 Static analysis (run locally + in CI)

- **Semgrep** with `p/owasp-top-ten` and `p/security-audit` — multi-language coverage.
- JS/TS: ESLint with `eslint-plugin-security`, `eslint-plugin-no-secrets`.
- Python: `bandit -r .`, `ruff` with the `S` (bandit) ruleset.
- Go: `gosec ./...`, `staticcheck ./...`.
- Rust: `cargo clippy -- -D warnings`, `cargo audit`, `cargo deny`.
- Java: `spotbugs` + `find-sec-bugs`.
- Ruby: `brakeman`.
- PHP: `phpstan` + `psalm` with security plugins.

## 8.3 Secret scanning

- Local pre-commit hook: `gitleaks protect --staged --redact -v`.
- CI: `gitleaks detect --redact -v` on every push and PR.
- GitHub native: enable **Push Protection** + **Secret Scanning** in repo settings.
- For historical scrubs: `trufflehog git file://./ --since-commit HEAD~50`.

## 8.4 Dependency scanning

See `reference/04-supply-chain.md` § 4.3. Wire into CI as a required, blocking check at high/critical severity.
