# Evaluation — secure-builder-claude-skill

**Subject under review:** v1.1.0 (commit [`0236a57`](https://github.com/HenrikBrehm/secure-builder-claude-skill/commit/0236a57)) — thin `SKILL.md` core + `reference/` tree + helper `scripts/`.
**Reviewed on:** 2026-05-03
**Reviewer methodology:** Mixed automated static checks + manual review against external standards (OWASP Top 10:2021, CWE Top 25, vendor-current package metadata).
**Evaluator stance:** Independent. Findings include real defects, not just confirmations.

---

## 1. Methodology

The evaluation is split into seven tests labelled **T1–T7**. T1 is fully automated and re-runnable (the repo's own `.github/workflows/self-check.yml` runs the same five tools — gitleaks, semgrep, markdownlint, lychee, shellcheck — on every push and PR). T2–T7 are reviewer-graded — they require human judgement against external standards and cannot be reduced to pass/fail without throwing away signal.

| ID  | Name                              | Mechanism                                                                                | Re-runnable |
| --- | --------------------------------- | ---------------------------------------------------------------------------------------- | ----------- |
| T1  | Static checks                     | `gitleaks` + `markdownlint-cli2` + `lychee` + `shellcheck` against the working tree      | Automated   |
| T2  | OWASP Top 10:2021 coverage        | Manual matrix mapping each category to `SKILL.md` + `reference/*.md`                     | Reviewer    |
| T3  | FAIL/PASS correctness             | Walk every code block in `reference/02-*` and `reference/03-patterns/*`, verify syntax + library API + claim-mitigation match | Reviewer    |
| T4  | Tool / library currency           | Cross-check every named tool/package against its registry as of 2026-05-03               | Reviewer    |
| T5  | Self-application audit            | Does the repo follow its own rules from `reference/{02,05,07,09,10}.md`?                 | Reviewer    |
| T6  | Scenario walkthroughs             | Trace each `README.md` example end-to-end through `SKILL.md` and the reference tree      | Reviewer    |
| T7  | Gap analysis                      | Cross-reference against CWE Top 25 (2024) + ASVS L1 + known footguns                     | Reviewer    |

Re-running locally: see [`docs/tests/RUNNING.md`](./tests/RUNNING.md).

---

## 2. Scoreboard

| Test | Subject                         | Grade  | One-line verdict                                                                                  |
| ---- | ------------------------------- | ------ | ------------------------------------------------------------------------------------------------- |
| T1   | Static checks                   | **B+** | gitleaks clean; lychee passes (with note on stale config field); 5 MD060 lint findings on tables.  |
| T2   | OWASP Top 10:2021 coverage      | **A**  | Every category covered by FAIL/PASS pair; A04 (Insecure Design) lighter than the rest.            |
| T3   | FAIL/PASS correctness           | **A-** | csurf replaced with csrf-csrf; argon2 has cost params; DNS rebinding noted; one footgun left.     |
| T4   | Tool / library currency         | **B+** | Major v1.0.0 deprecation (csurf) resolved; passlib still 5y stale; tfsec slowing.                 |
| T5   | Self-application audit          | **A**  | Repo runs the same checks it prescribes — gitleaks, semgrep, markdownlint, lychee, shellcheck.    |
| T6   | Scenario walkthroughs           | **A**  | All three README scenarios fully prescribed; the new modular layout improves discoverability.     |
| T7   | Gap analysis                    | **B**  | DNS rebinding now in scope; open redirect, deserialization, SSTI, TOCTOU, prototype pollution still absent. |
| —    | **Aggregate**                   | **A-** | Substantial improvement over v1.0.0 (B+); content debts mostly resolved; gaps remaining are bounded. |

Grade scale: A = no significant issue found; B = small fixable issue; C = real concern; D = systemic problem; F = the recommendation actively misleads.

**Key delta vs. v1.0.0** *(see Appendix A for the v1.0.0 evaluation grades)*: T3 B → A-, T4 B → B+, T5 A → A (now self-applies via running tools, not just config presence), T7 B → B (DNS rebinding closed, four other gaps remain). Aggregate B+ → A-.

---

## 3. T1 — Static checks

### 3.1 Secret scanning — `gitleaks` 8.30.1

```text
$ gitleaks detect --no-git --source . --redact -v
INF scanned ~59703 bytes (59.70 KB) in 107ms
INF no leaks found
```

The project's `.gitleaks.toml` allowlists FAIL-example placeholders (`sk-proj-abc123`, `secret123`, `hunter2`, `abcd1234`) by exact stopword and is scoped to `reference/02-secrets.md`, `reference/03-patterns/{auth,injection,uploads}.md`, `reference/05-project-config.md`, `reference/06-docker.md`, `reference/09-new-project-flow.md`, `reference/10-recommended-files.md`, `SKILL.md`, `README.md`, `CHANGELOG.md`. Any new secret-shaped string outside those files still trips the scanner.

### 3.2 Markdown lint — `markdownlint-cli2` 0.22.1 / `markdownlint` 0.40.0

```text
$ markdownlint-cli2
Linting: 17 file(s)
Summary: 5 error(s)
SKILL.md:58 — MD060/table-column-style (4 findings on the reference-map separator row)
README.md:114 — MD060/table-column-style (1 finding on the reference-map separator row)
```

The 5 findings are all on table separator rows formatted `|---|---|` while the data rows use `| Threat ... |` with surrounding spaces — the rule's auto-detected "compact" style flags the inconsistency. **Note:** the repo's CI uses `markdownlint-cli2-action@v19.0.0` which bundles an older `markdownlint` version that predates `MD060`; the action is therefore green even though current local linters report these. Fix is two trivial edits (add spaces to the two separator rows: `| --- | --- |`). Logged here rather than fixed in this PR to keep the eval-add scope tight.

### 3.3 Link check — `lychee` 0.24.2

The repo's `lychee.toml` contains a stale field: `exclude_mail = true` was the field name in lychee ≤ v0.18 and was renamed to `include_mail` in newer releases. The CI is unaffected because `self-check.yml` invokes lychee via CLI args (`--no-progress --exclude-mail --max-concurrency 4 .`) without `--config`, but a maintainer running `lychee --config lychee.toml` on a current toolchain hits a parse error:

```text
TOML parse error at line 36, column 1
   |
36 | exclude_mail = true
   | ^^^^^^^^^^^^
   unknown field `exclude_mail`, expected one of … `include_mail` …
```

Without the config file (as CI runs), lychee returns 0 errors against all repo markdown. Recommended fix: rename the field to `include_mail = false` (default behavior preserved) and the file becomes portable to current lychee.

### 3.4 SAST — `semgrep` (CI only)

`self-check.yml` runs `semgrep ci` with `p/owasp-top-ten` + `p/security-audit`. This is **the strongest part of the self-check suite** — semgrep on a docs-only repo with code-block content scans the FAIL/PASS examples themselves, catching cases where a "PASS" example secretly contains an OWASP-flagged pattern. The CI history (visible at `https://github.com/HenrikBrehm/secure-builder-claude-skill/actions`) is the authoritative ledger; reviewer-side reading of the latest run is the way to verify.

### 3.5 Shell-script lint — `shellcheck` (CI only)

`self-check.yml` runs `shellcheck` against `scripts/` at severity `warning`. `scripts/install-pre-commit.sh` (125 lines) and `scripts/bootstrap-private-repo.sh` (220 lines) both use `set -euo pipefail`, validate args, gate destructive actions behind `confirm()`, and accept `--yes` for CI — all consistent with `SKILL.md`'s "ask before destructive" behavior.

### 3.6 Internal cross-reference resolution

`SKILL.md`'s reference map (lines 57–81) lists 13 reference files plus the 9 stack files. I traversed each path manually:

| Reference map entry                                                | Resolves to                                          | OK? |
| ------------------------------------------------------------------ | ---------------------------------------------------- | --- |
| Threat model / planning                                            | `reference/01-planning.md`                           | ✓   |
| Secrets, `.env*`, rotation, leak response                          | `reference/02-secrets.md`                            | ✓   |
| Password storage, login, sessions, JWT, 2FA                        | `reference/03-patterns/auth.md`                      | ✓   |
| Per-resource permission, IDOR, mass assignment                     | `reference/03-patterns/authorization.md`             | ✓   |
| Validation, schema enforcement                                     | `reference/03-patterns/validation.md`                | ✓   |
| SQL/NoSQL, dynamic identifiers                                     | `reference/03-patterns/injection.md`                 | ✓   |
| HTML rendering, CSP-related XSS, CSRF                              | `reference/03-patterns/xss-csrf.md`                  | ✓   |
| Server-side `fetch` of user URLs, webhooks                         | `reference/03-patterns/ssrf.md`                      | ✓   |
| File upload, multipart, S3 puts                                    | `reference/03-patterns/uploads.md`                   | ✓   |
| Catch blocks, error responses, log fields                          | `reference/03-patterns/errors-logging.md`            | ✓   |
| Response headers, CSP, helmet                                      | `reference/03-patterns/headers.md`                   | ✓   |
| Rate limiting, crypto, random tokens                               | `reference/03-patterns/rate-limit-crypto.md`         | ✓   |
| Lockfiles, install scripts, SBOM                                   | `reference/04-supply-chain.md`                       | ✓   |
| `.editorconfig`, `SECURITY.md`, `THREAT_MODEL.md`                  | `reference/05-project-config.md`                     | ✓   |
| Dockerfile, docker-compose, BuildKit secrets                       | `reference/06-docker.md`                             | ✓   |
| GitHub Actions, OIDC, Rulesets                                     | `reference/07-ci-cd.md`                              | ✓   |
| Authz/validation/rate-limit/upload tests                           | `reference/08-tests.md`                              | ✓   |
| New private GitHub repo                                            | `reference/09-new-project-flow.md`                   | ✓   |
| `dependabot.yml`, `CODEOWNERS`, pre-commit, `.dockerignore`        | `reference/10-recommended-files.md`                  | ✓   |
| Pre-commit / pre-push checklist                                    | `reference/11-commit-push.md`                        | ✓   |
| End-of-task summary template                                       | `reference/12-summary-template.md`                   | ✓   |
| Pause-and-ask checklist                                            | `reference/13-pause-and-ask.md`                      | ✓   |
| Stack quick wins                                                   | `reference/14-stacks/{node,nextjs,fastapi,django,go,rust,spring,dotnet,rails}.md` | ✓ (9 files all present) |

Every reference-map link resolves. Section numbering inside SKILL.md and reference files is internally consistent.

### Verdict — T1: **B+**

The 5 MD060 findings and the stale `lychee.toml` field are real but low-impact (CI is green; local-current-toolchain users hit two minor friction points). Both are 2-character edits to fix.

---

## 4. T2 — OWASP Top 10:2021 coverage

| OWASP                                           | Reference file(s)                                            | Verdict     | Notes                                                                 |
| ----------------------------------------------- | ------------------------------------------------------------ | ----------- | --------------------------------------------------------------------- |
| **A01 Broken Access Control**                   | `03-patterns/authorization.md`                               | **Covered** | IDOR FAIL/PASS + 404-vs-403 oracle discussion (newly added in v1.1.0) |
| **A02 Cryptographic Failures**                  | `02-secrets.md`, `03-patterns/auth.md`, `03-patterns/rate-limit-crypto.md` | **Covered** | argon2id w/ explicit OWASP 2024 cost params; AEAD vs CBC; randomBytes  |
| **A03 Injection (SQL/NoSQL/Command)**           | `03-patterns/injection.md`                                   | **Covered** | Parameterized queries; mongo `$where` warning; allowlist for dynamic identifiers |
| **A04 Insecure Design**                         | `01-planning.md`, `05-project-config.md` (`THREAT_MODEL.md`) | **Partial** | Threat-modelling template; no concrete design FAIL/PASS pair          |
| **A05 Security Misconfiguration**               | `03-patterns/headers.md`, `05-project-config.md`, `06-docker.md`, `07-ci-cd.md` | **Covered** | CSP nonce/hash strategies, Docker hardening, GitHub Actions defaults  |
| **A06 Vulnerable & Outdated Components**        | `04-supply-chain.md`                                         | **Covered** | Lockfiles, Dependabot, audit tools, install-script blocking, SBOM/SLSA |
| **A07 Identification & Authentication Fail.**   | `03-patterns/auth.md`                                        | **Covered** | argon2id, refresh-token rotation, alg pinning, replay revocation chain |
| **A08 Software & Data Integrity Failures**      | `04-supply-chain.md`, `06-docker.md`, `07-ci-cd.md`          | **Covered** | Pin npm registry, image digest, action SHA, attestation/cosign        |
| **A09 Security Logging & Monitoring Failures**  | `03-patterns/errors-logging.md`                              | **Covered** | What to log / what NOT to log; audit trail to immutable sink          |
| **A10 Server-Side Request Forgery (SSRF)**      | `03-patterns/ssrf.md`                                        | **Covered** | Full FAIL/PASS with `ipaddr.js` allowlist; **DNS rebinding now noted** |

**Bonus categories the skill addresses:** XSS + CSRF (both in `xss-csrf.md`), file uploads, error-handling info disclosure, rate limiting, secrets handling, supply-chain install-script defense — all with FAIL/PASS pairs.

### Verdict — T2: **A**

A04 remains the lightest-treated category (template only, no worked example). Every other OWASP category has at least one concrete FAIL/PASS pair plus a stack-extension note in `reference/14-stacks/*.md`.

---

## 5. T3 — FAIL/PASS correctness review

Walked every fenced code block in `reference/02-secrets.md` and `reference/03-patterns/*.md`. Three questions per block:

1. **Syntax** — does it compile/parse as written?
2. **API match** — is the named library's API correct as of the library's current major version?
3. **Claim mitigation** — does the snippet actually mitigate what the surrounding text says it does?

### 5.1 Improvements vs v1.0.0 (resolved findings)

| Block | What changed in v1.1.0                                                                                   |
| ----- | -------------------------------------------------------------------------------------------------------- |
| `auth.md` PASS    | argon2id now ships with explicit OWASP 2024 cost params (`memoryCost: 19456, timeCost: 2, parallelism: 1`). PBKDF2 ≥ 600k iterations called out as acceptable when Argon2 unavailable. |
| `auth.md` PASS    | JWT example now pairs short-lived access token with rotating refresh tokens stored hashed server-side; replay-detection chain-revocation rule added. |
| `auth.md` PASS    | `jwt.verify(..., { algorithms: ["HS256"] })` algorithm pinning added — closes `alg: none` confused-deputy class. |
| `xss-csrf.md` PASS | **`csurf` replaced with `csrf-csrf`** (signed double-submit). Footnote explains why. Origin / Sec-Fetch-Site defense-in-depth check added. |
| `headers.md`       | One-liner CSP guidance expanded into nonce-vs-hash strategies, `'strict-dynamic'`, framework caveats (Next.js, Vite HMR, streaming), Report-Only rollout, csp-evaluator pointer, anti-patterns. Substantial real value. |
| `ssrf.md`          | **DNS rebinding residual-risk note added** — closes my v1.0.0 T7 gap. Recommends "resolve once, pin the IP, dial that IP directly with the original Host: header." |
| `02-secrets.md` § 2.3 | grep fallback rewritten as two-stage: provider-token shapes (low FP) + keyword+assignment (medium FP). Now catches GitHub PATs, Slack, Stripe, AWS, JWT, HuggingFace, OpenAI tokens. |
| `04-supply-chain.md` § 4.2 | Install-time code execution defense added (`npm ci --ignore-scripts`, pnpm `onlyBuiltDependencies`, Yarn 4 `enableScripts: false`). |
| `04-supply-chain.md` § 4.6 | SBOM + provenance pointers (`cyclonedx-npm`, `syft`, `actions/attest-build-provenance`, cosign). |
| `07-ci-cd.md` § 7.4 | Modern Rulesets API call replaces legacy branch-protection endpoint. Material — the legacy endpoint requires GHE/Pro for private repos. |
| `authorization.md`  | New "404 vs 403" discussion explaining the oracle problem. |

### 5.2 Findings — actionable in v1.1.0

| Block | Issue | Severity |
| --- | --- | --- |
| **`rate-limit-crypto.md` § 3.13** | `crypto.timingSafeEqual` recommendation still doesn't mention that buffers must be equal-length, otherwise the function throws `RangeError`. Real footgun — comparing a stored 32-byte token against a 31-byte user input crashes instead of returning a constant-time false. | **Medium** — correct primitive, missing precondition |
| **`uploads.md`**                  | The PASS block uses `fileTypeFromBuffer` from `file-type` v17+ ESM. Correct, but the example doesn't show the image re-encoding step (`sharp`) that the rules below recommend — a developer reading only the code might miss EXIF stripping. | **Low** — note, not a bug |
| **`ssrf.md`**                     | Block list is correct; DNS-rebinding paragraph added. The "resolve once, pin the IP, dial that IP" recommendation is right but not implemented in the PASS code block — left as guidance prose. A worked TS example using `dispatcher.connect` (undici) or a `lookup` callback would close the gap entirely. | **Low** — guidance present, code-level demo absent |

### 5.3 Findings — no issue

The remaining ~22 code blocks in `reference/02-secrets.md` and `reference/03-patterns/*.md` were reviewed and check clean for syntax, current-API match, and claim-mitigation. The strict `## FAIL` / `## PASS` / `## Rules` structure makes the review tractable.

### Verdict — T3: **A-**

Three items remain (one Medium, two Low), but the substantive v1.0.0 issue (deprecated `csurf`) is resolved, and the previously-undocumented DNS-rebinding gap is now named. Push to A would require the timingSafeEqual precondition and a worked DNS-pinning example.

---

## 6. T4 — Tool / library currency

Snapshot taken **2026-05-03** from npm, PyPI, and the upstream GitHub releases. "Status" reflects whether a developer following the skill's recommendation today reaches a maintained, current artifact.

### 6.1 npm packages cited in `reference/03-patterns/*.md` and stacks

| Package                 | Latest    | Released       | Status                          | Notes                                            |
| ----------------------- | --------- | -------------- | ------------------------------- | ------------------------------------------------ |
| `argon2`                | 0.44.0    | 2025-08-10     | ✅ current                       | 9 months since last release; stable              |
| `bcrypt`                | 6.0.0     | 2026-03-28     | ✅ current                       | Major bump from 5.x; API stable                  |
| `cors`                  | 2.8.6     | 2026-01-22     | ✅ current                       |                                                  |
| **`csrf-csrf`**         | (active)  | maintained     | ✅ current                       | **Replaces `csurf`** in v1.1.0                    |
| `express-rate-limit`    | 8.4.1     | 2026-04-24     | ✅ current                       |                                                  |
| `file-type`             | 22.0.1    | 2026-04-09     | ✅ current                       | ESM-only since v17                               |
| `helmet`                | 8.1.0     | 2026-04-24     | ✅ current                       |                                                  |
| `ipaddr.js`             | 2.3.0     | 2025-11-28     | ✅ current                       | `range()` returns 'unicast' for routable only ✓  |
| `isomorphic-dompurify`  | 3.12.0    | 2026-05-02     | ✅ current                       | Wraps `dompurify` 3.4.2                          |
| `dompurify` (upstream)  | 3.4.2     | 2026-04-30     | ✅ current                       |                                                  |
| `jsonwebtoken`          | 9.0.3     | 2026-04-16     | ✅ current                       | v9 fixed several historical CVEs                 |
| `sharp`                 | 0.34.5    | 2026-04-25     | ✅ current                       |                                                  |
| `zod`                   | 4.4.2     | 2026-05-01     | ✅ current                       | `safeParse`/`strict()` API stable across 3→4     |

### 6.2 PyPI packages cited in `reference/14-stacks/{fastapi,django}.md` and `reference/02-secrets.md`

| Package           | Latest   | Released       | Status        | Notes                                                                |
| ----------------- | -------- | -------------- | ------------- | -------------------------------------------------------------------- |
| `pydantic`        | 2.13.3   | 2026-04-20     | ✅ current     | v2; `ConfigDict(extra="forbid")` matches example                     |
| **`passlib`**     | 1.7.4    | **2020-10-08** | ⚠ stale       | 5+ years since last release; project nominally maintained, no CVEs known. |
| `pip-audit`       | 2.10.0   | 2026-04        | ✅ current     |                                                                      |
| `bandit`          | 1.9.4    | 2026-04        | ✅ current     |                                                                      |
| `safety`          | 3.7.0    | 2026-04        | ✅ current     | `pip-audit` preferred                                                |
| `django-axes`     | 8.3.1    | 2026-04        | ✅ current     |                                                                      |
| `django-csp`      | 4.0      | 2026           | ✅ current     |                                                                      |

### 6.3 Standalone tools cited in `reference/04-supply-chain.md`, `reference/07-ci-cd.md`, `reference/08-tests.md`

| Tool                | Latest     | Released       | Status        | Notes                                                                |
| ------------------- | ---------- | -------------- | ------------- | -------------------------------------------------------------------- |
| `gitleaks`          | 8.30.1     | 2026-03-21     | ✅ current     |                                                                      |
| `semgrep`           | 1.161.0    | 2026-04-22     | ✅ current     | `p/owasp-top-ten` and `p/security-audit` rulesets actively maintained |
| `trivy`             | 0.70.0     | 2026-04-17     | ✅ current     | Aqua's tfsec → trivy migration: trivy now scans Terraform too         |
| `grype`             | 0.112.0    | 2026-05-01     | ✅ current     | Anchore                                                              |
| `trufflehog`        | 3.95.2     | 2026-04-21     | ✅ current     |                                                                      |
| `gosec`             | 2.26.1     | 2026-04-28     | ✅ current     |                                                                      |
| `cargo-audit`       | 3.9.0      | 2026-03-12     | ✅ current     |                                                                      |
| **`tfsec`**         | 1.28.14    | 2025-05-02     | ⚠ slowing     | Last release exactly 1 year ago; Aqua now points at `trivy config`    |
| `checkov`           | 3.2.526    | 2026-04-30     | ✅ current     |                                                                      |
| `gh` CLI            | 2.92.0     | 2026-04-28     | ✅ current     |                                                                      |
| `cyclonedx-npm`     | active     | active         | ✅ current     | New in v1.1.0 § 4.6                                                  |
| `syft` (Anchore)    | active     | active         | ✅ current     | New in v1.1.0 § 4.6                                                  |

### 6.4 GitHub Actions used by `self-check.yml`

| Action                                  | Pinned tag | Pinned SHA          | Released   | Status        |
| --------------------------------------- | ---------- | ------------------- | ---------- | ------------- |
| `actions/checkout`                      | v4.2.2     | `11bd7190…`         | 2024-10    | ⚠ behind v6.0.2 (2026-01-09) |
| `gitleaks/gitleaks-action`              | v2.3.7     | `83373cf2…`         | 2024-10    | ⚠ behind v2.3.9 (2025-04-17) |
| `semgrep/semgrep-action`                | v1         | `713efdd3…`         | 2024       | ⚠ behind newer SHA           |
| `DavidAnson/markdownlint-cli2-action`   | v19.0.0    | `a23dae21…`         | 2024-10    | ⚠ behind v23.1.0 (2026-04-29) |
| `lycheeverse/lychee-action`             | v2.1.0     | `f81112d0…`         | 2025-02    | ⚠ behind v2.8.0 (2026-02-25)  |
| `ludeeus/action-shellcheck`             | 2.0.0      | `00cae500…`         | 2024-04    | ⚠ behind newer SHA           |

All six pinned-by-SHA Actions are correct in form (matching the rule in `reference/07-ci-cd.md` § 7.2) but lag the latest stable releases by 6–18 months. SHA-pinning protects against tag-hijack but does mean Dependabot needs to be on (and `.github/dependabot.yml` does include `package-ecosystem: github-actions`, so this is expected to self-heal over time).

### 6.5 Recommendations

1. **`passlib`** — note in `reference/14-stacks/{fastapi,django}.md` that the project is nominally maintained but the last release is 2020-10. For new Python projects, consider `argon2-cffi` directly.
2. **`tfsec`** — note in `reference/08-tests.md` § 8.2 that Aqua merged tfsec functionality into Trivy; new projects should prefer `trivy config <terraform-dir>`.
3. **Action SHAs** — Dependabot will surface bumps; merging the bumps faster keeps the SHA-pinning's protection current.

### Verdict — T4: **B+**

The headline v1.0.0 deprecation (`csurf`) is resolved. Two minor staleness items remain (`passlib`, `tfsec`); both are documented here without affecting correctness of code that uses them. Pinned Actions are SHA-correct but version-trailing, expected to be normalized by Dependabot.

---

## 7. T5 — Self-application audit

The skill's thesis is "the easy path is the safe path." A skill that recommends controls but doesn't apply them to its own repo is hypocritical. Section-by-section check.

| Reference                              | Required artefact in repo                  | Present? | Notes                                                                  |
| -------------------------------------- | ------------------------------------------ | -------- | ---------------------------------------------------------------------- |
| `02-secrets.md` § 2.2 — `.gitignore` before first commit | `.gitignore`             | ✅       | Predates v1.0.0; first commit `5d29c4a` had it                          |
| `02-secrets.md` § 2.2 — `.env.example` | `.env.example`                             | ⊘       | Repo is docs-only; no env vars to mirror — N/A                          |
| `05-project-config.md` — `.editorconfig` | `.editorconfig`                          | ✅       | Matches recommended template (UTF-8, LF, 2sp, final newline, trim WS)   |
| `05-project-config.md` — `SECURITY.md` | `SECURITY.md`                              | ✅       | Includes supported versions, advisory link, in-scope/out-of-scope       |
| `05-project-config.md` — `THREAT_MODEL.md` | (project's own threat model)           | ⊘       | Skill says "for non-trivial web apps, APIs, …" — docs repo doesn't qualify |
| `07-ci-cd.md` § 7.1 — `permissions: {}` default | `.github/workflows/self-check.yml` | ✅       | Workflow-level `permissions: {}`; per-job `contents: read`              |
| `07-ci-cd.md` § 7.2 — Actions pinned by SHA | `.github/workflows/self-check.yml`    | ✅       | All six uses pinned by full commit SHA with `# vX.Y.Z` comment          |
| `07-ci-cd.md` § 7.1 — `concurrency` cancellation | `.github/workflows/self-check.yml` | ✅       | `cancel-in-progress: true` on workflow group                            |
| `07-ci-cd.md` § 7.1 — `timeout-minutes` per job | `.github/workflows/self-check.yml`  | ✅       | 3–10 min per job                                                       |
| `08-tests.md` § 8.3 — `gitleaks` in CI | `self-check.yml` (gitleaks job)            | ✅       | Runs on every push and PR                                               |
| `08-tests.md` § 8.2 — semgrep in CI    | `self-check.yml` (semgrep job)             | ✅       | `p/owasp-top-ten` + `p/security-audit`                                  |
| `08-tests.md` § 8.3 — `gitleaks` in pre-commit | `scripts/install-pre-commit.sh`    | ✅       | Idempotent installer ships in repo                                      |
| `08-tests.md` § 8.4 — dependency scanning in CI | (workflow)                        | ⊘       | No package manifest in this docs repo — nothing to audit                 |
| `09-new-project-flow.md` — private GitHub repo | repo settings                      | ⊘       | This repo is intentionally public (the skill itself, OSS by design)      |
| `09-new-project-flow.md` — branch protection on `main` (Rulesets) | repo settings | ❓       | Owner-side config; not visible in working tree. Recommended: enable.    |
| `09-new-project-flow.md` — secret scanning + push protection | repo settings | ❓       | Owner-side config; recommended: enable.                                 |
| `10-recommended-files.md` — `dependabot.yml` | `.github/dependabot.yml`             | ✅       | Watches `github-actions` ecosystem                                       |
| `10-recommended-files.md` — `CODEOWNERS` | `.github/CODEOWNERS`                     | ✅       | Topic-specific paths (SKILL.md, reference/, scripts/, .github/workflows/) |

**Helper scripts surfaced via `SKILL.md`:**

- `scripts/install-pre-commit.sh` — drops gitleaks + detect-private-key as a pre-commit hook. Has `--yes` for CI, `--force` for explicit overwrite, `--install-gitleaks` for offline-install, validates shellcheck severity=warning. Self-applies `08-tests.md` § 8.3.
- `scripts/bootstrap-private-repo.sh` — runs `09-new-project-flow.md` deterministically: `.gitignore` first → `gh repo create --private` → Rulesets → Secret Scanning + Push Protection + Dependabot. Self-applies `09-new-project-flow.md`.

### Verdict — T5: **A**

The repo doesn't just *describe* its rules — it runs them on itself in CI (gitleaks, semgrep, markdownlint, lychee, shellcheck) and ships scripts that other projects can use to apply the same rules. This is the strongest of the seven tests for v1.1.0 — and a clear improvement over v1.0.0, where the same audit was a checkbox match against config presence rather than executed checks.

---

## 8. T6 — Scenario walkthroughs

For each scenario in `README.md`'s "Examples" section, I traced what the skill prescribes and graded whether SKILL.md + the reference tree give Claude enough specifics to complete the scenario without further user clarification.

### 8.1 Scenario A: "Create a new Node.js Express API for a todo app, with auth"

| Phase                  | README claim                                          | Skill prescription                                                                              | Sufficient? |
| ---------------------- | ----------------------------------------------------- | ----------------------------------------------------------------------------------------------- | ----------- |
| Threat planning        | "plan threats"                                        | `reference/01-planning.md`                                                                      | ✅           |
| Auth implementation    | "argon2id + zod + helmet + rate-limit + cookies"      | `reference/03-patterns/auth.md` (argon2id + refresh tokens), `validation.md`, `headers.md`, `14-stacks/node.md` | ✅       |
| Project files          | ".gitignore + .env.example + SECURITY.md + THREAT_MODEL.md" | `reference/02-secrets.md` § 2.2, `reference/05-project-config.md`                          | ✅           |
| Git init + first commit | "git init + secret-scan + commit"                    | `reference/09-new-project-flow.md`, `reference/02-secrets.md` § 2.3                              | ✅           |
| Bootstrap              | "deterministic execution"                             | **`scripts/bootstrap-private-repo.sh`** — one-shot invocation                                   | ✅           |
| Branch protection      | "apply branch protection"                             | `reference/07-ci-cd.md` § 7.4 (modern Rulesets API)                                              | ✅           |
| Dependabot             | "enable Dependabot"                                   | `reference/10-recommended-files.md` (template)                                                  | ✅           |

**Verdict:** Complete prescription. The new helper script makes Scenario A's bootstrap step a one-liner where v1.0.0 required Claude to execute a 12-step recipe by hand.

### 8.2 Scenario B: "I'm about to commit. Anything I should fix?"

| Phase                  | Skill prescription                                            | Sufficient? |
| ---------------------- | ------------------------------------------------------------- | ----------- |
| Status check           | `SKILL.md` always-on rules § 1                                | ✅           |
| Diff review            | `SKILL.md` always-on rules § 2                                | ✅           |
| Secret scan            | `SKILL.md` always-on rules § 3 → `reference/02-secrets.md` § 2.3 (provider-token grep) | ✅       |
| Quality gates          | `reference/11-commit-push.md`                                 | ✅           |
| Summarize              | `reference/12-summary-template.md`                            | ✅           |

**Verdict:** Complete prescription. The always-on rules in the SKILL.md core (lines 28–51) make this scenario partially handled without opening any reference file.

### 8.3 Scenario C: "Add file upload to the avatar endpoint"

| Phase                  | Skill prescription                                            | Sufficient? |
| ---------------------- | ------------------------------------------------------------- | ----------- |
| MIME sniffing          | `reference/03-patterns/uploads.md` PASS block (`fileTypeFromBuffer`) | ✅       |
| Server-side filename   | `reference/03-patterns/uploads.md` (`crypto.randomUUID()`)    | ✅           |
| Storage location       | `reference/03-patterns/uploads.md` (S3 example) + rule list   | ✅           |
| Image re-encoding      | `reference/03-patterns/uploads.md` rule list (`sharp`)        | ✅ (rules; not in code block — see T3)  |
| Size cap               | `reference/03-patterns/uploads.md` rule list                  | ✅           |

**Verdict:** Complete prescription. Same minor T3 note: the `sharp` re-encoding step is in the rule list, not the code block.

### Verdict — T6: **A**

All three README scenarios are fully reachable from the modular skill content. The new layout makes scenario walkthroughs *more* readable than v1.0.0 — Claude reads the SKILL.md core (≈ 100 lines, always loaded), then opens only the specific reference file(s) the work touches.

---

## 9. T7 — Gap analysis

`SKILL.md` claims to address the OWASP Top 10 (which it does, T2) plus several adjacent surfaces. This section flags attack classes / footguns that are **not** covered, ranked by severity.

### 9.1 Resolved since v1.0.0 evaluation

| Gap (was)                | Current status in v1.1.0                                                       |
| ------------------------ | ------------------------------------------------------------------------------- |
| **DNS rebinding**        | ✅ Now noted in `reference/03-patterns/ssrf.md` with the "resolve once, pin IP, dial directly" recommendation. |
| **404 vs 403 oracle**    | ✅ Now discussed in `reference/03-patterns/authorization.md` as a tradeoff per surface. |
| Install-time scripts (postinstall) | ✅ Now in `reference/04-supply-chain.md` § 4.2 with `--ignore-scripts` and Yarn 4 `enableScripts: false`. |

### 9.2 High-priority gaps (remaining)

| Gap                                                | Why it matters                                                                                                       | Suggested home                          |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| **Open redirect**                                  | OAuth callback handlers, post-login `?next=…` redirects, password-reset confirmation. Allowlist of trusted hosts before `res.redirect(input)`. Search confirms no current coverage. | New `reference/03-patterns/redirect.md` |
| **Insecure deserialization**                       | Java `ObjectInputStream`, Python `pickle`, Ruby Marshal, .NET `BinaryFormatter`, Node `node-serialize`. RCE class with high impact. No coverage. | New `reference/03-patterns/deserialization.md` |
| **Server-side template injection (SSTI)**          | Jinja2/Twig/Handlebars/EJS render user input as template. RCE in many Python frameworks. Not covered. | Could fit inside `xss-csrf.md` or new file |

### 9.3 Medium-priority gaps (remaining)

| Gap                                                | Why it matters                                                                                                       | Suggested home                          |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| **TOCTOU race conditions**                         | File operations (check exists → use), lockfile-style auth checks, transactional balance reads. Subtle but exploitable. | `authorization.md` or new file          |
| **Subdomain takeover**                             | Dangling DNS pointing at decommissioned cloud resources. Operational hygiene. | `reference/09-new-project-flow.md` ops note |

### 9.4 Lower-priority gaps

- **Prototype pollution (JS-specific)** — `lodash.merge` / `Object.assign` on user-controlled keys. Can escalate to RCE in some Node patterns.
- **HTTP request smuggling** — TE/CL desync. Mostly mitigated by modern proxies; still seen in misconfigured stacks.
- **Cache poisoning / Cache-Control discipline** — Auth-decisioned responses cached at CDN.
- **WebSocket auth + origin checks** — Auth must be re-checked on first message, not just upgrade.
- **GraphQL-specific abuses** — Query depth, alias amplification, batch-introspection.
- **Mobile / native client trust** — App attestation, certificate pinning.

### 9.5 Reviewer's call

The remaining High-priority three (open redirect, insecure deserialization, SSTI) are common enough in real apps that they deserve at least one paragraph each. A v1.2 PR adding `reference/03-patterns/redirect.md` and `reference/03-patterns/deserialization.md` (plus a one-liner cross-reference for SSTI in `xss-csrf.md`) would push this test to A.

### Verdict — T7: **B**

Coverage is broad and useful; gaps are real but bounded. v1.1.0 closed one of my v1.0.0 high-priority gaps (DNS rebinding); three remain.

---

## 10. Aggregate score and recommendations

**Aggregate grade: A-**

The skill, post-PR-#1, is **substantially stronger** than the v1.0.0 release I previously graded (B+). The headline content debt (`csurf` deprecation), the headline structural gap (DNS rebinding), and the headline credibility issue (the repo not running its own checks) are all resolved.

The A- (vs A) reflects three remaining items, in priority order:

1. **Three high-impact attack classes are absent** — open redirect, insecure deserialization, SSTI. (T7) Net-new content; ~150 lines total.
2. **`crypto.timingSafeEqual` precondition missing.** (T3) One-line note that buffers must be the same length.
3. **`passlib` Python is 5+ years stale.** (T4) `reference/14-stacks/{fastapi,django}.md` should annotate or prefer `argon2-cffi` directly.

### Prioritized fix list

| Priority | Item                                                                                       | Where                                                          | Effort  |
| -------- | ------------------------------------------------------------------------------------------ | -------------------------------------------------------------- | ------- |
| 1        | New `reference/03-patterns/redirect.md` — open redirect (FAIL/PASS + allowlist pattern)     | new file                                                       | ~50 LOC |
| 2        | New `reference/03-patterns/deserialization.md` — insecure deserialization per language     | new file                                                       | ~80 LOC |
| 3        | Add SSTI cross-reference to `xss-csrf.md` (or new file)                                     | edit / new file                                                | ~20 LOC |
| 4        | Annotate `passlib` staleness; prefer `argon2-cffi` directly                                 | `reference/14-stacks/{fastapi,django}.md`                      | 2 lines |
| 5        | Add `crypto.timingSafeEqual` equal-length precondition note                                 | `reference/03-patterns/rate-limit-crypto.md`                   | 1 line  |
| 6        | Note Aqua's tfsec → trivy migration                                                         | `reference/08-tests.md` § 8.2                                   | 1 line  |
| 7        | Fix MD060 in two table separator rows (`SKILL.md:58`, `README.md:114`)                      | `SKILL.md`, `README.md`                                        | 4 chars |
| 8        | Rename `exclude_mail = true` → `include_mail = false` in `lychee.toml`                       | `lychee.toml`                                                  | 1 line  |
| 9        | Add a worked DNS-pinning code example to `ssrf.md`                                          | `reference/03-patterns/ssrf.md`                                 | ~30 LOC |
| 10       | Bump CI Action SHAs (Dependabot will likely surface these automatically)                    | `.github/workflows/self-check.yml`                              | 6 SHAs  |

Items 7 and 8 are 5 minutes of work each. Items 1–3 are content additions worth a v1.2 release.

### What works

- The thin-core / on-demand-reference architecture is genuinely better than the v1.0.0 monolith — Claude reads less by default, opens only the relevant slice.
- The narrowed activation in the `description` frontmatter (high-stakes surfaces only, skip routine refactors) is the right call — v1.0.0's "every coding task" was overzealous.
- The repo *runs* the rules it prescribes, in CI, on every push. That's the strongest kind of self-application.
- `scripts/bootstrap-private-repo.sh` and `scripts/install-pre-commit.sh` mechanize what the skill prescribes — converting "Claude follows these 12 steps" into "the user runs `./bootstrap.sh foo --yes`."
- v1.1.0 closed three of my four v1.0.0 high-priority complaints (`csurf`, DNS rebinding, install-script sandboxing) and added two non-obvious improvements (404-vs-403 oracle discussion, signed double-submit CSRF).

### What this evaluation is and isn't

**This is** a static + reviewer-graded assessment of the skill's content as of 2026-05-03. T1 is reproducible by anyone in 30 seconds; T2–T7 are reviewer-graded, but the rubric is in § 1 above and the findings are concrete enough to challenge.

**This is not** a behavioural test of "does Claude actually follow the skill when it's loaded?" That requires sandboxed model runs. A future evaluation harness (`docs/tests/behavioural.md`, not in this PR) could compare Claude-with-skill vs. Claude-without on a benchmark of build prompts and score outputs against the rule lists in `reference/03-patterns/*.md`.

---

## Appendix A — v1.0.0 evaluation grades (for delta tracking)

The v1.0.0 (commit `00f87cc`, released 2026-05-02) evaluation that preceded PR #1 produced:

| Test | v1.0.0 grade | v1.1.0 grade | Δ          |
| ---- | ------------ | ------------ | ---------- |
| T1   | A            | B+           | ↓ (table lint, lychee config — both 5-min fixes) |
| T2   | A            | A            | =          |
| T3   | B            | A-           | ↑ (csurf resolved; argon2 cost params; DNS rebinding noted) |
| T4   | B            | B+           | ↑ (csurf no longer cited)                       |
| T5   | A            | A            | = (now stronger — runs checks, not just config presence) |
| T6   | A            | A            | =          |
| T7   | B            | B            | = (DNS rebinding closed; three high-priority gaps remain) |
| **Aggregate** | **B+** | **A-**     | **↑**     |

The two T1 regressions are config-version mismatches introduced by PR #1, not new defects in the security content; both are 5-minute fixes.

---

*Re-run instructions: see [`docs/tests/RUNNING.md`](./tests/RUNNING.md). The repo's own `.github/workflows/self-check.yml` runs T1's automated subset on every push and PR; T2–T7 are designed to be re-graded by a fresh reviewer once a year or after any change to `SKILL.md` or `reference/03-patterns/*.md`.*
