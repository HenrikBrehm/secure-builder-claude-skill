# secure-builder

> A Claude Code skill that turns Claude into a secure-by-default senior engineer.
> The easy path becomes the safe path.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skill-8A2BE2.svg)](https://docs.claude.com/en/docs/claude-code)
[![Status: stable](https://img.shields.io/badge/status-stable-brightgreen.svg)](#)

## What it does

`secure-builder` is a single-file [Claude Code](https://docs.claude.com/en/docs/claude-code) skill that auto-activates whenever Claude is asked to **build, edit, scaffold, refactor, review, commit, or publish** software.

Instead of treating security as a code-review afterthought, the skill makes Claude:

- **Plan threats before writing code** — entry points, trust boundaries, assets, top risks.
- **Apply secure-by-default patterns** — argon2id passwords, parameterized queries, CSP/HSTS, SameSite cookies, SSRF guards, file-type sniffing, AEAD crypto.
- **Protect secrets** — write `.gitignore` and `.env.example` *before* the first commit, scan staged diffs, mask logs, refuse to commit `*.pem`/`*.env`/credentials.
- **Harden CI/CD** — pin GitHub Actions by SHA, set `permissions: {}`, OIDC over long-lived keys, branch protection, CODEOWNERS.
- **Harden Docker** — pin base images by digest, run as non-root, multi-stage, BuildKit secrets.
- **Add security tests** — IDOR, expired tokens, oversized payloads, login rate-limit, file-upload edge cases.
- **Run the full new-project flow** — private GitHub repo, secret scanning, dependabot, branch protection, signed commits.

The full ruleset lives in [`SKILL.md`](./SKILL.md) — 14 sections, ~1000 lines, no fluff.

## Why use it

Most security work is bolted on at the end. By then the easy path has already been taken in 50 places. `secure-builder` flips that: every time Claude touches code, the security checklist is loaded into context first, and the *default* output is hardened.

- **Zero config.** Drop one file in `~/.claude/skills/` and it activates on relevant requests.
- **Stack-agnostic.** Patterns for Node, Python, Go, Rust, Java, .NET, Ruby — see Section 14.
- **Opinionated about defaults, not about your stack.** It enforces argon2id over MD5, not Express over Fastify.
- **Self-applying.** The skill follows its own rules — `.gitignore` first, secret scan before commit, private-by-default repos.

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

### Option 2 — Copy just SKILL.md

```bash
mkdir -p ~/.claude/skills/secure-builder
curl -fsSL https://raw.githubusercontent.com/HenrikBrehm/secure-builder-claude-skill/main/SKILL.md \
  -o ~/.claude/skills/secure-builder/SKILL.md
```

### Option 3 — Git submodule (for dotfiles repos)

```bash
git submodule add https://github.com/HenrikBrehm/secure-builder-claude-skill.git \
  .claude/skills/secure-builder
```

### Verify

Open Claude Code and run:

```
/secure-builder
```

The skill should load. Or just ask Claude to "build me a small Express API with login" and watch the secure defaults appear automatically.

## Usage

The skill **auto-activates** on any build/edit/scaffold/refactor/review/commit/publish request — you don't need to invoke it manually. But you can:

```
/secure-builder
```

…to load it explicitly into context, e.g. before a security review.

### Examples

#### 1. Scaffold a new private project

> *"Create a new Node.js Express API for a todo app, with auth."*

Claude will (a) plan threats, (b) scaffold with argon2id + zod validation + helmet + rate-limit + httpOnly cookies, (c) write `.gitignore` + `.env.example` + `SECURITY.md` + `THREAT_MODEL.md`, (d) `git init` + secret-scan + commit, (e) `gh repo create --private --source=. --push`, (f) apply branch protection and enable Dependabot.

#### 2. Review existing code before commit

> *"I'm about to commit. Anything I should fix?"*

Claude will run through Section 11 (Commit & push safety): `git status`, `git diff --cached`, secret scan, lint/typecheck/tests, then summarize.

#### 3. Add a feature to an existing app

> *"Add file upload to the avatar endpoint."*

Claude will sniff content type from magic bytes, server-generate filenames, store outside web root, re-encode images, cap size and per-user count — even though you didn't mention any of that.

## What's inside SKILL.md

| § | Topic |
|---|-------|
| 1 | Security planning before coding |
| 2 | Secrets protection (`.gitignore`, `.env.example`, scanning, rotation) |
| 3 | Secure-by-default patterns (auth, authz, validation, SQL/NoSQL, XSS, CSRF, SSRF, uploads, errors, logging, headers, rate-limit, crypto) |
| 4 | Dependency & supply-chain hygiene |
| 5 | Hardened project config (`.editorconfig`, `SECURITY.md`, `THREAT_MODEL.md`) |
| 6 | Docker hardening |
| 7 | CI/CD hardening (GitHub Actions) |
| 8 | Tests & security checks |
| 9 | New-project flow (private repo, branch protection, secret scanning) |
| 10 | Recommended files (`dependabot.yml`, `CODEOWNERS`, pre-commit, `.dockerignore`) |
| 11 | Commit & push safety |
| 12 | Final summary template |
| 13 | When to pause and ask |
| 14 | Stack quick-reference (Node, Next.js, FastAPI, Django, Go, Rust, Spring, .NET, Rails) |

## Contributing

Pull requests welcome. Read [CONTRIBUTING.md](./CONTRIBUTING.md) first.

The bar for new patterns: **a real exploit class it prevents, a concrete FAIL/PASS pair, and a stack reference.** No "best practice" without a "what breaks if you skip this" justification.

## Security

Found a vulnerability or a footgun in the skill itself (e.g., a recommended pattern that's actually unsafe)? See [SECURITY.md](./SECURITY.md). Please don't open public issues for security problems.

## License

[MIT](./LICENSE) © 2026 HenrikBrehm

## Acknowledgments

- The Claude Code team for the skill system.
- The OWASP project, the Go/Rust/Python security working groups, and a decade of `gitleaks`/`semgrep`/`trivy` maintainers whose heuristics feed Section 8.
