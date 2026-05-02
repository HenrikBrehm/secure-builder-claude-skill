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
  if (!doc) return res.status(404).end()  // see "404 vs 403" below
  res.json(doc)
})
```

## Rules

- **Default deny.** Whitelist what each role can do.
- Check ownership/permission on **every** read AND write. Never trust the client to send `?ownerId=me`.
- Centralize policy via middleware / policy objects. Don't scatter role checks.
- Admin-only routes: separate router with `requireAdmin`, plus an audit log entry for every action.
- Beware of "mass assignment" — never spread `req.body` directly into `User.update(...)`. Use an explicit allowlist of writable fields.

## 404 vs 403

There's no universal answer — it's a tradeoff per surface:

- **Return `404`** when the *existence* of the resource is itself sensitive (private documents, other users' profiles in a privacy-sensitive product, anything where "this object exists but isn't yours" leaks something attackers can enumerate).
- **Return `403`** on internal/admin tools, B2B apps where users legitimately know what objects exist, or any surface where a clear `forbidden` response materially aids debugging for legitimate users. Pair with an audit log entry.

The footgun is **mixing them on the same surface**: if `/docs/:id` returns `404` for non-existent docs and `403` for existing-but-not-yours, the status code itself is an oracle. Pick one per route family and apply it consistently.
