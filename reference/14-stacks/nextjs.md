# 14. Next.js

- Server Actions: validate inputs, check auth, never accept arbitrary `redirect()` targets from input.
- API routes: same as Express. Prefer `next-auth` / Auth.js over hand-rolled.
- Set headers via `next.config.js` `headers()` or middleware. CSP nonce pattern in `reference/03-patterns/headers.md`.
- Beware of `revalidatePath` / `revalidateTag` triggered by unauthenticated requests.
