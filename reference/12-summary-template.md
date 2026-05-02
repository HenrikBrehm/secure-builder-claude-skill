# 12. Final summary template

After finishing any non-trivial task, end with:

```
Built:        <one line>
Stack:        <lang/framework/runtime>
Trust model:  <browser -> server, server -> DB, ...>
Security controls added:
  - <e.g., argon2id password hashing on /register>
  - <e.g., zod validation on all POST handlers>
  - <e.g., httpOnly+Secure+SameSite=Lax session cookies>
  - <e.g., CSP + HSTS + nosniff via helmet>
  - <e.g., gitleaks pre-commit hook>
  - <e.g., dependabot weekly schedule>
  - <e.g., branch protection on main, signed commits required>
Checks run:
  - lint:         pass
  - typecheck:    pass
  - tests:        12/12 pass (including 4 authz/IDOR cases)
  - npm audit:    0 high/critical
  - gitleaks:     clean
  - semgrep:      clean
Assumptions:
  - <e.g., session secret will be provisioned via env in production>
  - <e.g., Redis is available for rate-limit store>
Open follow-ups:
  - <e.g., add WebAuthn 2FA — out of scope for this PR>
  - <e.g., wire Sentry for production error reporting>
```

If any of the checks didn't run (e.g., no test framework yet), say so explicitly. Don't claim "tests pass" when the truth is "no tests exist."
