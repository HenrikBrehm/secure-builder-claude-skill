# 3.12 + 3.13 — Rate limiting and crypto

## 3.12 Rate limiting & abuse

- Global: per-IP and per-user request rate.
- Stricter limits on auth, password reset, email send, expensive endpoints, AI-cost endpoints.
- Use a shared store (Redis) so limits work across instances.
- Return `429 Too Many Requests` with `Retry-After`.

## 3.13 Crypto

- Use the platform's audited crypto. Never roll your own primitives.
- **Random tokens:** `crypto.randomBytes(32).toString("base64url")` (Node), `secrets.token_urlsafe(32)` (Python). Never `Math.random()`.
- **Constant-time comparison** for tokens: `crypto.timingSafeEqual`. String `===` leaks via timing.
- **Symmetric encryption:** AEAD (AES-GCM, ChaCha20-Poly1305) — never AES-CBC without HMAC.
- **Asymmetric:** Ed25519 for signing, X25519 for ECDH where possible. RSA-2048 minimum if RSA is required.
- **Key derivation from passwords:** Argon2id (see `reference/03-patterns/auth.md`), not raw SHA-256.
- **HMAC keys:** at least 32 random bytes; never reuse an HMAC key for encryption (and vice versa).
- **Rotation:** every secret has an expected rotation cadence written down; HMAC/JWT signing keys rotate via dual-key acceptance windows so verifier and signer can be updated independently.
