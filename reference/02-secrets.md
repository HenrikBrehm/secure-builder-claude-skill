# 2. Secrets protection

Treat every secret as if it will be public the moment you stop watching.

## 2.1 Never put secrets in source

### FAIL
```ts
const apiKey = "sk-proj-abc123"
const dbUrl = "postgres://user:hunter2@db.internal/app"
const jwtSecret = "secret"
```

### PASS
```ts
const apiKey = process.env.OPENAI_API_KEY
const dbUrl = process.env.DATABASE_URL
const jwtSecret = process.env.JWT_SECRET

if (!apiKey || !dbUrl || !jwtSecret) {
  throw new Error("Missing required env: OPENAI_API_KEY, DATABASE_URL, JWT_SECRET")
}
```

## 2.2 Always create both `.gitignore` and `.env.example` BEFORE the first commit

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

## 2.3 Before EVERY commit

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

## 2.4 If a secret reaches a remote

1. **Rotate the secret immediately at the provider.** Do not wait to clean history first — the leak window is open. Tell the user exactly which key to rotate and where (provider dashboard URL if known).
2. Then offer to rewrite history with `git filter-repo` (preferred) or BFG.
3. Force-push the cleaned history (one of the few cases where force-push is justified — confirm with user first).
4. Never assume history rewrite is enough. Treat the credential as compromised forever.

## 2.5 Never echo secrets

- Do not `console.log` env vars in tutorials/examples.
- Do not include secret values in error messages.
- Do not paste `.env` contents into chat or tool output, even when debugging.
- Mask in logs: `log.info("DB connected to", dbUrl.replace(/:[^:@]+@/, ":***@"))`.
- For tokens, log only a stable prefix: `tok_abc...` (first 6-8 chars) for traceability.
