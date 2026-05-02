# 6. Docker hardening

## Dockerfile

### PASS
```dockerfile
# Pin base image by digest, not just tag
FROM node:20.11-alpine@sha256:abcd1234... AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev --ignore-scripts
COPY . .
RUN npm run build

FROM node:20.11-alpine@sha256:abcd1234...
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
USER app
COPY --from=build --chown=app:app /app/dist         ./dist
COPY --from=build --chown=app:app /app/node_modules ./node_modules
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://127.0.0.1:3000/health || exit 1
CMD ["node", "dist/index.js"]
```

### Rules
- **Pin base images by digest** (`@sha256:...`), not floating tags.
- Use minimal base (`-alpine`, `-slim`, `gcr.io/distroless/*`).
- Multi-stage to drop build deps from the final image.
- Run as **non-root** (`USER app`).
- Don't `COPY . .` before adding `.dockerignore`.
- `.dockerignore` includes `.env`, `.git`, `node_modules`, `*.pem`, `coverage/`, `*.log`.
- No secrets in `ARG` or `ENV` (visible in image history). Use BuildKit secrets:
  ```dockerfile
  RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci
  ```
- Set `HEALTHCHECK`.
- Drop capabilities at runtime: `docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE`.

## docker-compose

- Don't expose DB ports to the host (use `expose:` not `ports:`) unless you need them locally.
- Read secrets from a gitignored `.env` file or use Docker secrets / external secret managers.
- Set `read_only: true` on containers that don't need writable rootfs; mount `tmpfs` for `/tmp`.
- Set `security_opt: ["no-new-privileges:true"]`.
