# Contributing to secure-builder

Thanks for considering a contribution! This skill is intentionally tight: every recommendation has to earn its place. The bar is high but the process is light.

## Before you open a PR

Ask yourself:

1. **What real exploit class does this prevent or detect?** "It's a best practice" isn't an answer.
2. **Can I show a FAIL/PASS pair?** The skill follows a strict format — broken example, then the secure version, both runnable.
3. **Does it conflict with anything already in `SKILL.md`?** If so, which loses, and why?
4. **Is it stack-specific or universal?** Stack-specific patterns go in Section 14.

If you can't answer all four, please open an issue first to discuss.

## Out of scope

- Reformatting passes, prose polishing, or "make it more concise" rewrites without a content delta. The skill is pragmatic, not polished.
- "Add my favorite library X" — only if it's a defensible *default*, not a preference.
- Generic CI templates that don't address a security control.
- Anything that adds friction without preventing a real attack class.

## Style

- Markdown, no HTML. Fenced code blocks with language tags (` ```ts `, ` ```python `).
- Use the existing `#### FAIL` / `#### PASS` block convention.
- Section numbering is load-bearing — the skill references its own sections by number. If you add a section, renumber consistently.
- No emoji, no marketing language, no "easy"/"simply"/"just". The skill addresses senior engineers who already know the basics.
- Lines wrap naturally; no enforced column limit.

## How to contribute

### 1. For typo / formatting / dead-link fixes

Open a PR directly. Title: `fix: <short description>`.

### 2. For new patterns or revisions

Open an issue first with:

- The exploit class.
- A 5-line "what's wrong with the current advice" (if any).
- The replacement, in skeleton form.

If maintainers green-light it, open a PR. Title: `feat: <section>: <short description>` (e.g., `feat: §3.7: cover DNS rebinding for safeFetch`).

### 3. For security issues in SKILL.md content

**Do not open a public PR or issue.** See [SECURITY.md](./SECURITY.md) for private reporting.

## PR checklist

- [ ] The change is in `SKILL.md` or repo metadata only — no code is added (this is a docs-only skill).
- [ ] Section numbering is intact.
- [ ] Code examples actually run / would compile (test them locally).
- [ ] Stack quick-reference (Section 14) updated if you added a stack-specific note.
- [ ] `CHANGELOG.md` updated under `## [Unreleased]`.
- [ ] No personal data, internal URLs, real credentials, or org-specific paths.

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
