# Contributing to secure-builder

Thanks for considering a contribution. This skill is intentionally tight: every recommendation has to earn its place. The bar is high but the process is light.

## Before you open a PR

Ask yourself:

1. **What real exploit class does this prevent or detect?** "It's a best practice" isn't an answer.
2. **Can I show a FAIL/PASS pair?** The skill follows a strict format — broken example, then the secure version, both runnable.
3. **Does it conflict with anything already in `SKILL.md` or `reference/`?** If so, which loses, and why?
4. **Is it stack-specific or universal?** Stack-specific patterns go in `reference/14-stacks/<stack>.md`.

If you can't answer all four, please open an issue first to discuss.

## Out of scope

- Reformatting passes, prose polishing, or "make it more concise" rewrites without a content delta.
- "Add my favorite library X" — only if it's a defensible *default*, not a preference.
- Generic CI templates that don't address a security control.
- Anything that adds friction without preventing a real attack class.

## Style

- Markdown, no HTML beyond what `.markdownlint-cli2.jsonc` allows (`<br>`, `<details>`, `<summary>`, `<kbd>`).
- Fenced code blocks with language tags (` ```ts `, ` ```python `).
- Use the existing `### FAIL` / `### PASS` block convention inside reference files.
- Section numbering is load-bearing — `SKILL.md`'s reference map points at numbered files (`reference/01-planning.md`, …, `reference/14-stacks/`). If you add a section, renumber consistently and update the reference map.
- No emoji, no marketing language, no "easy" / "simply" / "just". The skill addresses senior engineers who already know the basics.
- Lines wrap naturally; no enforced column limit (markdownlint MD013 is off).

## How to contribute

### 1. For typo / formatting / dead-link fixes

Open a PR directly. Title: `fix: <short description>`.

### 2. For new patterns or revisions

Open an issue first with:

- The exploit class.
- A 5-line "what's wrong with the current advice" (if any).
- The replacement, in skeleton form.

If maintainers green-light it, open a PR. Title: `feat: <reference path>: <short description>` (e.g., `feat: reference/03-patterns/ssrf.md: cover DNS rebinding for safeFetch`).

### 3. For helper script changes

Edit `scripts/*.sh` directly if it's a bug fix; open an issue first for new scripts. The bar is the same as for SKILL.md content: the script must address a concrete attack class or security workflow, and it must pass `shellcheck` cleanly.

### 4. For security issues in SKILL.md content

**Do not open a public PR or issue.** See [SECURITY.md](./SECURITY.md) for private reporting.

## Helper scripts (`scripts/`)

`scripts/install-pre-commit.sh` and `scripts/bootstrap-private-repo.sh` are the only executable code in the repo. New scripts must:

- Start with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Pass `shellcheck` cleanly (CI enforces this — see `.github/workflows/self-check.yml`).
- Be idempotent: rerunning them on a repo already in the desired state should be a no-op or a friendly skip.
- **Confirm before destructive actions** (writing files, calling `gh repo create`, applying branch protection). A `--yes` (or `-y`) flag may skip prompts for CI/scripted use.
- Never make network calls without explicit user consent (interactive confirm or `--yes`).
- Document inputs, outputs, and required tools in the file's leading comment block.

## PR checklist

- [ ] The change is in `SKILL.md`, `reference/`, `scripts/`, or repo metadata only.
- [ ] Section numbering and SKILL.md reference-map entries are intact.
- [ ] Code examples actually run / would compile (test them locally).
- [ ] `reference/14-stacks/<stack>.md` updated if you added a stack-specific note.
- [ ] `CHANGELOG.md` updated under `## [Unreleased]`.
- [ ] No personal data, internal URLs, real credentials, or org-specific paths.
- [ ] If you touched `scripts/`, the script passes `shellcheck`.
- [ ] CI (gitleaks, semgrep, markdownlint, lychee, shellcheck) passes locally where you can run it.

## Review

One maintainer review minimum. Reviews focus on:

1. Does the recommendation actually prevent the named attack class?
2. Is there a simpler / equally-secure alternative that's been overlooked?
3. Does the FAIL example faithfully represent code people *actually* write?
4. Will the PASS example still be considered safe in 12 months?

## Code of conduct

Be precise, be skeptical of your own claims, cite sources for any non-obvious recommendation. Don't be a jerk about it.

## License

By contributing you agree that your contribution will be released under the [MIT License](./LICENSE).
