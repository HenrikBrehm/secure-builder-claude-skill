# 3.3 Input validation

Validate at every trust boundary.

## PASS — TypeScript / Zod
```ts
import { z } from "zod"

const CreateUser = z.object({
  email: z.string().email().max(254),
  name:  z.string().min(1).max(100),
  age:   z.number().int().min(13).max(120),
}).strict()  // reject unknown keys

app.post("/users", async (req, res) => {
  const parsed = CreateUser.safeParse(req.body)
  if (!parsed.success) return res.status(400).json({ errors: parsed.error.flatten() })
  const user = await db.users.create(parsed.data)
  res.status(201).json({ id: user.id })
})
```

## PASS — Python / Pydantic
```python
from pydantic import BaseModel, EmailStr, Field, ConfigDict

class CreateUser(BaseModel):
    model_config = ConfigDict(extra="forbid")
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)
    age: int = Field(ge=13, le=120)
```

## Rules

- Reject unknown fields (`strict()` / `extra="forbid"`).
- Set max sizes on every string and array.
- Validate types AND ranges, not just types.
- Re-validate on the server even if the client validates.
- For numeric IDs from a path, parse to int/UUID and reject malformed before any DB call.
