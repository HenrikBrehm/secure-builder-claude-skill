---
name: Bug report
about: A pattern in SKILL.md is wrong, broken, or produces insecure output.
title: "bug: §<section>: <short description>"
labels: ["bug"]
assignees: []
---

> **Security issue?** If this is an exploitable problem in a recommended pattern, please report privately via [GitHub Security Advisory](https://github.com/HenrikBrehm/secure-builder-claude-skill/security/advisories/new) instead. See [SECURITY.md](../../SECURITY.md).

## Section

Which `SKILL.md` section is affected? (e.g., `§ 3.7 SSRF`, `§ 7.1 Workflow defaults`)

## What's wrong

Describe the issue. Be specific:

- The recommended pattern fails when ...
- The example doesn't compile / run because ...
- The advice contradicts § X.Y because ...

## Reproducer

If applicable, paste a minimal code example showing the failure:

```ts
// or python / go / rust / etc.
```

## Expected behavior

What should the skill recommend instead, and why?

## Environment

- `SKILL.md` version (commit SHA or release tag):
- Claude Code version:
- Stack:
