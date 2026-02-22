---
title: "Docker Storage and Volumes"
summary: "Why container filesystems are ephemeral, the three storage options (volumes, bind mounts, tmpfs), and when to use each."
reading_time_minutes: 3
order: 3
---

## Why This Matters

Containers are disposable by design. You should be able to destroy and recreate one without losing data. But applications need to persist data -- databases, user uploads, configuration. Understanding Docker's storage model is how you keep data alive across container restarts and removals.

## The Container Filesystem Is Ephemeral

When Docker runs a container, it stacks the image's read-only layers and adds a thin writable layer on top. All file writes inside the container go to this writable layer.

When the container is **stopped**, the writable layer is preserved. The container still exists on disk; it is just not running. You can restart it and find your files intact.

When the container is **removed** (`docker rm`), the writable layer is deleted permanently. Everything written inside the container is gone.

This is intentional. Containers are meant to be replaceable. Anything that needs to survive must be stored outside the container's writable layer.

## Three Storage Options

Docker provides three ways to persist data beyond the container lifecycle.

### Volumes (Docker-managed)

A volume is a directory managed by Docker, stored at `/var/lib/docker/volumes/` on the host. Docker handles creation, mounting, and cleanup.

```bash
docker volume create mydata
docker run -v mydata:/app/data myimage
```

**Characteristics:**
- Created and managed by Docker, independent of any specific host path
- Survives container removal -- the volume persists until explicitly deleted
- Portable: works the same on any host running Docker
- Can be shared between multiple containers
- Supports volume drivers for remote/cloud storage

**Use for:** Production databases, application state, anything that must survive container replacement.

### Bind Mounts (host-managed)

A bind mount maps a specific host directory directly into the container. Both the host and the container see the same files in real time.

```bash
docker run -v /home/user/project:/app myimage
```

**Characteristics:**
- The host controls the path and contents
- Changes on either side are immediately visible to the other
- Depends on the host's directory structure -- not portable
- The container process can modify host files (security consideration)

**Use for:** Development workflows. Mount your source code into a container so changes on the host trigger live reloading inside the container.

### tmpfs Mounts (memory-only)

A tmpfs mount stores data in the host's RAM. Nothing is written to disk. Data disappears when the container stops.

```bash
docker run --tmpfs /app/cache myimage
```

**Characteristics:**
- Fastest option: pure RAM, no disk I/O
- Data does not persist -- gone when the container stops (not just when removed)
- Not shared between containers
- Never written to the host filesystem

**Use for:** Sensitive ephemeral data (secrets, session tokens) that should not touch disk, or scratch space for temporary computations.

## Choosing the Right Option

| Scenario | Use |
|---|---|
| Database files in production | Volume |
| Application state that must survive redeployment | Volume |
| Source code during development (live reload) | Bind mount |
| Sharing config files from host to container | Bind mount |
| Temporary secrets or session data | tmpfs |
| Scratch space for computation | tmpfs |

**The rule of thumb:** Volumes for persistent production data. Bind mounts for development. tmpfs for ephemeral secrets.

## Managing Volumes

```bash
docker volume create mydata       # Create a named volume
docker volume ls                  # List all volumes
docker volume inspect mydata      # Show volume details (mount point, driver)
docker volume rm mydata           # Delete a volume
docker volume prune               # Delete all unused volumes
```

Volumes that are no longer referenced by any container are "dangling." `docker volume prune` cleans these up. Be careful -- this is destructive and cannot be undone.

## Key Takeaways

- The container's writable layer is deleted on `docker rm`. `docker stop` preserves it.
- Volumes are Docker-managed, portable, and persist independently of containers. Use for production data.
- Bind mounts map a host path into the container, with real-time sync. Use for development.
- tmpfs mounts live in RAM and vanish when the container stops. Use for ephemeral secrets.
- If you store data only in the container's writable layer, that data will not survive container replacement.
