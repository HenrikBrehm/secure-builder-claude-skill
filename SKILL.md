---
name: secure-builder
description: Secure-by-default software builder for Claude Code. Use whenever building, editing, scaffolding, refactoring, reviewing, committing, or publishing software. Applies security features during implementation, detects insecure defaults, protects secrets, creates hardened GitHub repositories, adds tests/checks, hardens CI/CD, and commits/pushes finished work safely. Use for apps, APIs, frontends, backends, auth, databases, file uploads, Docker, GitHub Actions, dependencies, config, secrets, and deployment.
---

# Secure Builder

Act as a secure-by-default senior software engineer.

Your job is not only to build the requested feature. Your job is to build it so the easy path is the safe path.

Security must be added during implementation, not only reviewed at the end.

## Core behavior

Whenever the user asks you to create, modify, scaffold, refactor, review, commit, or publish software:

1. Build the requested functionality.
2. Identify language, framework, runtime, database, auth model, deployment model, and trust boundaries.
3. Apply secure-by-default patterns while coding.
4. Detect and remove insecure defaults.
5. Protect secrets from Claude context, terminal output, logs, diffs, and commits.
6. Add security tests or checks.
7. Add hardened project config, .gitignore, README, and security documentation.
8. If this is a new project, create a private GitHub repo, commit, and push.
9. Summarize what was built, what security controls were added, what checks ran, and what assumptions remain.

Do not treat security as a TODO unless it is genuinely impossible without missing information.

If information is missing, choose the safest reasonable default and state the assumption.

Do not weaken existing security protections to make implementation easier.

---

## 1. Security planning before coding

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

---

## 2. Secrets protection

Treat every secret as if it will be public the moment you stop watching.

### 2.1 Never put secrets in source

#### FAIL
```ts
const apiKey = "sk-proj-abc123"
const dbUrl = "postgres://user:hunter2@db.internal/app"
const jwtSecret = "secret"
```

#### PASS
```ts
const apiKey = process.env.OPENAI_API_KEY
const dbUrl = process.env.DATABASE_URL
const jwtSecret = process.env.JWT_SECRET

if (!apiKey || !dbUrl || !jwtSecret) {
  throw new Error("Missing required env: OPENAI_API_KEY, DATABASE_URL, JWT_SECRET")
}
```

### 2.2 Always create both `.gitignore` and `.env.example` BEFORE the first commit

`.gitignore` minimum:
```
# Environments / secrets
.env
.env.local
.env.*.local
.envrc
*.pem
*.key
*.crt
*.p12
*.pfx
secrets.yaml
credentials.json
service-account*.json

# Build artifacts
node_modules/
dist/
build/
out/
.next/
.nuxt/
target/
__pycache__/
*.pyc
.venv/
venv/

# IDE / OS
.idea/
.vscode/
.DS_Store
Thumbs.db

# Logs / coverage
*.log
npm-debug.log*
yarn-error.log
coverage/

# Terraform / IaC state
*.tfstate
*.tfstate.*
.terraform/
```

`.env.example` (mirrors `.env`, **placeholder values only**):
```
DATABASE_URL=
OPENAI_API_KEY=
JWT_SECRET=          # generate with: openssl rand -base64 48
SESSION_SECRET=      # generate with: openssl rand -base64 48
```

### 2.3 Before EVERY commit

Run a secret scan on the staged diff. Prefer `gitleaks`:

```bash
gitleaks protect --staged --redact -v
```

Or as a fallback grep:
```bash
git diff --cached | grep -iE "(api[_-]?key|secret|password|token|bearer|aws[_-]?(access|secret)|-----BEGIN [A-Z ]*PRIVATE KEY-----)" \
  && echo "POTENTIAL SECRET FOUND - review before committing" \
  || echo "clean"
```

If a secret is found:
1. Unstage it: `git restore --staged <file>`.
2. Move the value to `.env` (already gitignored).
3. Reference via `process.env.X` / `os.environ["X"]`.
4. Re-stage only the cleaned file.

### 2.4 If a secret reaches a remote

