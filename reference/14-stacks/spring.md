# 14. Java / Spring Boot

- Spring Security defaults are good. Don't disable CSRF for browser apps.
- Use `@Validated` + Bean Validation. Parameterized JPQL or Spring Data repositories.
- `BCryptPasswordEncoder` (cost ≥ 12) or `Argon2PasswordEncoder`.
