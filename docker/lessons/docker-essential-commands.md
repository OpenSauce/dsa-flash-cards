---
title: "Essential Docker Commands"
summary: "The core commands for building, running, inspecting, and managing containers, plus Dockerfile instructions CMD, ENTRYPOINT, COPY, and ADD."
reading_time_minutes: 5
order: 2
---

## Why This Matters

Knowing Docker commands is the difference between reading about containers and actually using them. These are the commands you will use daily in development, CI pipelines, and production deployments. Interviewers expect you to be conversational with them.

## Building Images

```bash
docker build -t myapp:v1 .
```

`-t` tags the image with a name and optional version. The `.` is the **build context** -- the directory whose files are available to `COPY` and `ADD` instructions. Docker sends the entire build context to the daemon before building, which is why `.dockerignore` matters (covered in the layers lesson).

## Running Containers

```bash
docker run [OPTIONS] IMAGE [COMMAND]
```

Key flags:

- **`-d`** (detached): Run in the background. Without it, the container's stdout/stderr is attached to your terminal.
- **`-p 8080:80`** (port mapping): Map host port 8080 to container port 80. Traffic hitting `localhost:8080` on the host reaches port 80 inside the container.
- **`--name myapp`**: Give the container a human-readable name instead of a random one.
- **`--rm`**: Automatically remove the container when it exits. Useful for one-off tasks so stopped containers do not pile up.
- **`-v /host/path:/container/path`**: Mount a host directory into the container (bind mount). Covered in the storage lesson.
- **`-e KEY=VALUE`**: Set an environment variable inside the container.

```bash
docker run -d -p 8080:80 --name web --rm nginx
```

This runs nginx in the background, maps port 8080 to 80, names it "web", and cleans up on exit.

## Inspecting Running Containers

**`docker ps`** lists running containers. Add `-a` to include stopped containers.

**`docker logs myapp`** shows stdout/stderr from a container. Add `-f` to follow (like `tail -f`).

**`docker exec -it myapp bash`** runs a command inside a running container. The `-it` flags allocate an interactive terminal. This is how you "shell into" a container for debugging.

**`docker inspect myapp`** outputs detailed JSON metadata about a container: IP address, mounts, environment variables, state.

## Stopping and Removing

**`docker stop myapp`** sends SIGTERM to the main process and waits up to 10 seconds for a graceful shutdown. If the process does not exit, Docker escalates to SIGKILL. You can change the timeout with `-t`: `docker stop -t 30 myapp`.

**`docker kill myapp`** sends SIGKILL immediately. No grace period. Use only when `docker stop` has failed or the container is unresponsive.

**`docker rm myapp`** removes a stopped container and its writable layer. The container must be stopped first (or use `docker rm -f` to force).

**`docker rmi myapp:v1`** removes an image. Fails if any container (running or stopped) is using it.

## Dockerfile Instructions: CMD vs ENTRYPOINT

Both define what runs when a container starts. The difference is how they handle arguments passed to `docker run`.

**CMD** sets the default command. It is fully replaced if you pass arguments:

```dockerfile
CMD ["python", "app.py"]
# docker run myimage          -> python app.py
# docker run myimage bash     -> bash (CMD replaced entirely)
```

**ENTRYPOINT** sets the executable that always runs. Arguments from `docker run` are appended:

```dockerfile
ENTRYPOINT ["python", "app.py"]
# docker run myimage          -> python app.py
# docker run myimage --debug  -> python app.py --debug
```

**Together**, ENTRYPOINT defines the executable and CMD provides default arguments:

```dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]
# docker run myimage          -> python app.py
# docker run myimage test.py  -> python test.py (CMD replaced)
```

**Always use exec form** (`["executable", "arg"]`) over shell form (`executable arg`). Shell form wraps the command in `/bin/sh -c`, which means the process is not PID 1 and does not receive signals like SIGTERM. Containers using shell form cannot shut down gracefully.

## Dockerfile Instructions: COPY vs ADD

**COPY** copies files from the build context into the image. That is all it does.

**ADD** does the same, plus two extras:
- Auto-extracts local `.tar` archives into the destination
- Can fetch files from remote URLs (discouraged -- use `curl` in a `RUN` instead)

**Always prefer COPY.** `ADD` introduces implicit behavior that makes the Dockerfile harder to reason about. Use `ADD` only when you specifically need tar extraction.

## Container Lifecycle

A container moves through these states:

```
Created -> Running -> Paused -> Running -> Stopped -> Removed
                                  |
                                  +-------> Removed
```

- **Created**: Image pulled, container filesystem set up, but process not started
- **Running**: Main process (PID 1) is executing
- **Paused**: Process frozen (SIGSTOP). Resumes where it left off
- **Stopped**: Process exited (or was killed). Container and its writable layer still exist on disk
- **Removed**: Container and writable layer deleted

`docker stop` moves Running to Stopped. `docker rm` moves Stopped to Removed. A stopped container still occupies disk space until removed.

## Key Takeaways

- `docker run -d -p HOST:CONTAINER --name NAME IMAGE` is the most common run command.
- `docker exec -it CONTAINER bash` is how you debug inside a running container.
- `docker stop` sends SIGTERM then SIGKILL; `docker kill` sends SIGKILL immediately. Default to `stop`.
- CMD is overridden by `docker run` arguments; ENTRYPOINT is appended to. Use exec form for both.
- COPY is explicit; ADD has implicit tar extraction and URL fetching. Prefer COPY.
- Stopped containers still exist on disk. `docker rm` deletes them; `--rm` on `docker run` auto-cleans.
