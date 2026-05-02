---
name: Feature request
about: Propose a new pattern, section, or stack-specific note.
title: "feat: §<section>: <short description>"
labels: ["enhancement"]
assignees: []
---

## What attack class does this prevent or detect?

Be specific. "It's a best practice" is not an answer. Examples:
- "Prototype pollution via merging unsanitized JSON"
- "Privilege escalation via mass assignment in `User.update(req.body)`"
- "Deserialization RCE via untrusted YAML input"

## What's missing in `SKILL.md` today?

Quote or reference the gap. Is it absent entirely, or is the current advice incomplete?

## Proposed addition (skeleton)

```text
#### FAIL
<minimal broken example>

#### PASS
<minimal secure example>

Rules:
- <bullet>
- <bullet>
```

## Scope

- [ ] Universal (applies to most stacks)
- [ ] Stack-specific (goes in § 14)
- [ ] New section

## References

Links to CVEs, OWASP cheat sheets, vendor advisories, blog posts that document the attack class.