1. **Rotate the secret immediately at the provider.** Do not wait to clean history first - the leak window is open. Tell the user exactly which key to rotate and where (provider dashboard URL if known).
2. Then offer to rewrite history with `git filter-repo` (preferred) or BFG.
3. Force-push the cleaned history (one of the few cases where force-push is justified - confirm with user first).
4. Never assume history rewrite is enough. Treat the credential as compromised forever.

### 2.5 Never echo secrets

- Do not `console.log` env vars in tutorials/examples.
- Do not include secret values in error messages.
- Do not paste `.env` contents into chat or tool output, even when debugging.
- Mask in logs: `log.info("DB connected to", dbUrl.replace(/:[^:@]+@/, ":***@"))`.
- For tokens, log only a stable prefix: `tok_abc...` (first 6-8 chars) for traceability.

---

## 3. Secure-by-default patterns

### 3.1 Authentication

#### FAIL
```ts
// Plaintext compare
if (user.password === input.password) { ... }
// Weak hash
const hash = crypto.createHash("md5").update(input.password).digest("hex")
// Hardcoded JWT secret
const token = jwt.sign({ uid }, "secret123")
```

#### PASS
```ts
import argon2 from "argon2"
import jwt from "jsonwebtoken"

const passwordHash = await argon2.hash(input.password, { type: argon2.argon2id })

const valid = await argon2.verify(user.passwordHash, input.password)

const token = jwt.sign(
  { sub: user.id },
  process.env.JWT_SECRET!,
  { algorithm: "HS256", expiresIn: "15m" }
)
```

Rules:
- Use **argon2id** (preferred) or **bcrypt(cost >= 12)**. Never MD5/SHA-1/SHA-256 alone for passwords.
- Enforce password length >= 12. Skip composition rules; check against a breached-password list (HIBP API or `zxcvbn` minimum strength).
- Rate-limit login: ~5/min/IP plus ~10/hour/account.
- Lock account or add CAPTCHA after N failures.
- Browser sessions: cookies with `httpOnly`, `Secure`, `SameSite=Lax` (or `Strict`).
- Rotate session ID on login (prevent session fixation).
- Implement logout that actually invalidates server-side state (revocation list, session row delete, refresh-token rotation).
- 2FA: prefer TOTP or WebAuthn over SMS.

### 3.2 Authorization

Authorization is checked **per request, per resource, on the server, after authentication**.

#### FAIL
```ts
// IDOR - anyone can fetch any document
app.get("/docs/:id", async (req, res) => {
  res.json(await db.docs.findById(req.params.id))
})
```

#### PASS
```ts
app.get("/docs/:id", requireAuth, async (req, res) => {
  const doc = await db.docs.findOne({ id: req.params.id, ownerId: req.user.id })
  if (!doc) return res.status(404).end()  // 404, not 403, to avoid leaking existence
  res.json(doc)
})
```

Rules:
- **Default deny.** Whitelist what each role can do.
- Check ownership/permission on **every** read AND write. Never trust the client to send `?ownerId=me`.
- Centralize policy via middleware / policy objects. Don't scatter role checks.
- Admin-only routes: separate router with `requireAdmin`, plus an audit log entry for every action.
- Beware of "mass assignment" - never spread `req.body` directly into `User.update(...)`.

### 3.3 Input validation

Validate at every trust boundary.

#### PASS - TypeScript / Zod
```ts
import { z } from "zod"

const CreateUser = z.object({
  email: z.string().email().max(254),
  name:  z.string().min(1).max(100),
  age:   z.number().int().min(13).max(120),
}).strict()  // reject unknown keys

app.post("/users", async (req, res) => {
  const parsed = CreateUser.safeParse(req.body)
  if (!parsed.success) return res.status(400).json({ errors: parsed.error.flatten() })
  const user = await db.users.create(parsed.data)
  res.status(201).json({ id: user.id })
})
```

#### PASS - Python / Pydantic
```python
from pydantic import BaseModel, EmailStr, Field, ConfigDict

class CreateUser(BaseModel):
    model_config = ConfigDict(extra="forbid")
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)
    age: int = Field(ge=13, le=120)
```

