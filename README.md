# secure-builder

> A Claude Code skill that turns Claude into a secure-by-default senior engineer.
> The easy path becomes the safe path.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skill-8A2BE2.svg)](https://docs.claude.com/en/docs/claude-code)
[![self-check](https://github.com/HenrikBrehm/secure-builder-claude-skill/actions/workflows/self-check.yml/badge.svg)](https://github.com/HenrikBrehm/secure-builder-claude-skill/actions/workflows/self-check.yml)

## What it does

`secure-builder` is a [Claude Code](https://docs.claude.com/en/docs/claude-code) skill that activates when Claude is asked to **scaffold a project, write auth/authz/session/password code, handle uploads, fetch user-supplied URLs, touch secrets, change deployment configs, edit Dockerfiles or CI workflows, install dependencies, or run a pre-commit/pre-push review**. (Routine refactors, renames, typos, and pure UI work do not load it.)

Instead of treating security as a code-review afterthought, the skill makes Claude:

- **Plan threats before writing code** — entry points, trust boundaries, assets, top risks.
- **Apply secure-by-default patterns** — argon2id with explicit cost params, parameterized queries, nonce/strict-dynamic CSP, SameSite cookies, SSRF guards, file-type sniffing, AEAD crypto, refresh-token rotation.
- **Protect secrets** — write `.gitignore` and `.env.example` *before* the first commit, scan staged diffs, mask logs, refuse to commit `*.pem`/`*.env`/credentials.
- **Harden CI/CD** — pin GitHub Actions by SHA, set `permissions: {}`, OIDC over long-lived keys, branch protection via the modern Rulesets API, CODEOWNERS.
- **Harden Docker** — pin base images by digest, run as non-root, multi-stage, BuildKit secrets, `npm ci --ignore-scripts`.
- **Add security tests** — IDOR, expired tokens, oversized payloads, login rate-limit, file-upload edge cases.
- **Run the full new-project flow** — private GitHub repo, secret scanning, dependabot, branch protection, signed commits — also available as a single deterministic script.

## Layout

```
SKILL.md                          # ~100-line core: behavior loop + always-on rules + reference map
reference/01-13/, 14-stacks/      # 31 topic files Claude opens on demand
scripts/                          # bash helpers (shellcheck-clean, --yes for CI)
  install-pre-commit.sh
  bootstrap-private-repo.sh
.github/workflows/self-check.yml  # CI runs gitleaks + semgrep + markdownlint + lychee + shellcheck on this repo
```

The thin core is what gets loaded into Claude's context every time the skill activates. Topic files (auth, uploads, CSP, Docker, CI/CD, etc.) are pulled in only when the work calls for them — so you don't pay context cost for upload guidance while writing a database migration.

## Self-applying

This repo eats its own dogfood. Every push runs the same checks SKILL.md prescribes:

- **gitleaks** — secret scan on the diff
- **semgrep** — `p/owasp-top-ten` + `p/security-audit`
- **markdownlint** — structure of SKILL.md and the reference tree
- **lychee** — every external link in SKILL.md / reference/* still resolves
- **shellcheck** — both helper scripts

CI status badge is at the top. If a recommendation in SKILL.md ever stops passing on this repo, the badge goes red and the bug is the recommendation, not the workflow.

## Why use it

Most security work is bolted on at the end. By then the easy path has already been taken in 50 places. `secure-builder` flips that: every time Claude touches security-sensitive code, the relevant checklist is loaded into context first, and the *default* output is hardened.

- **Thin core.** SKILL.md is ~100 lines; topic detail is opened on demand. No more 35 KB of upload guidance loaded while you're editing CSS.
- **Stack-agnostic.** Patterns for Node, Next.js, FastAPI, Django, Go, Rust, Spring, .NET, Rails — see [`reference/14-stacks/`](./reference/14-stacks).
- **Opinionated about defaults, not about your stack.** It enforces argon2id with explicit cost params over MD5, not Express over Fastify.
- **Self-applying** (badge above).

## Install

### Option 1 — Clone (recommended, easy to update)

```bash
git clone https://github.com/HenrikBrehm/secure-builder-claude-skill.git \
  ~/.claude/skills/secure-builder
```

Update later with:
```bash
git -C ~/.claude/skills/secure-builder pull
```

### Option 2 — Git submodule (for dotfiles repos)

```bash
git submodule add https://github.com/HenrikBrehm/secure-builder-claude-skill.git \
  .claude/skills/secure-builder
```

> Single-file `curl SKILL.md` install is no longer recommended — Claude needs the `reference/` tree and `scripts/` to follow the references in SKILL.md.

### Verify

Open Claude Code and ask Claude to "scaffold a small Express auth API" — the secure defaults (argon2id with cost params, refresh-token rotation, helmet, csrf-csrf, gitleaks pre-commit hook, private repo with branch protection) should appear automatically.

## Usage

The skill **auto-activates** when the work matches its description (auth code, uploads, secrets, deployment configs, CI workflows, dependency installs, pre-commit/pre-push reviews). You can also load it explicitly with `/secure-builder`.

### Examples

#### 1. Scaffold a new private project

> *"Create a new Node.js Express API for a todo app, with auth."*

Claude (a) plans threats, (b) scaffolds with argon2id (`{ memoryCost: 19456, timeCost: 2, parallelism: 1 }`) + zod validation + helmet + rate-limit + httpOnly cookies + refresh-token rotation, (c) writes `.gitignore` + `.env.example` + `SECURITY.md` + `THREAT_MODEL.md`, (d) runs `gitleaks detect` + commits, (e) `gh repo create --private --source=. --push`, (f) applies branch protection via Rulesets and enables Dependabot. Same flow is also one command: `./scripts/bootstrap-private-repo.sh todo-api`.

#### 2. Review existing code before commit

> *"I'm about to commit. Anything I should fix?"*

Claude runs `git status`, `git diff --cached`, the secret scan, lint/typecheck/tests, then summarizes — see `reference/11-commit-push.md`.

#### 3. Add a feature to an existing app

> *"Add file upload to the avatar endpoint."*

Claude opens `reference/03-patterns/uploads.md`, sniffs content type from magic bytes, server-generates filenames, stores outside web root, re-encodes images, caps size and per-user count — even though you didn't mention any of that.

## What's inside

The skill itself ([`SKILL.md`](./SKILL.md)) is a thin always-loaded core. Detail lives under [`reference/`](./reference/) and gets opened on demand:

| § | Topic | File |
|---|---|---|
| 1 | Security planning before coding | [`reference/01-planning.md`](./reference/01-planning.md) |
| 2 | Secrets protection (`.gitignore`, `.env.example`, scanning, rotation) | [`reference/02-secrets.md`](./reference/02-secrets.md) |
| 3.1 | Authentication (argon2id, JWT + refresh tokens) | [`reference/03-patterns/auth.md`](./reference/03-patterns/auth.md) |
| 3.2 | Authorization (IDOR, default deny, mass assignment) | [`reference/03-patterns/authorization.md`](./reference/03-patterns/authorization.md) |
| 3.3 | Input validation (Zod / Pydantic) | [`reference/03-patterns/validation.md`](./reference/03-patterns/validation.md) |
| 3.4 | SQL / NoSQL injection | [`reference/03-patterns/injection.md`](./reference/03-patterns/injection.md) |
| 3.5 + 3.6 | XSS + CSRF (`csrf-csrf`, signed double-submit) | [`reference/03-patterns/xss-csrf.md`](./reference/03-patterns/xss-csrf.md) |
| 3.7 | SSRF (private-IP block, DNS rebinding) | [`reference/03-patterns/ssrf.md`](./reference/03-patterns/ssrf.md) |
| 3.8 | File uploads (magic-byte sniff, server-gen names) | [`reference/03-patterns/uploads.md`](./reference/03-patterns/uploads.md) |
| 3.9 + 3.10 | Error handling and logging | [`reference/03-patterns/errors-logging.md`](./reference/03-patterns/errors-logging.md) |
| 3.11 | Security headers (CSP nonce / hash / strict-dynamic) | [`reference/03-patterns/headers.md`](./reference/03-patterns/headers.md) |
| 3.12 + 3.13 | Rate-limit and crypto | [`reference/03-patterns/rate-limit-crypto.md`](./reference/03-patterns/rate-limit-crypto.md) |
| 4 | Dependency & supply-chain (`--ignore-scripts`, SBOM/SLSA) | [`reference/04-supply-chain.md`](./reference/04-supply-chain.md) |
| 5 | Hardened project config (`.editorconfig`, `SECURITY.md`, `THREAT_MODEL.md`) | [`reference/05-project-config.md`](./reference/05-project-config.md) |
| 6 | Docker hardening | [`reference/06-docker.md`](./reference/06-docker.md) |
| 7 | CI/CD hardening (GitHub Actions, Rulesets API) | [`reference/07-ci-cd.md`](./reference/07-ci-cd.md) |
| 8 | Tests & security checks | [`reference/08-tests.md`](./reference/08-tests.md) |
| 9 | New-project flow (private repo bootstrap) | [`reference/09-new-project-flow.md`](./reference/09-new-project-flow.md) |
| 10 | Recommended files | [`reference/10-recommended-files.md`](./reference/10-recommended-files.md) |
| 11 | Commit & push safety | [`reference/11-commit-push.md`](./reference/11-commit-push.md) |
| 12 | Final summary template | [`reference/12-summary-template.md`](./reference/12-summary-template.md) |
| 13 | When to pause and ask | [`reference/13-pause-and-ask.md`](./reference/13-pause-and-ask.md) |
| 14 | Stack quick-reference | [`reference/14-stacks/`](./reference/14-stacks/) (Node, Next.js, FastAPI, Django, Go, Rust, Spring, .NET, Rails) |

## Contributing

Pull requests welcome. Read [CONTRIBUTING.md](./CONTRIBUTING.md) first.

The bar for new patterns: **a real exploit class it prevents, a concrete FAIL/PASS pair, and a stack reference.** No "best practice" without a "what breaks if you skip this" justification.

## Security

Found a vulnerability or a footgun in the skill itself (e.g., a recommended pattern that's actually unsafe)? See [SECURITY.md](./SECURITY.md). Please don't open public issues for security problems.

## License

[MIT](./LICENSE) © 2026 HenrikBrehm

## Acknowledgments

- The Claude Code team for the skill system.
- The OWASP project, the Go/Rust/Python security working groups, and a decade of `gitleaks` / `semgrep` / `trivy` maintainers whose heuristics feed Section 8.
