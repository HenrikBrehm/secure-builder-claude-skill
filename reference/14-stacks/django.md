# 14. Python / Django

- Keep `DEBUG = False` in production. Set `ALLOWED_HOSTS`. Enable all `SECURE_*` settings. CSRF + sessions are on by default — don't disable.
- `django-axes` for login rate-limiting; `django-csp` for CSP.
- Use the ORM; for raw SQL, parameterize with `cursor.execute(sql, [params])`.