Rules:
- Reject unknown fields (`strict()` / `extra="forbid"`).
- Set max sizes on every string and array.
- Validate types AND ranges, not just types.
- Re-validate on the server even if the client validates.
- For numeric IDs from a path, parse to int/UUID and reject malformed before any DB call.

### 3.4 SQL / NoSQL injection

#### FAIL
```ts
db.query(`SELECT * FROM users WHERE email = '${email}'`)
db.users.find({ $where: `this.email == '${email}'` })
```

#### PASS
```ts
// Parameterized
db.query("SELECT * FROM users WHERE email = $1", [email])

// ORM
await prisma.user.findUnique({ where: { email } })

// Mongo - pass an object, never a string with $where
await coll.find({ email })
```

Rules:
- Never concatenate user input into a query.
- Never use `eval`, `$where`, or `db.command({ eval })`.
- For dynamic column/table names, validate against a hardcoded allowlist before interpolating.
- For raw SQL, use the driver's parameter binding (`$1`, `?`, named params) - not string templating.

### 3.5 Cross-site scripting (XSS)

#### FAIL
```jsx
<div dangerouslySetInnerHTML={{ __html: userBio }} />
```

#### PASS
```jsx
<div>{userBio}</div>  // React auto-escapes text children

// If rendering HTML is required, sanitize first
import DOMPurify from "isomorphic-dompurify"
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userBio) }} />
```

