# 4. Dependency & supply-chain hygiene

## 4.1 At project init

- **Commit lockfiles:** `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `requirements.txt` (with `pip-compile`), `Pipfile.lock`, `poetry.lock`, `Cargo.lock`, `go.sum`, `Gemfile.lock`.
- **Pin runtime version:** `.nvmrc`, `.python-version`, `.tool-versions`, `engines` in `package.json`.
- **Vet new deps:** maintainer activity, last release date, weekly downloads, open CVEs, install scripts. Prefer well-maintained alternatives over hot-but-new packages.

## 4.2 Block install-time code execution

`postinstall` / `preinstall` / `prepare` hooks run arbitrary code at `npm install` time — a top vector for compromised packages. Disable by default and allowlist what genuinely needs to compile.

```bash
# Per project (.npmrc)
ignore-scripts=true

# Per command
npm ci --ignore-scripts
```

```yaml
# pnpm — explicit allowlist (package.json)
"pnpm": {
  "onlyBuiltDependencies": ["esbuild", "sharp"]
}
```

For native modules that genuinely need a build step (`sharp`, `esbuild`, `@swc/core`), allowlist by name. Everything else stays sandboxed.

Yarn 4: `enableScripts: false` in `.yarnrc.yml`.

## 4.3 Continuous

Enable Dependabot or Renovate at repo creation. Run on CI:
- Node: `npm audit --audit-level=high` or `pnpm audit`
- Python: `pip-audit` (preferred) or `safety check`
- Rust: `cargo audit`
- Go: `govulncheck ./...`
- Ruby: `bundler-audit`

Block CI on **high/critical**. Warn on moderate.

## 4.4 Typosquatting & slopsquatting

Before installing any package — especially one suggested by an LLM:

1. Check the name carefully (no typo of a popular package).
2. Verify the package exists on the registry **and** has prior versions.
3. Look at the linked GitHub repo: stars, last commit, open issues, release history.
4. Check weekly downloads. Brand-new package + suspicious name = stop and ask.

LLMs hallucinate package names; attackers register the hallucinations. If you're not sure a package is real, search the registry rather than guessing.

## 4.5 Lock package install sources

- npm: configure a registry, never auto-trust HTTP mirrors.
- Python: use `--require-hashes` for production installs where feasible.
- Avoid `curl ... | bash` install steps for build dependencies.

## 4.6 SBOM and provenance (mature projects)

- Generate an SBOM at build time: `cyclonedx-npm` (Node), `syft` (multi-lang). Attach to releases.
- For GitHub-released artifacts, sign + attest provenance with [`actions/attest-build-provenance`](https://github.com/actions/attest-build-provenance) — gives consumers a verifiable build trail (SLSA L3).
- Container images: `cosign sign` + `cosign attest` against a build-time SBOM.
