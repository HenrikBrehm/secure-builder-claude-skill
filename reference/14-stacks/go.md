# 14. Go

- `net/http` with `http.TimeoutHandler` and `Server.ReadHeaderTimeout` / `ReadTimeout` / `WriteTimeout` set.
- `database/sql` with placeholders or `sqlc` / `sqlx`. `golang.org/x/crypto/bcrypt` or `argon2` for passwords.
- `gosec ./...` + `govulncheck ./...` in CI.