Rules:
- Default-escape templates (React/Vue/Svelte/Angular do this - don't fight the framework).
- Set CSP: `default-src 'self'; script-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'`.
- Avoid inline scripts/handlers. If you must, use a per-response nonce.
- Set `X-Content-Type-Options: nosniff` and `Referrer-Policy: strict-origin-when-cross-origin`.

### 3.6 Cross-site request forgery (CSRF)

For browser apps with cookie sessions:

```ts
import csrf from "csurf"
app.use(csrf({ cookie: { httpOnly: true, sameSite: "lax", secure: true } }))
```

Or use a **double-submit cookie** pattern, or a per-session token in a custom request header.

Rules:
- Cookies should be `SameSite=Lax` (default) or `Strict`.
- Pure-API auth (Bearer token in `Authorization` header, no cookies) is not vulnerable to CSRF - but the server must actually require the header and not also accept a cookie.
- State-changing methods (POST/PUT/PATCH/DELETE) require the CSRF token.
- CORS is **not** a CSRF defense.

### 3.7 Server-side request forgery (SSRF)

#### FAIL
```ts
const r = await fetch(req.body.url)  // user-supplied URL fetched from server
```

#### PASS
```ts
import dns from "dns/promises"
import ipaddr from "ipaddr.js"

async function safeFetch(input: string) {
  const u = new URL(input)
  if (!["http:", "https:"].includes(u.protocol)) throw new Error("bad protocol")

  const addrs = await dns.resolve(u.hostname)
  for (const a of addrs) {
    const ip = ipaddr.parse(a)
    if (ip.range() !== "unicast") throw new Error("private IP")
  }
  return fetch(u, { redirect: "error", signal: AbortSignal.timeout(5000) })
}
```

Block:
- `127.0.0.0/8`, `::1` (loopback)
- `169.254.0.0/16`, `fe80::/10` (link-local - includes cloud metadata `169.254.169.254`)
- `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `fc00::/7` (private)
- `0.0.0.0`, `::`

Disallow redirects (`redirect: "error"`) or re-validate after each redirect. Set a hard timeout. Consider an egress allowlist for production.

### 3.8 File uploads

#### PASS
```ts
import { fileTypeFromBuffer } from "file-type"

const ALLOWED = new Set(["image/png", "image/jpeg", "image/webp"])
const MAX = 5 * 1024 * 1024  // 5MB

async function handleUpload(file: File, ownerId: string) {
  if (file.size > MAX) throw new Error("too large")

  const buf = Buffer.from(await file.arrayBuffer())
  const sniffed = await fileTypeFromBuffer(buf)        // sniff magic bytes
  if (!sniffed || !ALLOWED.has(sniffed.mime)) throw new Error("bad type")

  const id  = crypto.randomUUID()                       // server-generated name
  const key = `u/${ownerId}/${id}.${sniffed.ext}`

  await s3.putObject({
    Bucket: "uploads",
    Key: key,
    Body: buf,
    ContentType: sniffed.mime,
    Metadata: { "uploaded-by": ownerId },
  })
  return id
}
```

Rules:
- Sniff content type from magic bytes. Never trust `Content-Type` header or filename extension.
- Server-generates the filename. Discard the client name (or store as metadata only, never use as a path).
- Store outside the web root, or behind a signed-URL endpoint.
- Re-encode images server-side (`sharp`/ImageMagick) to strip embedded scripts and EXIF.
- Never execute uploaded files. Set `Content-Disposition: attachment` for downloads.
- Scan with ClamAV / VirusTotal for high-risk surfaces (anything user-shareable).
- Cap total upload count and total bytes per user.

### 3.9 Error handling

#### FAIL
```ts
catch (e) { res.status(500).send(e.stack) }              // leaks paths, env, query
catch (e) { res.status(500).json({ error: e }) }         // leaks DB error details
try { ... } catch {}                                      // silent failure
```

#### PASS
```ts
catch (e) {
  log.error({ err: e, requestId }, "internal error")     // server log only
  res.status(500).json({ error: "internal_error", requestId })
}
```

Rules:
- Generic message + correlation ID to the client. Full detail to server logs only.
- Never `try { ... } catch {}` to silence errors. Either handle them meaningfully or let them propagate.
- Don't catch and re-throw without context - wrap with a higher-level cause (`throw new Error("user lookup failed", { cause: e })`).
- Don't return DB error messages, stack traces, or framework debug pages in production.

### 3.10 Logging

- **Log:** who, what, when, from where, with what result, and a request ID.
- **Never log:** passwords, full tokens, full card numbers, SSNs, raw request bodies on auth endpoints, full session cookies, full API keys.
- For tokens, log a stable prefix only (e.g., `tok_abc...`).
- Audit-log security-sensitive actions (login, logout, password change, role change, payment, admin action) to a separate immutable sink if possible.
- Never write logs to the application's own writable directory in production - ship to stdout / journald / a log service.

### 3.11 Security headers (HTML responses)

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
Content-Security-Policy: default-src 'self'; script-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
```

Use `helmet` (Node), `secure_headers` (Rails), Django's `SECURE_*` settings + `django-csp`, etc. Don't hand-roll.

### 3.12 Rate limiting & abuse

- Global: per-IP and per-user request rate.
- Stricter limits on auth, password reset, email send, expensive endpoints, AI-cost endpoints.
- Use a shared store (Redis) so limits work across instances.
- Return `429 Too Many Requests` with `Retry-After`.

### 3.13 Crypto

- Use the platform's audited crypto. Never roll your own primitives.
- Random tokens: `crypto.randomBytes(32).toString("base64url")` (Node), `secrets.token_urlsafe(32)` (Python). Never `Math.random()`.
- Constant-time comparison for tokens: `crypto.timingSafeEqual`. String `===` leaks via timing.
- Symmetric encryption: AEAD (AES-GCM, ChaCha20-Poly1305) - never AES-CBC without HMAC.
- Asymmetric: Ed25519 for signing, X25519 for ECDH where possible. RSA-2048 minimum if RSA is required.

---

## 4. Dependency & supply-chain hygiene

### 4.1 At project init

- **Commit lockfiles:** `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `requirements.txt` (with `pip-compile`), `Pipfile.lock`, `poetry.lock`, `Cargo.lock`, `go.sum`, `Gemfile.lock`.
- **Pin runtime version:** `.nvmrc`, `.python-version`, `.tool-versions`, `engines` in `package.json`.
- **Vet new deps:** maintainer activity, last release date, weekly downloads, open CVEs, install scripts. Prefer well-maintained alternatives over hot-but-new packages.

### 4.2 Continuous

Enable Dependabot or Renovate at repo creation. Run on CI:
- Node: `npm audit --audit-level=high` or `pnpm audit`
- Python: `pip-audit` (preferred) or `safety check`
- Rust: `cargo audit`
- Go: `govulncheck ./...`
- Ruby: `bundler-audit`

Block CI on **high/critical**. Warn on moderate.

### 4.3 Typosquatting & slopsquatting

Before installing any package - especially one suggested by an LLM:

1. Check the name carefully (no typo of a popular package).
2. Verify the package exists on the registry **and** has prior versions.
3. Look at the linked GitHub repo: stars, last commit, open issues, release history.
4. Check weekly downloads. Brand-new package + suspicious name = stop and ask.

LLMs hallucinate package names; attackers register the hallucinations. If you're not sure a package is real, search the registry rather than guessing.

### 4.4 Lock package install sources

- npm: configure a registry, never auto-trust HTTP mirrors.
- Python: use `--require-hashes` for production installs where feasible.
- Avoid `curl ... | bash` install steps for build dependencies.

---

## 5. Hardened project config

For any new project, generate:

### `.gitignore`
See Section 2.2.

### `.editorconfig`
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

### `SECURITY.md`
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

### `THREAT_MODEL.md`
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

---

## 6. Docker hardening

### Dockerfile

#### PASS
```dockerfile
# Pin base image by digest, not just tag
FROM node:20.11-alpine@sha256:abcd1234... AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
RUN npm run build

FROM node:20.11-alpine@sha256:abcd1234...
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
USER app
COPY --from=build --chown=app:app /app/dist         ./dist
COPY --from=build --chown=app:app /app/node_modules ./node_modules
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://127.0.0.1:3000/health || exit 1
CMD ["node", "dist/index.js"]
```

Rules:
- **Pin base images by digest** (`@sha256:...`), not floating tags.
- Use minimal base (`-alpine`, `-slim`, `gcr.io/distroless/*`).
- Multi-stage to drop build deps from the final image.
- Run as **non-root** (`USER app`).
- Don't `COPY . .` before adding `.dockerignore`.
- `.dockerignore` includes `.env`, `.git`, `node_modules`, `*.pem`, `coverage/`, `*.log`.
- No secrets in `ARG` or `ENV` (visible in image history). Use BuildKit secrets: `RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci`.
- Set `HEALTHCHECK`.
- Drop capabilities at runtime: `docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE`.

### docker-compose
- Don't expose DB ports to the host (use `expose:` not `ports:`) unless you need them locally.
- Read secrets from a gitignored `.env` file or use Docker secrets / external secret managers.
- Set `read_only: true` on containers that don't need writable rootfs; mount `tmpfs` for `/tmp`.
- Set `security_opt: ["no-new-privileges:true"]`.

---

## 7. CI/CD hardening (GitHub Actions)

### 7.1 Workflow defaults

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

permissions: {}            # default: no permissions

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read       # grant only what's needed
    steps:
      # Pin actions by full SHA, not floating tag
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11   # v4.1.1
      - uses: actions/setup-node@60edb5dd545a775178f52524783378180af0d1f8 # v4.0.2
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test
      - run: npm audit --audit-level=high
```

### 7.2 Mandatory rules

- **Pin all third-party actions by full SHA.** Tags are mutable - an attacker who compromises a maintainer can move `@v4` to malicious code. Add a `# v4.1.1` comment for readability.
- Set `permissions: {}` at workflow level; expand per-job to least privilege (`contents: read`, `pull-requests: write`, etc.).
- **Never use `pull_request_target` with `actions/checkout` of `github.event.pull_request.head.sha`** - this runs untrusted PR code with repo write permissions and access to secrets. Either don't use `pull_request_target`, or split workflows so the privileged step only consumes pre-validated artifacts.
- Never expand untrusted input directly into a `run:` block - use env-var indirection so the shell doesn't interpret it:
  ```yaml
  env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "$TITLE"
  ```
- Use **OIDC** (`id-token: write` + cloud trust policy) for cloud auth. Do not store long-lived AWS/GCP keys in repo secrets.
- GitHub redacts the **exact** value of `${{ secrets.X }}`. It does **not** redact derived forms (base64-decoded, JSON-extracted, substring). Don't process secrets in `run:` steps that produce logs.
- Add **branch protection** on `main`: require PR review, require status checks, require signed commits if feasible, no force pushes, no deletions, dismiss stale reviews on push.
- Add **CODEOWNERS** for security-sensitive paths (auth, payments, infra, `.github/workflows/`).
- Set `timeout-minutes` on every job. A runaway job can drain spend.

### 7.3 Required CI checks for any non-trivial repo

- Lint (`eslint`/`ruff`/`clippy`/`golangci-lint`)
- Type check (`tsc --noEmit`/`mypy`/`pyright`)
- Test
- Dependency audit (see Section 4.2)
- Secret scan (`gitleaks` or `trufflehog`) on PR + on push
- SAST: `semgrep ci` with `p/owasp-top-ten` and `p/security-audit`
- For Docker: `trivy image` or `grype` on the built image
- For IaC: `tfsec` / `checkov` on Terraform

---

## 8. Tests & security checks

Add tests that fail the build when an authorization or input-validation rule regresses. A passing build should mean "the security invariants still hold," not just "the unit tests pass."

### 8.1 Required test cases for any auth-bearing app

- Anonymous request to a protected route -> 401.
- Authenticated request to **another user's** resource -> 404 (or 403).
- Expired/tampered token -> 401.
- Injection-style input (`' OR 1=1--`, `{"$ne": null}`) is rejected at validation.
- Oversized payload (e.g., 10MB on a JSON endpoint) is rejected before reaching the handler.
- Login rate-limit: 11th attempt within window -> 429.
- CSRF (cookie-session apps): state-changing request without token -> rejected.
- File upload: wrong MIME, oversized, double-extension (`evil.php.png`), zero-byte - all rejected.
- Password reset token: single-use, expires, scoped to user.

### 8.2 Static analysis (run locally + in CI)

- **Semgrep** with `p/owasp-top-ten` and `p/security-audit` - multi-language coverage.
- JS/TS: ESLint with `eslint-plugin-security`, `eslint-plugin-no-secrets`.
- Python: `bandit -r .`, `ruff` with the `S` (bandit) ruleset.
- Go: `gosec ./...`, `staticcheck ./...`.
- Rust: `cargo clippy -- -D warnings`, `cargo audit`, `cargo deny`.
- Java: `spotbugs` + `find-sec-bugs`.
- Ruby: `brakeman`.
- PHP: `phpstan` + `psalm` with security plugins.

### 8.3 Secret scanning

- Local pre-commit hook: `gitleaks protect --staged --redact -v`.
- CI: `gitleaks detect --redact -v` on every push and PR.
- GitHub native: enable **Push Protection** + **Secret Scanning** in repo settings.
- For historical scrubs: `trufflehog git file://./ --since-commit HEAD~50`.

### 8.4 Dependency scanning

See Section 4.2. Wire into CI as a required, blocking check at high/critical severity.

---

## 9. New project flow (private GitHub repo)

When the user asks you to create a new project, follow this exact order:

1. **Create local directory & initial structure** - minimal code, README skeleton.
2. **Write `.gitignore` FIRST** - before any `git add`. Include `.env`, secrets, build artifacts.
3. **Write `.env.example`** with empty/placeholder values. Place real `.env` in the gitignored location only.
4. **Write `SECURITY.md`** and (for non-trivial projects) `THREAT_MODEL.md`.
5. **`git init`** and confirm `.gitignore` is staged first. Run `git status` and verify it does NOT show `.env` or any secrets.
6. **Run a secret scan** before the first commit:
   ```bash
   gitleaks detect --no-git --source . --redact -v
   ```
7. **First commit** - small: scaffolding + security docs only.
8. **Create the remote as PRIVATE**:
   ```bash
   gh repo create <name> --private --source=. --remote=origin --push
   ```
   Never `--public` unless the user explicitly asked for an open-source release **and** a sanitization pass has run.
9. **Apply branch protection**:
   ```bash
   gh api -X PUT repos/:owner/<name>/branches/main/protection \
     -f required_pull_request_reviews.required_approving_review_count=1 \
     -F required_status_checks.strict=true \
     -F required_status_checks.contexts[]="ci" \
     -F enforce_admins=true \
     -F restrictions=null
   ```
10. **Enable security features**:
    ```bash
    gh api -X PATCH repos/:owner/<name> \
      -F security_and_analysis.secret_scanning.status=enabled \
      -F security_and_analysis.secret_scanning_push_protection.status=enabled \
      -F security_and_analysis.dependabot_security_updates.status=enabled
    ```
11. **Add `.github/dependabot.yml`** (see Section 10), `.github/workflows/ci.yml` (see Section 7), `.github/CODEOWNERS`.
12. **Verify**: `gh repo view --web` and confirm the repo is private, has the docs, and CI ran clean on the first commit.

If `gh` is not authenticated, tell the user to run `! gh auth login` and pause.

---

## 10. Recommended files for new projects

### `.github/dependabot.yml`
```yaml
version: 2
updates:
  - package-ecosystem: npm                # adapt: pip, cargo, gomod, bundler, ...
    directory: "/"
    schedule: { interval: weekly }
    open-pull-requests-limit: 10
    groups:
      patch-and-minor:
        update-types: [patch, minor]
  - package-ecosystem: github-actions
    directory: "/"
    schedule: { interval: weekly }
  - package-ecosystem: docker
    directory: "/"
    schedule: { interval: weekly }
```

### `.github/CODEOWNERS`
```
*                       @owner
/auth/                  @owner @security
/payments/              @owner @security
/.github/workflows/     @owner @security
/infra/                 @owner @security
/Dockerfile             @owner @security
```

### `.pre-commit-config.yaml`
```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.4
    hooks: [{ id: gitleaks }]
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: detect-private-key
      - id: check-added-large-files
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-merge-conflict
```

### `.dockerignore`
```
.git
.gitignore
.env
.env.*
*.pem
*.key
node_modules
dist
build
coverage
.vscode
.idea
*.log
README.md
```

---

## 11. Commit & push safety

Before every commit:

1. **`git status`** - verify no `.env`, no `*.pem`, no `secrets.*`, no surprise files.
2. **`git diff --cached`** - eyeball every hunk. Look for tokens, URLs with creds, hardcoded keys, debug `console.log`s with PII or session data.
3. **Run the secret scan** (see Section 8.3).
4. **Run lint + type-check + tests** for the changed scope.
5. **Write a commit message** explaining the *why* (the *what* is in the diff).
6. **Commit.**
7. **Stage specific files** (`git add path/to/file`), not `git add -A` / `git add .` - those sweep in stray secrets and editor artifacts.

Forbidden unless the user explicitly asks:
- `--no-verify` (skips hooks, defeats secret scanning + tests).
- `--no-gpg-sign` if signing is configured.
- `git push --force` / `--force-with-lease` to `main`/`master` or any protected branch.
- `git filter-repo` / history rewrite without first verifying with the user.
- Committing any file matching `*.env*`, `*.pem`, `*.p12`, `*.key`, `*credentials*`, `*service-account*`, `id_rsa*`, `*.kdbx`.

After commit, for non-trivial work, run `gh pr create --draft` and let CI gate the merge. Don't push directly to `main` if branch protection allows it but the team uses PR review.

---

## 12. Final summary template

After finishing any non-trivial task, end with:

```
Built:        <one line>
Stack:        <lang/framework/runtime>
Trust model:  <browser -> server, server -> DB, ...>
Security controls added:
  - <e.g., argon2id password hashing on /register>
  - <e.g., zod validation on all POST handlers>
  - <e.g., httpOnly+Secure+SameSite=Lax session cookies>
  - <e.g., CSP + HSTS + nosniff via helmet>
  - <e.g., gitleaks pre-commit hook>
  - <e.g., dependabot weekly schedule>
  - <e.g., branch protection on main, signed commits required>
Checks run:
  - lint:         pass
  - typecheck:    pass
  - tests:        12/12 pass (including 4 authz/IDOR cases)
  - npm audit:    0 high/critical
  - gitleaks:     clean
  - semgrep:      clean
Assumptions:
  - <e.g., session secret will be provisioned via env in production>
  - <e.g., Redis is available for rate-limit store>
Open follow-ups:
  - <e.g., add WebAuthn 2FA - out of scope for this PR>
  - <e.g., wire Sentry for production error reporting>
```

If any of the checks didn't run (e.g., no test framework yet), say so explicitly. Don't claim "tests pass" when the truth is "no tests exist."

---

## 13. When to pause and ask

Stop and confirm with the user before:

- Force-pushing, history-rewriting, deleting branches.
- Making a repo public.
- Disabling a security control that already exists (CSRF middleware, CSP, rate-limit, validation, type-narrowing).
- Opening a port to `0.0.0.0` from a service that was previously bound to `127.0.0.1`.
- Adding a dependency you can't verify (low downloads, no maintainer, recent name change).
- Pasting potentially-sensitive content (configs, logs, traces, secrets, customer data) to a third-party tool (pastebin, gists, diagram services, online formatters, public LLM playgrounds).
- Skipping a security check the user previously enabled.
- Using `--no-verify`, `--no-gpg-sign`, `--force`, `--allow-empty-message`, etc.

If you must proceed without an answer (e.g., agent-mode), pick the safest reasonable default and **state the assumption in your summary**.

---

## 14. Stack quick-reference

### Node / Express / Fastify
- `helmet`, `express-rate-limit`, `cors` with explicit origin allowlist, `csurf` (cookie sessions), `zod` validation.
- Don't trust `X-Forwarded-For` unless behind a known proxy: `app.set('trust proxy', N)` with the right hop count.
- `argon2` for passwords; `jsonwebtoken` only for short-lived access tokens.

### Next.js
- Server Actions: validate inputs, check auth, never accept arbitrary `redirect()` targets from input.
- API routes: same as Express. Prefer `next-auth` / Auth.js over hand-rolled.
- Set headers via `next.config.js` `headers()` or middleware.
- Beware of `revalidatePath`/`revalidateTag` triggered by unauthenticated requests.

### Python / FastAPI
- Pydantic models for request bodies (`extra="forbid"`). `Depends(get_current_user)` for auth. `slowapi` for rate-limiting.
- `passlib[argon2]` for passwords. SQLAlchemy with parameter binding (`text()` only with `:bindparam`s).

### Python / Django
- Keep `DEBUG = False` in production. Set `ALLOWED_HOSTS`. Enable all `SECURE_*` settings. CSRF + sessions are on by default - don't disable.
- `django-axes` for login rate-limiting; `django-csp` for CSP.
- Use the ORM; for raw SQL, parameterize with `cursor.execute(sql, [params])`.

### Go
- `net/http` with `http.TimeoutHandler` and `Server.ReadHeaderTimeout`/`ReadTimeout`/`WriteTimeout` set.
- `database/sql` with placeholders or `sqlc`/`sqlx`. `golang.org/x/crypto/bcrypt` or `argon2` for passwords.
- `gosec ./...` + `govulncheck ./...` in CI.

### Rust
- `axum` / `actix-web` with `tower-http` for rate-limiting, compression, CORS, request-id.
- `argon2` crate for passwords. `sqlx` with compile-time-checked queries (`query!` / `query_as!`).
- `cargo audit` + `cargo deny` in CI.

### Java / Spring Boot
- Spring Security defaults are good. Don't disable CSRF for browser apps.
- Use `@Validated` + Bean Validation. Parameterized JPQL or Spring Data repositories.
- `BCryptPasswordEncoder` (cost >= 12) or `Argon2PasswordEncoder`.

### C# / .NET
- ASP.NET Core: `[Authorize]` and policy-based authorization. Antiforgery tokens for forms. Data Protection API for cookies.
- EF Core with parameter binding; never `FromSqlRaw` with interpolation.
- `Microsoft.AspNetCore.Identity` for auth; `PasswordHasher<TUser>` uses PBKDF2 - fine, but consider Argon2 via a third-party hasher for stricter requirements.

### Ruby on Rails
- `bcrypt` via `has_secure_password`. Strong parameters (`params.permit(...)`).
- CSRF and session cookies are secure by default - don't disable.
- `brakeman` in CI; `bundler-audit` for deps.

---

## Closing

If at any point you find yourself about to commit, push, deploy, or expose code that hasn't gone through Section 11, stop and run Section 11 first.

If at any point you find yourself about to weaken a control to make a build pass, stop and surface the question to the user instead.

The job is not "make it work." The job is "make it work without becoming a liability."
