# 10. Recommended files for new projects

## `.github/dependabot.yml`
```yaml
version: 2
updates:
  - package-ecosystem: npm                # adapt: pip, cargo, gomod, bundler, ...
    directory: "/"
    schedule: { interval: weekly }
    open-pull-requests-limit: 10
    groups:
      patch-and-minor:
        update-types: [patch, minor]
  - package-ecosystem: github-actions
    directory: "/"
    schedule: { interval: weekly }
  - package-ecosystem: docker
    directory: "/"
    schedule: { interval: weekly }
```

## `.github/CODEOWNERS`
```
*                       @owner
/auth/                  @owner @security
/payments/              @owner @security
/.github/workflows/     @owner @security
/infra/                 @owner @security
/Dockerfile             @owner @security
```

## `.pre-commit-config.yaml`
```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.4
    hooks: [{ id: gitleaks }]
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: detect-private-key
      - id: check-added-large-files
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-merge-conflict
```

## `.dockerignore`
```
.git
.gitignore
.env
.env.*
*.pem
*.key
node_modules
dist
build
coverage
.vscode
.idea
*.log
README.md
```
