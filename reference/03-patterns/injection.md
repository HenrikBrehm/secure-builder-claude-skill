# 3.4 SQL / NoSQL injection

## FAIL
```ts
db.query(`SELECT * FROM users WHERE email = '${email}'`)
db.users.find({ $where: `this.email == '${email}'` })
```

## PASS
```ts
// Parameterized
db.query("SELECT * FROM users WHERE email = $1", [email])

// ORM
await prisma.user.findUnique({ where: { email } })

// Mongo — pass an object, never a string with $where
await coll.find({ email })
```

## Rules

- Never concatenate user input into a query.
- Never use `eval`, `$where`, or `db.command({ eval })`.
- For dynamic column/table names, validate against a hardcoded allowlist before interpolating.
- For raw SQL, use the driver's parameter binding (`$1`, `?`, named params) — not string templating.
