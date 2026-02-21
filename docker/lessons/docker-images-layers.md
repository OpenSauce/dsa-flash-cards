---
title: "Docker Images and Layers"
order: 1
summary: "What a Docker image actually is, how Dockerfile instructions produce stacked filesystem layers, and how copy-on-write works at runtime."
---

## Why This Matters

Every Docker image you pull or build is a stack of layers. Understanding this structure explains why images share disk space, why some builds are fast while others are slow, and why containers can start in milliseconds. Layers are the foundation for everything else in Docker -- build caching, multi-stage builds, and image size optimization all depend on this mental model.

## An Image Is a Stack of Read-Only Layers

A Docker image is not a single file. It is an ordered sequence of filesystem layers, each representing the changes made by one Dockerfile instruction. When Docker creates a container from an image, it stacks these layers using a union filesystem (overlay2 on most Linux hosts) to present a single merged view.

```
+----------------------------+
|   Writable container layer |  <- created at runtime, ephemeral
+----------------------------+
|   COPY . .                 |  Layer 4 (your app code)
+----------------------------+
|   RUN pip install ...      |  Layer 3 (dependencies)
+----------------------------+
|   COPY requirements.txt .  |  Layer 2
+----------------------------+
|   FROM python:3.12-slim    |  Layer 1 (base image)
+----------------------------+
```

Each layer records only the filesystem diff introduced by its instruction -- files added, modified, or deleted. Layers are identified by content hashes (SHA256 digests), which means identical layers are stored only once on disk, even if used by multiple images.

## Which Instructions Create Layers?

Only three Dockerfile instructions produce filesystem layers:

- **`RUN`** -- executes a command and captures the resulting filesystem changes
- **`COPY`** -- copies files from the build context into the image
- **`ADD`** -- like COPY, but with tar extraction and URL download

Other instructions -- `ENV`, `WORKDIR`, `EXPOSE`, `CMD`, `ENTRYPOINT`, `LABEL` -- modify the image's configuration metadata but do not create filesystem layers.

## Layer Sharing

If two images use the same base (`FROM python:3.12-slim`), they share those base layers on disk and in memory. This is why pulling a second image that uses the same base is fast -- Docker already has the shared layers and only downloads the new ones.

This also means deleting a file in a later layer does not reduce the image size. The file still exists in the earlier layer. It is merely hidden by a "whiteout" marker in the upper layer. To truly remove files from the image, you must avoid adding them in the first place, or use multi-stage builds to start fresh.

## Copy-on-Write at Runtime

When a running container reads a file, it reads from the highest layer that contains that file. When it writes to a file from a lower layer, Docker copies the file into the writable container layer before applying the change. The original image layer is never modified.

This is copy-on-write: reads fall through to lower layers, writes go to the top. It is why containers start instantly -- they do not need to duplicate the entire image filesystem. They just add a thin writable layer on top.

## Key Takeaways

- A Docker image is an ordered stack of read-only filesystem layers, merged at runtime by a union filesystem.
- `RUN`, `COPY`, and `ADD` create layers. Other instructions modify metadata only.
- Layers are content-addressed (SHA256). Identical layers are shared across images.
- Deleting a file in a later layer hides it but does not shrink the image -- the file persists in the earlier layer.
- Containers add a thin writable layer on top of the image stack via copy-on-write.
