# 14. Python / FastAPI

- Pydantic models for request bodies (`extra="forbid"`). `Depends(get_current_user)` for auth. `slowapi` for rate-limiting.
- `passlib[argon2]` for passwords. SQLAlchemy with parameter binding (`text()` only with `:bindparam`s).
- Run `pip-audit` in CI; pin dependencies via `pip-compile` and commit the lockfile.
