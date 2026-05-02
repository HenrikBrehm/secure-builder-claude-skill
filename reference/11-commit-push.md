# 11. Commit & push safety

Before every commit:

1. **`git status`** — verify no `.env`, no `*.pem`, no `secrets.*`, no surprise files.
2. **`git diff --cached`** — eyeball every hunk. Look for tokens, URLs with creds, hardcoded keys, debug `console.log`s with PII or session data.
3. **Run the secret scan** (see `reference/08-tests.md` § 8.3).
4. **Run lint + type-check + tests** for the changed scope.
5. **Stage specific files** (`git add path/to/file`), not `git add -A` / `git add .` — those sweep in stray secrets and editor artifacts.
6. **Write a commit message** explaining the *why* (the *what* is in the diff).
7. **Commit.**

Forbidden unless the user explicitly asks:

- `--no-verify` (skips hooks, defeats secret scanning + tests).
- `--no-gpg-sign` if signing is configured.
- `git push --force` / `--force-with-lease` to `main` / `master` or any protected branch.
- `git filter-repo` / history rewrite without first verifying with the user.
- Committing any file matching `*.env*`, `*.pem`, `*.p12`, `*.key`, `*credentials*`, `*service-account*`, `id_rsa*`, `*.kdbx`.

After commit, for non-trivial work, run `gh pr create --draft` and let CI gate the merge. Don't push directly to `main` if branch protection allows it but the team uses PR review.
