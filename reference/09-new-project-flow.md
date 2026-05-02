# 9. New project flow (private GitHub repo)

When the user asks you to create a new project, follow this exact order:

1. **Create local directory & initial structure** — minimal code, README skeleton.
2. **Write `.gitignore` FIRST** — before any `git add`. Include `.env`, secrets, build artifacts.
3. **Write `.env.example`** with empty/placeholder values. Place real `.env` in the gitignored location only.
4. **Write `SECURITY.md`** and (for non-trivial projects) `THREAT_MODEL.md`.
5. **`git init`** and confirm `.gitignore` is staged first. Run `git status` and verify it does NOT show `.env` or any secrets.
6. **Run a secret scan** before the first commit:
   ```bash
   gitleaks detect --no-git --source . --redact -v
   ```
7. **First commit** — small: scaffolding + security docs only.
8. **Create the remote as PRIVATE**:
   ```bash
   gh repo create <name> --private --source=. --remote=origin --push
   ```
   Never `--public` unless the user explicitly asked for an open-source release **and** a sanitization pass has run.
9. **Apply branch protection via Rulesets** (works on free private repos; legacy endpoint requires GHE/Pro). Full call in `reference/07-ci-cd.md` § 7.4.
10. **Enable security features**:
    ```bash
    gh api -X PATCH "repos/:owner/<name>" \
      -F security_and_analysis.secret_scanning.status=enabled \
      -F security_and_analysis.secret_scanning_push_protection.status=enabled \
      -F security_and_analysis.dependabot_security_updates.status=enabled
    ```
11. **Add `.github/dependabot.yml`** (see `reference/10-recommended-files.md`), `.github/workflows/ci.yml` (see `reference/07-ci-cd.md`), `.github/CODEOWNERS`.
12. **Verify**: `gh repo view --web` and confirm the repo is private, has the docs, and CI ran clean on the first commit.

If `gh` is not authenticated, tell the user to run `! gh auth login` and pause.

> Steps 1–10 are also available as a single deterministic script: `scripts/bootstrap-private-repo.sh`.
