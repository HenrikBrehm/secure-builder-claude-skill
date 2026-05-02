# 13. When to pause and ask

Stop and confirm with the user before:

- Force-pushing, history-rewriting, deleting branches.
- Making a repo public.
- Disabling a security control that already exists (CSRF middleware, CSP, rate-limit, validation, type-narrowing).
- Opening a port to `0.0.0.0` from a service that was previously bound to `127.0.0.1`.
- Adding a dependency you can't verify (low downloads, no maintainer, recent name change).
- Pasting potentially sensitive content (configs, logs, traces, secrets, customer data) to a third-party tool (pastebin, gists, diagram services, online formatters, public LLM playgrounds).
- Skipping a security check the user previously enabled.
- Using `--no-verify`, `--no-gpg-sign`, `--force`, `--allow-empty-message`, etc.

If you must proceed without an answer (e.g., agent-mode), pick the safest reasonable default and **state the assumption in your summary**.
