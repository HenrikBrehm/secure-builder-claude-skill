# Re-running the evaluation

The full evaluation lives in [`../EVALUATION.md`](../EVALUATION.md). It is split into seven tests (**T1–T7**). T1 is fully automated; T2–T7 are reviewer-graded.

## T1 — automated static checks

Five tools: `gitleaks` (secrets), `markdownlint-cli2` (Markdown lint), `lychee` (link check), `semgrep` (SAST on code blocks), `shellcheck` (helper-script lint).

The repo's own [`.github/workflows/self-check.yml`](../../.github/workflows/self-check.yml) runs all five on every push to `main` and every pull request, with all third-party Actions pinned by full commit SHA. The workflow is the canonical T1 ledger — read the latest run there first.

### Run T1 locally (subset)

The three T1 tools that are easy to run on a developer laptop:

```bash
# 1. gitleaks — uses .gitleaks.toml automatically
gitleaks detect --no-git --source . --redact -v

# 2. markdownlint — uses .markdownlint-cli2.jsonc automatically
npx -y markdownlint-cli2

# 3. lychee — pass --config explicitly
lychee --no-progress --config lychee.toml .
```

Expected:

| Tool             | Expected on a clean working tree                                        |
| ---------------- | ----------------------------------------------------------------------- |
| `gitleaks`       | `INF no leaks found`                                                    |
| `markdownlint`   | `Summary: 0 error(s)` *(see EVALUATION.md § 3.2 — current 5-finding state explained)* |
| `lychee`         | `✅ … OK`, `🚫 0 Errors`                                                  |

### Tool versions used in the published evaluation

```text
gitleaks            8.30.1
markdownlint-cli2   0.22.1   (markdownlint-rules 0.40.0)
lychee              0.24.2
gh CLI              2.92.0
```

`semgrep` and `shellcheck` are best run via the CI workflow rather than installed locally — both have nontrivial dependency graphs (semgrep: Python + ~50 transitive deps, shellcheck: Haskell runtime).

## T2–T7 — reviewer-graded re-evaluation

These cannot be re-run by a script — they require a human checking SKILL.md content against external standards. A maintainer should re-grade them:

- on a regular cadence (annual, or after any major content change to `SKILL.md` / `reference/`); or
- whenever the skill is bumped to a new minor/major version.

### Procedure for a reviewer

1. Read [`../EVALUATION.md`](../EVALUATION.md) start-to-finish, focusing on the **Findings** subsections of T3, T4, T7.
2. For each item, check whether the underlying claim still holds. Concrete checks:
   - **T3 (correctness)** — re-read every `## FAIL` / `## PASS` block in `reference/02-secrets.md` and `reference/03-patterns/*.md`; check the named library's current API.
   - **T4 (currency)** — `npm view <pkg> deprecated time.modified`, `pip index versions <pkg>`, `gh release list --repo <owner>/<repo> --limit 1` for tools.
   - **T5 (self-application)** — diff the repo's actual state against the templates in `reference/{05,07,09,10}.md`; confirm `self-check.yml` is green.
   - **T7 (gaps)** — has any new attack class become Top-10 since the last review? Has the v1.2/+1 release closed any of the high-priority gaps listed in § 9.2?
3. Update the **Scoreboard** in `EVALUATION.md` § 2 with new grades and a fresh "Reviewed on" date. Append a new row to **Appendix A** (delta vs. previous version).
4. Open a follow-up PR for each finding that turned actionable, and link it from the **Prioritized fix list** in § 10.

There is intentionally **no** `tests/run-all.sh` script: T2–T7 don't lend themselves to automation without losing the very signal that makes a reviewer-graded test useful. T1 is automated end-to-end via `self-check.yml`.
