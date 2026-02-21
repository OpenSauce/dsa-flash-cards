---
title: "Docker Build Cache"
order: 2
summary: "How Docker's layer cache works, what triggers cache invalidation, why Dockerfile instruction order determines build speed, and how .dockerignore stabilizes the cache."
---

## Why This Matters

The build cache is the difference between a 10-second rebuild and a 10-minute one. Every CI pipeline, every developer's inner loop, every deployment depends on understanding what makes Docker reuse a layer versus rebuild it from scratch. Misordering a single instruction can force an entire dependency installation on every code change.

## How the Cache Works

Docker caches each layer produced during a build. On rebuild, it evaluates instructions top to bottom:

1. Is the instruction unchanged?
2. Are the instruction's inputs unchanged?
3. Is the parent layer cached?

If all three are true, Docker reuses the cached layer instantly. The moment one layer's cache is **invalidated**, every layer after it is rebuilt -- even if those later instructions have not changed.

This cascade is the core mechanic: **cache invalidation flows downward through the Dockerfile.**

## What Triggers Invalidation

Different instructions have different invalidation rules:

**`COPY` and `ADD`:** Docker computes checksums of the source files. If any file's content has changed, the layer is invalidated. Modification timestamps (mtime) are ignored -- only content matters.

**`RUN`:** The command string is compared. If the string is identical and the parent layer is cached, the layer is reused. Docker does not inspect what the command actually does at runtime. `RUN apt-get update` may produce different results on different days, but Docker treats the identical string as a cache hit.

**Metadata instructions (`ENV`, `WORKDIR`, `CMD`):** Invalidated when the instruction string changes. No filesystem layer is created, but invalidation still cascades to subsequent instructions.

## Instruction Ordering

Because invalidation cascades downward, instruction order determines cache efficiency.

**Bad ordering:**

```dockerfile
FROM python:3.12-slim
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
```

Any source file change invalidates `COPY . .`, which forces `pip install` to re-run. Dependencies are reinstalled on every code change.

**Good ordering:**

```dockerfile
FROM python:3.12-slim
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

The `pip install` layer only rebuilds when `requirements.txt` changes. Code changes only affect the final `COPY . .` layer.

**The rule:** instructions that change rarely go near the top; instructions that change often go near the bottom.

This pattern applies universally: `package.json` before `npm install`, `go.mod` before `go build`, `Gemfile` before `bundle install`.

## .dockerignore and Cache Stability

`COPY . .` sends the entire build context to the Docker daemon. Without a `.dockerignore`, files irrelevant to the build -- `.git/`, `node_modules/`, `__pycache__/`, `.env` -- are included. These files change frequently and bust the cache for no reason.

A `.dockerignore` file excludes specified files from the build context. This has three effects:

1. **Cache stability** -- files excluded by `.dockerignore` cannot trigger cache invalidation on `COPY . .`
2. **Build speed** -- a smaller build context means less data sent to the daemon
3. **Security** -- `.env` files, credentials, and secrets are kept out of the image

```
.git
node_modules
__pycache__
.env
*.md
```

## Layer Granularity Trade-off

Chaining commands with `&&` in a single `RUN` creates one layer. Splitting into separate `RUN` instructions creates multiple layers.

- **Fewer layers (chained):** smaller total image size, but the entire layer rebuilds if any part of the chain's inputs change
- **More layers (split):** larger image, but each layer caches independently

Combine commands that always change together. Separate commands with different change frequencies. OS package installation and application dependency installation should almost always be separate `RUN` instructions.

## Key Takeaways

- Docker evaluates cache top to bottom. The first invalidated layer forces all subsequent layers to rebuild.
- `COPY`/`ADD` invalidation is based on file content checksums, not timestamps.
- `RUN` invalidation is based on the command string only -- Docker does not track external state.
- Order your Dockerfile from least-frequently-changing to most-frequently-changing instructions.
- Copy dependency manifests before source code so dependency installation survives code changes.
- Always use a `.dockerignore` to prevent irrelevant files from busting the cache.
