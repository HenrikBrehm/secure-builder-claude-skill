# 3.2 Authorization

Authorization is checked **per request, per resource, on the server, after authentication**.

## FAIL
```ts
// IDOR — anyone can fetch any document
app.get("/docs/:id", async (req, res) => {
  res.json(await db.docs.findById(req.params.id))
})
```

## PASS
```ts
app.get("/docs/:id", requireAuth, async (req, res) => {
  const doc = await db.docs.findOne({ id: req.params.id, ownerId: req.user.id })
  if (!doc) return res.status(404).end()  // 404, not 403, to avoid leaking existence
  res.json(doc)
})
```

## Rules

- **Default deny.** Whitelist what each role can do.
- Check ownership/permission on **every** read AND write. Never trust the client to send `?ownerId=me`.
- Centralize policy via middleware / policy objects. Don't scatter role checks.
- Admin-only routes: separate router with `requireAdmin`, plus an audit log entry for every action.
- Beware of "mass assignment" — never spread `req.body` directly into `User.update(...)`. Use an explicit allowlist of writable fields.
