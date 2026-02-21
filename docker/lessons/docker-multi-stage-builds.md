---
title: "Multi-Stage Builds"
order: 3
summary: "Using multiple FROM statements to separate build tooling from runtime artifacts, dramatically reducing image size and attack surface."
---

## Why This Matters

A Go application image with the full SDK is 800+ MB. The compiled binary in Alpine is 15-20 MB. A Node.js image with `node_modules` and build tools is 400+ MB. The production bundle served by Nginx is 50 MB. Multi-stage builds are how you get from the first number to the second without maintaining multiple Dockerfiles or writing cleanup scripts.

## The Problem: Build Tools in Production

A single-stage Dockerfile for a compiled language includes everything needed to build the application -- compiler, linker, build tools, source code, intermediate artifacts. All of this ends up in the final image, even though none of it is needed at runtime.

```dockerfile
FROM golang:1.22
WORKDIR /app
COPY . .
RUN go build -o /server
CMD ["/server"]
```

This image ships the entire Go SDK, your source code, and all build cache artifacts. It is large, slow to pull, and exposes tools an attacker could use if the container is compromised.

## The Solution: Multiple Stages

A multi-stage build uses multiple `FROM` statements in a single Dockerfile. Each `FROM` begins a new build stage with its own base image and filesystem. You build in one stage and copy only the output into a minimal final stage.

```dockerfile
# Stage 1: Build
FROM golang:1.22 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /server

# Stage 2: Runtime
FROM alpine:3.19
COPY --from=builder /server /server
CMD ["/server"]
```

The `COPY --from=builder` instruction copies the compiled binary from the build stage into the runtime stage. The final image contains only Alpine and the binary. The Go SDK, source code, and build artifacts are discarded.

## Why It Matters Beyond Size

**Security:** Build tools, compilers, and source code never ship to production. A compromised container has fewer tools available to an attacker.

**Pull speed:** Smaller images deploy faster. In a CI/CD pipeline that pulls images on every deployment, the difference between 800 MB and 20 MB adds up.

**Layer caching per stage:** Each stage caches independently. In the example above, if only application code changes, the `go mod download` stage is reused. Dependencies are not re-downloaded.

## The Pattern for Interpreted Languages

Multi-stage builds are not just for compiled languages. For Node.js, Python, or Ruby, you can install dependencies and build in one stage, then copy the production artifacts into a clean runtime image:

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .
RUN yarn build

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/package.json /app/yarn.lock ./
RUN yarn install --frozen-lockfile --production
COPY --from=builder /app/.output ./
CMD ["node", ".output/server/index.mjs"]
```

The key: dev dependencies, build scripts, and source files stay in the build stage. Only the production bundle and production dependencies make it to the final image.

## When to Use Multi-Stage

Use multi-stage builds when your build toolchain is significantly larger than your runtime artifact:

- **Compiled languages** (Go, Rust, C/C++) -- compiler and SDK are not needed at runtime
- **Frontend builds** -- Node builds static assets served by Nginx or a minimal server
- **Any image** where "tools I need to build" differs from "things I need to run"

If your build and runtime environments are the same (e.g., a Python Flask app that just runs `pip install` and starts), multi-stage may not help much. But it is still useful if you have dev-only dependencies or build steps that produce artifacts.

## Key Takeaways

- Multi-stage builds use multiple `FROM` statements. Each stage starts with a clean filesystem.
- `COPY --from=<stage>` transfers artifacts between stages. Only the final stage becomes the image.
- Build tools, compilers, and source code never appear in the runtime image.
- Each stage caches independently, so dependency downloads survive code changes.
- The pattern applies to compiled languages, frontend builds, and any workflow where build tools differ from runtime needs.
