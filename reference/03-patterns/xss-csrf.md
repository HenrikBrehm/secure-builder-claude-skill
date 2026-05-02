# 3.5 + 3.6 — Cross-site scripting (XSS) and Cross-site request forgery (CSRF)

## 3.5 XSS

### FAIL
```jsx
<div dangerouslySetInnerHTML={{ __html: userBio }} />
```

### PASS
```jsx
<div>{userBio}</div>  // React auto-escapes text children

// If rendering HTML is required, sanitize first
import DOMPurify from "isomorphic-dompurify"
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userBio) }} />
```

### Rules
- Default-escape templates (React/Vue/Svelte/Angular do this — don't fight the framework).
- Set CSP — see `reference/03-patterns/headers.md` for the nonce/hash strategy.
- Avoid inline scripts/handlers. If you must, use a per-response nonce (not `'unsafe-inline'`).
- Set `X-Content-Type-Options: nosniff` and `Referrer-Policy: strict-origin-when-cross-origin`.

## 3.6 CSRF

For browser apps with cookie sessions:

### PASS — `csrf-csrf` (signed double-submit cookie)
```ts
import { doubleCsrf } from "csrf-csrf"

const { doubleCsrfProtection, generateToken } = doubleCsrf({
  getSecret: () => process.env.CSRF_SECRET!,        // 32+ random bytes
  cookieName: "__Host-x-csrf",                      // __Host- locks Path=/, Secure, no Domain
  cookieOptions: { sameSite: "lax", secure: true, httpOnly: true, path: "/" },
  size: 64,
  getTokenFromRequest: (req) => req.headers["x-csrf-token"] as string | undefined,
})

app.use(doubleCsrfProtection)

app.get("/csrf-token", (req, res) => res.json({ token: generateToken(req, res) }))
```

> **Why not `csurf`?** Unmaintained since 2022 and removed from the Express recommendations list. `csrf-csrf` is the actively maintained equivalent that implements the OWASP signed-double-submit pattern.

### Defense-in-depth
On state-changing handlers, also reject if the `Origin` (or `Sec-Fetch-Site: cross-site`) header doesn't match an allowlist:

```ts
const ALLOWED_ORIGINS = new Set([process.env.PUBLIC_ORIGIN!])

app.use((req, res, next) => {
  if (["POST", "PUT", "PATCH", "DELETE"].includes(req.method)) {
    const origin = req.get("origin") ?? req.get("referer")?.replace(/\/[^\/]*$/, "")
    if (!origin || !ALLOWED_ORIGINS.has(origin)) {
      return res.status(403).end()
    }
  }
  next()
})
```

### Rules
- Cookies: `SameSite=Lax` (default) or `Strict`. Lax allows top-level GET cross-site (which is fine since GET should be idempotent); Strict blocks it.
- Pure-API auth (Bearer in `Authorization`, no cookies) is not vulnerable to CSRF — but the server must actually require the header and not also accept a cookie.
- State-changing methods (POST/PUT/PATCH/DELETE) require the CSRF token AND the Origin/Sec-Fetch-Site check.
- CORS is **not** a CSRF defense.
