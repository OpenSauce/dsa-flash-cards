---
title: "Docker Image Layers and Build Cache"
order: 1
summary: "How Docker builds images from stacked layers, why Dockerfile instruction order determines build speed, and how to optimize with layer caching and multi-stage builds."
---

## Why This Matters

A Docker build that takes 10 minutes every time you change a single line of code is a build that someone misconfigured. Understanding layers is the difference between a 10-minute rebuild and a 5-second one. It also directly affects image size, security surface, and CI pipeline costs.

## Images Are Stacks of Layers

A Docker image is not a single blob. It is an ordered stack of read-only filesystem layers, each produced by a Dockerfile instruction. When Docker runs a container, it merges these layers into a single filesystem view using a union filesystem (overlay2 on most Linux hosts) and adds a thin writable layer on top.

```
┌──────────────────────────┐
│   Writable container     │  <- created at runtime, ephemeral
├──────────────────────────┤
│   COPY . .               │  Layer 4 (your app code)
├──────────────────────────┤
│   RUN pip install ...    │  Layer 3 (dependencies)
├──────────────────────────┤
│   COPY requirements.txt  │  Layer 2
├──────────────────────────┤
│   FROM python:3.12-slim  │  Layer 1 (base image)
└──────────────────────────┘
```

Each layer records only the filesystem changes introduced by its instruction -- files added, modified, or deleted. Layers are identified by content hashes and shared across images. If two images use the same base, they share those base layers on disk.

### Which Instructions Create Layers?

`RUN`, `COPY`, and `ADD` create new filesystem layers. Other instructions like `ENV`, `WORKDIR`, `EXPOSE`, and `CMD` add metadata to the image configuration but do not produce filesystem layers.

### Copy-on-Write at Runtime

When a running container modifies a file from a lower layer, Docker copies that file into the writable layer before applying the change. The original layer stays untouched. This is copy-on-write: read from below, write to the top.

## The Build Cache

Docker caches each layer. On rebuild, it walks the Dockerfile top to bottom:

1. Has this instruction changed? (For `RUN`, has the command string changed? For `COPY`, have the source file checksums changed?)
2. Is the parent layer unchanged?

If both answers are "no," Docker reuses the cached layer instantly. The moment one layer's cache is **invalidated**, every subsequent layer must be rebuilt -- even if those later instructions have not changed.

This is the single most important concept for build performance: **cache invalidation cascades to subsequent layers.**

### Why Instruction Order Matters

Consider this Dockerfile:

```dockerfile
FROM python:3.12-slim
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
```

Every time you edit any source file, `COPY . .` invalidates, which forces `RUN pip install` to re-execute. Dependencies are reinstalled on every code change.

Now reorder:

```dockerfile
FROM python:3.12-slim
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

The `pip install` layer only rebuilds when `requirements.txt` changes. Code changes only affect the final `COPY . .` layer. This pattern applies universally -- `package.json` before `npm install`, `go.mod` before `go build`, and so on.

**The rule:** instructions that change rarely go near the top; instructions that change often go near the bottom.

### .dockerignore and Cache Stability

`COPY . .` sends the entire build context to the Docker daemon. Without a `.dockerignore`, files irrelevant to the build (`.git/`, `node_modules/`, `__pycache__/`, `.env`) are included. These files change frequently and bust the cache for no reason.

A `.dockerignore` file is not optional. It affects both build speed (smaller context to transfer) and cache stability (fewer irrelevant changes triggering rebuilds).

## Multi-Stage Builds

A multi-stage build uses multiple `FROM` statements. Each stage starts fresh. You compile in one stage and copy only the output into a minimal final stage.

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

**Why this matters:**

- The Go SDK, source code, and build tools never appear in the final image. A Go binary in Alpine can be 15-20 MB vs 800+ MB with the full SDK image.
- Build tools and source are not shipped to production, reducing the attack surface.
- Each stage has its own cache. If only application code changes, the `go mod download` stage is reused.

### When to Use Multi-Stage

Use multi-stage builds when your build toolchain is significantly larger than your runtime artifact. This includes compiled languages (Go, Rust, C++), frontend builds (Node building static assets served by Nginx), and any image where you want to separate "tools I need to build" from "things I need to run."

## Common Mistakes

**Mistake: Mixing unrelated concerns in one RUN.** Chaining `apt-get install && pip install && npm install` in a single `RUN` creates one layer. If any dependency list changes, the entire layer rebuilds. Split by concern: OS packages in one `RUN`, Python dependencies in another, so each layer caches independently. The trade-off: more `RUN` instructions means more layers (slightly larger image), but better cacheability. Combine commands that always change together; separate commands with different change frequencies.

**Mistake: Installing dev dependencies in production images.** Include `--no-dev` flags (pip), `--production` flags (npm), or separate build stages to keep test frameworks and linters out of the final image.

**Mistake: Running as root.** Containers run as root by default. Add a non-root user in the Dockerfile. This limits the blast radius if the container is compromised.

```dockerfile
RUN adduser --disabled-password appuser
USER appuser
```

## Key Takeaways

- Each `RUN`, `COPY`, and `ADD` instruction creates an immutable layer identified by its content hash.
- Cache invalidation cascades: once a layer changes, every subsequent layer rebuilds. Order your Dockerfile from least-changing to most-changing.
- Copy dependency manifests before source code so dependency installation is cached across code changes.
- Use `.dockerignore` to exclude files that would unnecessarily bust the cache.
- Multi-stage builds separate build tooling from the runtime image, reducing size and attack surface.
