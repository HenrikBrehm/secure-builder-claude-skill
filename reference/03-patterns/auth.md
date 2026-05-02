# 3.1 Authentication

## FAIL
```ts
// Plaintext compare
if (user.password === input.password) { ... }
// Fast hash — wrong primitive for password storage (MD5/SHA-* are designed to be cheap)
const hash = crypto.createHash("md5").update(input.password).digest("hex")
// Hardcoded JWT secret
const token = jwt.sign({ uid }, "secret123")
```

## PASS
```ts
import argon2 from "argon2"
import jwt from "jsonwebtoken"
import crypto from "node:crypto"

// Argon2id with explicit OWASP-recommended cost params (2024 floor).
// memoryCost is in KiB. Bump on stronger hardware (e.g., memoryCost: 47104 ≈ 46 MiB).
const ARGON2_OPTS = {
  type: argon2.argon2id,
  memoryCost: 19456,   // 19 MiB
  timeCost: 2,
  parallelism: 1,
} as const

const passwordHash = await argon2.hash(input.password, ARGON2_OPTS)
const valid       = await argon2.verify(user.passwordHash, input.password)

// Short-lived access token + opaque rotating refresh token stored server-side.
const accessToken = jwt.sign(
  { sub: user.id },
  process.env.JWT_SECRET!,
  { algorithm: "HS256", expiresIn: "15m" }
)
const refreshToken = crypto.randomBytes(32).toString("base64url")
await db.refreshTokens.insert({
  userId: user.id,
  tokenHash: await argon2.hash(refreshToken, ARGON2_OPTS),
  expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30d
  rotatedFrom: null,
})

// Verify with the exact algorithm used to sign — never accept `alg: none`.
jwt.verify(token, process.env.JWT_SECRET!, { algorithms: ["HS256"] })

// On refresh: verify, revoke the old row, issue a new pair, link via rotatedFrom.
// If a refresh token is presented twice (replay), revoke the entire chain — likely theft.
```

## Rules

- **Password hashing.** Use **argon2id** with explicit cost params, or **bcrypt(cost ≥ 12)**. Never use a fast hash (MD5, SHA-1, SHA-256/512 alone) for password storage — they are correct primitives for the wrong job. **PBKDF2 with ≥ 600,000 iterations (SHA-256)** is acceptable when Argon2/bcrypt is unavailable (e.g., FIPS-only environments, default ASP.NET Identity).
- **Password policy.** Length ≥ 12 (NIST allows 8 if you check against a breached-password list; 12 buys margin). Skip composition rules; use HIBP API or `zxcvbn` minimum strength.
- **Rate-limit login.** ~5/min/IP plus ~10/hour/account. Lock account or add CAPTCHA after N failures.
- **Sessions (browser).** Cookies with `httpOnly`, `Secure`, `SameSite=Lax` (or `Strict`).
- **Rotate session ID on login** to prevent session fixation.
- **Logout** invalidates server-side state (revocation list, session row delete, refresh-token rotation).
- **JWT model.** Short-lived access tokens (5–15 min) paired with **rotating refresh tokens** stored hashed server-side. Refresh-token reuse → revoke the entire chain. Don't ship 15-minute access tokens without the refresh flow — users will get logged out mid-task.
- **Algorithm pinning.** `jwt.verify(..., { algorithms: ["HS256"] })`. Never accept `alg: none`. Never let the client choose the algorithm.
- **2FA.** Prefer TOTP or WebAuthn over SMS.
