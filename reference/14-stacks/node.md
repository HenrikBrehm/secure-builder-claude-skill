# 14. Node / Express / Fastify

- `helmet`, `express-rate-limit`, `cors` with explicit origin allowlist, `csrf-csrf` (cookie sessions — see `reference/03-patterns/xss-csrf.md`), `zod` validation.
- Don't trust `X-Forwarded-For` unless behind a known proxy: `app.set('trust proxy', N)` with the right hop count.
- `argon2` for passwords; `jsonwebtoken` only for short-lived access tokens (refresh-token rotation per `reference/03-patterns/auth.md`).
- `npm ci --ignore-scripts` in CI; pnpm `onlyBuiltDependencies` allowlist (`reference/04-supply-chain.md`).
