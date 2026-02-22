---
title: "Docker Compose"
summary: "Defining multi-container applications with a single YAML file, core Compose concepts (services, networks, volumes), and when Compose is enough vs when you need Kubernetes."
reading_time_minutes: 4
order: 6
---

## Why This Matters

Real applications are rarely a single container. A web app needs a database, maybe a cache, maybe a message queue. Starting each container individually with long `docker run` commands, wiring up networks and volumes by hand, and remembering the correct flags every time is tedious and error-prone. Docker Compose solves this by defining your entire application stack in one file and managing it with a single command.

## What Is Docker Compose?

Docker Compose is a tool for defining and running multi-container applications. You describe your services, networks, and volumes in a YAML file, and Compose creates and manages them as a unit.

```yaml
services:
  app:
    build: .
    ports:
      - "8080:80"
    depends_on:
      - db
    environment:
      DATABASE_URL: postgres://db:5432/myapp
  db:
    image: postgres:16
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: secret

volumes:
  pgdata:
```

`docker compose up` starts both services. `docker compose down` stops and removes them. One command replaces a half-dozen `docker run` invocations.

## Core Concepts

### Services

A service is a container definition. Each service specifies either a pre-built image (`image: postgres:16`) or a build context (`build: .`), plus configuration like ports, environment variables, volumes, and dependencies.

Compose creates a container for each service, named `{project}-{service}-1` by default. The project name comes from the directory name or can be set with `-p`.

### Networking

Compose automatically creates a **user-defined bridge network** for the project. All services are attached to it. This means every service can reach every other service **by its service name** -- Docker's embedded DNS handles resolution.

In the example above, the `app` service connects to the database at hostname `db` on port 5432. No IP addresses, no manual network creation.

You can define additional networks for isolation (e.g., a frontend network and a backend network), but the default single network covers most use cases.

### Volumes

Named volumes declared in the top-level `volumes:` block are created and managed by Compose. They persist across `docker compose down` unless you pass `--volumes` (or `-v`):

```bash
docker compose down           # Stops containers, removes network. Volumes preserved.
docker compose down -v        # Also deletes named volumes. Data is gone.
```

### depends_on

`depends_on` controls **startup order**, not readiness. `depends_on: [db]` ensures the `db` container starts before `app`, but it does not wait for Postgres to accept connections. The application must handle connection retries on its own (or use a health check condition).

```yaml
depends_on:
  db:
    condition: service_healthy
```

With a `healthcheck` defined on the `db` service, this waits until the database is actually ready.

## Essential Commands

```bash
docker compose up             # Create and start all services (foreground)
docker compose up -d          # Start in detached mode (background)
docker compose up --build     # Rebuild images before starting
docker compose down           # Stop and remove containers + network
docker compose ps             # List running services
docker compose logs -f app    # Follow logs for a specific service
docker compose exec app bash  # Shell into a running service container
docker compose build          # Build/rebuild images without starting
```

## The Compose File

The default file name is `compose.yaml` (preferred) or `docker-compose.yml` (legacy but still supported). Compose v2 ignores the `version:` top-level key -- you no longer need to specify it.

### Common Service Options

```yaml
services:
  app:
    image: myapp:latest           # Use a pre-built image
    build: ./app                  # OR build from a Dockerfile
    ports:
      - "8080:80"                 # Port mapping (host:container)
    volumes:
      - ./src:/app/src            # Bind mount for development
      - appdata:/app/data         # Named volume for persistence
    environment:
      NODE_ENV: production        # Set environment variables
    env_file:
      - .env                      # Load from file
    restart: unless-stopped       # Restart policy
    depends_on:
      - db                        # Startup ordering
```

### Profiles

Profiles let you selectively start services. A service with `profiles: [debug]` only starts when you run `docker compose --profile debug up`. This is useful for development-only services (pgAdmin, debug tools) that should not run in production.

## Compose vs Kubernetes

This is a common interview question with a clean answer.

**Compose is for single-host orchestration.** It runs all containers on one machine, has no concept of scaling across nodes, and provides no automatic failover or self-healing. It is simple, fast, and sufficient for local development, CI environments, and small self-hosted deployments.

**Kubernetes is for multi-host orchestration.** It schedules containers across a cluster of machines, provides auto-scaling, rolling updates, self-healing (restarting failed containers), service discovery, and load balancing. It is complex, has a steep learning curve, and is designed for production workloads that demand high availability.

**The dividing line:** If your application runs on a single server and you do not need automatic recovery from node failure, Compose is simpler. Once you need to scale across multiple machines or require production-grade resilience, Kubernetes is the tool.

## Key Takeaways

- Docker Compose defines multi-container applications in a single YAML file and manages them as a unit.
- Compose automatically creates a bridge network where services discover each other by name.
- `depends_on` controls startup order but does not guarantee the dependency is ready. Use health checks for that.
- `docker compose down` removes containers and networks but preserves volumes. Add `-v` to delete volumes too.
- Compose is for single-host orchestration. Kubernetes is for multi-host orchestration with auto-scaling and self-healing.
