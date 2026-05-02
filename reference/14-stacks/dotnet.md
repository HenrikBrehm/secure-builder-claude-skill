# 14. C# / .NET

- ASP.NET Core: `[Authorize]` and policy-based authorization. Antiforgery tokens for forms. Data Protection API for cookies.
- EF Core with parameter binding; never `FromSqlRaw` with interpolation.
- `Microsoft.AspNetCore.Identity` for auth: `PasswordHasher<TUser>` uses PBKDF2 with sensible default iterations (≥ 100,000) — **acceptable per OWASP**, not "broken." Bump `IterationCount` if your threat model warrants it. For Argon2id, the community option is `Konscious.Security.Cryptography.Argon2`; pick it when you need cross-platform parity with non-.NET stacks rather than because PBKDF2 is unsafe.
