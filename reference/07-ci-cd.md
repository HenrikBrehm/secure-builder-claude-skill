# 7. CI/CD hardening (GitHub Actions)

## 7.1 Workflow defaults

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
      - run: npm ci --ignore-scripts
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test
      - run: npm audit --audit-level=high
```

## 7.2 Mandatory rules

- **Pin all third-party actions by full SHA.** Tags are mutable — an attacker who compromises a maintainer can move `@v4` to malicious code. Add a `# v4.1.1` comment for readability.
- Set `permissions: {}` at workflow level; expand per-job to least privilege (`contents: read`, `pull-requests: write`, etc.).
- **Never use `pull_request_target` with `actions/checkout` of `github.event.pull_request.head.sha`** — this runs untrusted PR code with repo write permissions and access to secrets. Either don't use `pull_request_target`, or split workflows so the privileged step only consumes pre-validated artifacts.
- Never expand untrusted input directly into a `run:` block — use env-var indirection so the shell doesn't interpret it:
  ```yaml
  env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "$TITLE"
  ```
- Use **OIDC** (`id-token: write` + cloud trust policy) for cloud auth. Do not store long-lived AWS/GCP keys in repo secrets.
- GitHub redacts the **exact** value of `${{ secrets.X }}`. It does **not** redact derived forms (base64-decoded, JSON-extracted, substring). Don't process secrets in `run:` steps that produce logs.
- Add **branch protection / Rulesets** on `main`: require PR review, require status checks, require signed commits if feasible, no force pushes, no deletions, dismiss stale reviews on push. See § 7.4 for the modern API call.
- Add **CODEOWNERS** for security-sensitive paths (auth, payments, infra, `.github/workflows/`).
- Set `timeout-minutes` on every job. A runaway job can drain spend.

## 7.3 Required CI checks for any non-trivial repo

- Lint (`eslint` / `ruff` / `clippy` / `golangci-lint`)
- Type check (`tsc --noEmit` / `mypy` / `pyright`)
- Test
- Dependency audit (see `reference/04-supply-chain.md` § 4.3)
- Secret scan (`gitleaks` or `trufflehog`) on PR + on push
- SAST: `semgrep ci` with `p/owasp-top-ten` and `p/security-audit`
- For Docker: `trivy image` or `grype` on the built image
- For IaC: `tfsec` / `checkov` on Terraform

## 7.4 Branch protection via Rulesets (modern API)

The legacy `repos/:owner/:repo/branches/:branch/protection` endpoint requires GHE/Pro for private repos. For public + private repos on free plans, use **Rulesets** (organization or repo scope):

```bash
gh api -X POST "repos/:owner/:repo/rulesets" \
  -H "Accept: application/vnd.github+json" \
  --input - <<'JSON'
{
  "name": "main protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["refs/heads/main"], "exclude": [] }
  },
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
    },
    { "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": [{ "context": "ci" }]
      }
    }
  ],
  "bypass_actors": []
}
JSON
```

Then enable the per-repo security toggles:

```bash
gh api -X PATCH "repos/:owner/:repo" \
  -F security_and_analysis.secret_scanning.status=enabled \
  -F security_and_analysis.secret_scanning_push_protection.status=enabled \
  -F security_and_analysis.dependabot_security_updates.status=enabled
```
