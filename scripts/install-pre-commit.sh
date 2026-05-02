#!/usr/bin/env bash
#
# install-pre-commit.sh
#
# Installs a gitleaks + detect-private-key pre-commit hook into the
# CURRENT git repository. Idempotent. Detects an existing hook and
# refuses to overwrite without --force.
#
# Usage:
#   ./install-pre-commit.sh            # interactive
#   ./install-pre-commit.sh --yes      # non-interactive (CI / scripted)
#   ./install-pre-commit.sh --force    # overwrite existing hook
#
# Requires: bash 4+, git, gitleaks (or curl + tar if --install-gitleaks).

set -euo pipefail

YES=0
FORCE=0
INSTALL_GITLEAKS=0

for arg in "$@"; do
  case "$arg" in
    --yes|-y)            YES=1 ;;
    --force|-f)          FORCE=1 ;;
    --install-gitleaks)  INSTALL_GITLEAKS=1 ;;
    --help|-h)
      sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown arg: $arg" >&2
      exit 2
      ;;
  esac
done

confirm() {
  if [ "$YES" -eq 1 ]; then return 0; fi
  read -r -p "$1 [y/N] " ans
  case "$ans" in [yY]|[yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}

# Sanity: in a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "error: not inside a git repository" >&2
  exit 1
fi
GIT_DIR=$(git rev-parse --git-dir)
HOOK="$GIT_DIR/hooks/pre-commit"

# Optional: install gitleaks if missing
if ! command -v gitleaks >/dev/null 2>&1; then
  if [ "$INSTALL_GITLEAKS" -eq 1 ]; then
    echo "installing gitleaks via Homebrew or releases tarball..."
    if command -v brew >/dev/null 2>&1; then
      brew install gitleaks
    else
      echo "no Homebrew detected; please install gitleaks from" \
           "https://github.com/gitleaks/gitleaks/releases and rerun." >&2
      exit 1
    fi
  else
    echo "warning: gitleaks not on PATH. Install from" \
         "https://github.com/gitleaks/gitleaks or rerun with --install-gitleaks." >&2
  fi
fi

# Refuse to clobber an existing hook unless --force
if [ -f "$HOOK" ] && [ "$FORCE" -ne 1 ]; then
  if grep -q 'INSTALLED-BY-SECURE-BUILDER' "$HOOK" 2>/dev/null; then
    echo "pre-commit hook already managed by secure-builder; nothing to do."
    exit 0
  fi
  echo "error: $HOOK already exists." >&2
  echo "       rerun with --force to overwrite, or chain manually." >&2
  exit 1
fi

if ! confirm "Install pre-commit hook at $HOOK?"; then
  echo "aborted by user."
  exit 1
fi

mkdir -p "$(dirname "$HOOK")"
cat > "$HOOK" <<'HOOK_EOF'
#!/usr/bin/env bash
# INSTALLED-BY-SECURE-BUILDER
# Block commits that contain secrets or private keys.

set -euo pipefail

# 1. gitleaks on the staged diff (preferred).
if command -v gitleaks >/dev/null 2>&1; then
  if ! gitleaks protect --staged --redact -v; then
    echo "" >&2
    echo "pre-commit: gitleaks flagged a potential secret. Resolve before committing." >&2
    exit 1
  fi
fi

# 2. Fallback grep — catches a few common patterns even if gitleaks is missing.
if git diff --cached -U0 --no-color | \
   grep -E '(-----BEGIN [A-Z ]*PRIVATE KEY-----|api[_-]?key[[:space:]]*[:=][[:space:]]*"[^"]{16,}|aws_secret_access_key)' \
        >/dev/null 2>&1; then
  echo "pre-commit: staged diff matched a secret pattern. Move it to .env and re-stage." >&2
  exit 1
fi

# 3. Block obviously sensitive filenames.
BLOCKED=$(git diff --cached --name-only --diff-filter=A | \
          grep -E '(\.env($|\.[^/]+$)|\.pem$|\.p12$|\.key$|credentials\.json$|service-account.*\.json$|id_rsa)' || true)
if [ -n "$BLOCKED" ]; then
  echo "pre-commit: refusing to commit files that look like secrets:" >&2
  echo "$BLOCKED" | sed 's/^/  - /' >&2
  echo "Add them to .gitignore and re-stage if this is a false positive." >&2
  exit 1
fi

exit 0
HOOK_EOF
chmod +x "$HOOK"

echo "installed pre-commit hook at $HOOK"
echo "to test:  git commit --allow-empty -m 'pre-commit smoke test'"
