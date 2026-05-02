#!/usr/bin/env bash
#
# bootstrap-private-repo.sh
#
# Deterministic execution of reference/09-new-project-flow.md:
#   1. Write .gitignore (secrets-first), .env.example, SECURITY.md.
#   2. git init + secret-scan the working tree before the first commit.
#   3. Create the GitHub repo as private, push.
#   4. Apply branch protection via the modern Rulesets API.
#   5. Enable Secret Scanning + Push Protection + Dependabot security updates.
#
# Usage:
#   ./bootstrap-private-repo.sh <repo-name>            # interactive
#   ./bootstrap-private-repo.sh <repo-name> --yes      # non-interactive
#
# Requires: bash 4+, git, gh (authenticated, with `repo` scope), gitleaks.

set -euo pipefail

NAME=""
YES=0

for arg in "$@"; do
  case "$arg" in
    --yes|-y)  YES=1 ;;
    --help|-h)
      sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*)
      echo "unknown flag: $arg" >&2
      exit 2
      ;;
    *)
      if [ -z "$NAME" ]; then
        NAME="$arg"
      else
        echo "unexpected positional arg: $arg" >&2
        exit 2
      fi
      ;;
  esac
done

if [ -z "$NAME" ]; then
  echo "usage: $0 <repo-name> [--yes]" >&2
  exit 2
fi

confirm() {
  if [ "$YES" -eq 1 ]; then return 0; fi
  read -r -p "$1 [y/N] " ans
  case "$ans" in [yY]|[yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required tool not found on PATH: $1" >&2
    exit 1
  fi
}

require git
require gh
require gitleaks

if ! gh auth status >/dev/null 2>&1; then
  echo "error: 'gh' is not authenticated. Run: gh auth login" >&2
  exit 1
fi

OWNER=$(gh api user --jq .login)
echo "Target: ${OWNER}/${NAME} (private)"
confirm "Proceed with bootstrap?" || exit 1

# 1. .gitignore FIRST — before any git add.
if [ ! -f .gitignore ]; then
  cat > .gitignore <<'GITIGNORE_EOF'
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
GITIGNORE_EOF
  echo "wrote .gitignore"
fi

# 2. .env.example — placeholder values only.
if [ ! -f .env.example ]; then
  cat > .env.example <<'ENV_EOF'
# Copy to .env (gitignored) and fill in real values.
DATABASE_URL=
JWT_SECRET=          # openssl rand -base64 48
SESSION_SECRET=      # openssl rand -base64 48
ENV_EOF
  echo "wrote .env.example"
fi

# 3. SECURITY.md
if [ ! -f SECURITY.md ]; then
  cat > SECURITY.md <<'SEC_EOF'
# Security Policy

## Reporting a Vulnerability

Please report security issues privately via this repo's
**Security Advisory** tab ("Report a vulnerability").

Do not open public issues for security problems.
We aim to acknowledge within 2 business days.
SEC_EOF
  echo "wrote SECURITY.md"
fi

# 4. git init (idempotent) and secret-scan BEFORE the first commit.
if [ ! -d .git ]; then
  git init -q -b main
  echo "initialized git repository"
fi

echo "running gitleaks on the working tree..."
if ! gitleaks detect --no-git --source . --redact -v; then
  echo "gitleaks flagged a secret. Resolve before continuing." >&2
  exit 1
fi

# 5. First commit (only if there's something to commit).
git add .gitignore .env.example SECURITY.md
if ! git diff --cached --quiet; then
  git commit -q -m "chore: scaffold private repo with secrets policy"
  echo "created initial commit"
fi

# 6. Create remote as PRIVATE.
if gh repo view "${OWNER}/${NAME}" >/dev/null 2>&1; then
  echo "remote ${OWNER}/${NAME} already exists; skipping creation"
else
  gh repo create "${OWNER}/${NAME}" --private --source=. --remote=origin --push
fi

# 7. Branch protection via Rulesets (works on free private repos).
echo "applying branch protection ruleset to main..."
RULESET=$(cat <<'JSON'
{
  "name": "main protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/heads/main"], "exclude": [] } },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "required_signatures" },
    { "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": true,
        "required_review_thread_resolution": true
      }
    }
  ],
  "bypass_actors": []
}
JSON
)

# Don't fail the whole script if a ruleset already exists.
echo "$RULESET" | gh api -X POST "repos/${OWNER}/${NAME}/rulesets" \
  -H "Accept: application/vnd.github+json" --input - >/dev/null \
  || echo "ruleset POST returned non-zero (may already exist) — continuing"

# 8. Enable Secret Scanning + Push Protection + Dependabot security updates.
gh api -X PATCH "repos/${OWNER}/${NAME}" \
  -F security_and_analysis.secret_scanning.status=enabled \
  -F security_and_analysis.secret_scanning_push_protection.status=enabled \
  -F security_and_analysis.dependabot_security_updates.status=enabled \
  >/dev/null \
  || echo "warning: could not enable all security toggles (private repos on free plan may not support some)" >&2

echo ""
echo "Done. View at: https://github.com/${OWNER}/${NAME}"
echo "Next: write .github/workflows/ci.yml (see reference/07-ci-cd.md)."
