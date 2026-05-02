# 3.11 Security headers (HTML responses)

## Baseline

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
Content-Security-Policy: default-src 'self'; script-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
```

Use `helmet` (Node), `secure_headers` (Rails), Django's `SECURE_*` settings + `django-csp`, etc. Don't hand-roll.

## CSP — make it actually work

The baseline above will **break most apps** if you ship it without testing. Apps inevitably load some inline script or third-party widget. Two strategies:

### Strategy A — nonce-based (preferred for apps that emit some inline `<script>`)

Server generates a fresh per-response nonce; HTML and CSP both reference it.

```ts
import crypto from "node:crypto"

app.use((req, res, next) => {
  res.locals.nonce = crypto.randomBytes(16).toString("base64")
  res.setHeader(
    "Content-Security-Policy",
    [
      `default-src 'self'`,
      `script-src 'self' 'nonce-${res.locals.nonce}' 'strict-dynamic'`,
      `style-src 'self' 'nonce-${res.locals.nonce}'`,
      `object-src 'none'`,
      `base-uri 'self'`,
      `frame-ancestors 'none'`,
      `report-uri /csp-report`,
    ].join("; ")
  )
  next()
})
```

Then in templates: `<script nonce="{{nonce}}">...</script>`. `'strict-dynamic'` lets nonce-trusted scripts load further scripts without listing every CDN.

### Strategy B — hash-based (preferred when scripts are static and known at build time)

Compute SHA-256 of every inline script at build time and add `'sha256-XXXXX='` entries to `script-src`.

### Framework caveats

- **Next.js:** App Router supports nonces via `headers()` in `middleware.ts`. Server Components produce inline styles (`<style data-emotion=...>`) that need a hash strategy or a relaxed `style-src` until the framework matures.
- **Vite (dev):** HMR injects inline scripts; either widen CSP in dev only, or skip CSP in `vite dev` and rely on `vite build` output.
- **React / Tailwind:** runtime style injection requires `style-src` allowance; nonce approach only works if the runtime accepts a nonce prop.
- **Streaming HTML / Suspense:** nonce tokens in `<script>` tags must not be regenerated mid-stream.

### Rollout

1. Ship in **Report-Only** mode first: `Content-Security-Policy-Report-Only: ...; report-uri /csp-report`.
2. Watch the report endpoint for a week — every legitimate inline script / third-party will fire.
3. Promote to enforcing only when reports are quiet.
4. Validate against [csp-evaluator.withgoogle.com](https://csp-evaluator.withgoogle.com/) — it flags `'unsafe-inline'`, missing `object-src`, fallback gaps.

### Anti-patterns

- `'unsafe-inline'` in `script-src` — that's not a CSP, that's a placebo.
- `*` in any directive that's not `img-src` or `font-src`.
- `'unsafe-eval'` — only if you genuinely need it (some legacy template engines); otherwise it's a free XSS multiplier.
- Setting CSP only on the HTML route and forgetting it on error pages / `404` / `500`.
