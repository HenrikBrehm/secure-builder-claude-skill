# 3.9 + 3.10 — Error handling and logging

## 3.9 Error handling

### FAIL
```ts
catch (e) { res.status(500).send(e.stack) }              // leaks paths, env, query
catch (e) { res.status(500).json({ error: e }) }         // leaks DB error details
try { ... } catch {}                                      // silent failure
```

### PASS
```ts
catch (e) {
  log.error({ err: e, requestId }, "internal error")     // server log only
  res.status(500).json({ error: "internal_error", requestId })
}
```

### Rules
- Generic message + correlation ID to the client. Full detail to server logs only.
- Never `try { ... } catch {}` to silence errors. Either handle them meaningfully or let them propagate.
- Don't catch and re-throw without context — wrap with a higher-level cause (`throw new Error("user lookup failed", { cause: e })`).
- Don't return DB error messages, stack traces, or framework debug pages in production.

## 3.10 Logging

- **Log:** who, what, when, from where, with what result, and a request ID.
- **Never log:** passwords, full tokens, full card numbers, SSNs, raw request bodies on auth endpoints, full session cookies, full API keys.
- For tokens, log a stable prefix only (e.g., `tok_abc...`).
- Audit-log security-sensitive actions (login, logout, password change, role change, payment, admin action) to a separate immutable sink if possible.
- Never write logs to the application's own writable directory in production — ship to stdout / journald / a log service.
