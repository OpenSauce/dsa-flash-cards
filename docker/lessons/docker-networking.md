---
title: "Docker Networking"
summary: "Bridge, host, and none networking modes, port mapping, container DNS on user-defined networks, and how containers communicate."
reading_time_minutes: 3
order: 4
---

## Why This Matters

Containers need to talk to each other (app to database), to the host (exposing a web server), and sometimes to nothing at all (security-sensitive batch jobs). Docker's networking model controls all of this. Misconfiguring it is a common source of "connection refused" errors and security gaps.

## Networking Modes

Docker provides three main networking modes for single-host deployments.

### Bridge (default)

When you run a container without specifying a network, Docker attaches it to the default `bridge` network. The container gets its own IP address on a private virtual network, isolated from the host's network.

To make a container reachable from outside, you use **port mapping**:

```bash
docker run -p 8080:80 nginx
```

This maps host port 8080 to container port 80. Traffic arriving at `localhost:8080` on the host is forwarded to port 80 inside the container.

**Default bridge limitation:** Containers on the default bridge can communicate by IP address, but not by container name. There is no built-in DNS.

**User-defined bridge networks** fix this. When you create your own bridge network, Docker runs an embedded DNS server that resolves container names to IP addresses:

```bash
docker network create mynet
docker run --name db --network mynet postgres
docker run --name app --network mynet myapp
# Inside "app", you can connect to "db" by name
```

This is how multi-container applications (app + database + cache) communicate. Each service refers to others by container name.

### Host

Host mode removes all network isolation. The container shares the host's network stack directly -- same IP address, same ports, no translation layer.

```bash
docker run --network host nginx
```

Nginx now binds directly to the host's port 80. No `-p` flag needed.

**Use when:** You need maximum network performance (no NAT overhead) or the container must bind to the host's network interface directly.

**Downside:** No port isolation. If two containers both try to bind port 80 in host mode, one fails. You also lose the security benefit of network isolation.

### None

None mode disables all networking. The container has only a loopback interface (`127.0.0.1`). It cannot reach the network and nothing can reach it.

```bash
docker run --network none myapp
```

**Use when:** The workload should have zero network access. Batch processing on local data, cryptographic operations, or any security-sensitive task where network isolation is a requirement.

## Port Mapping Details

The `-p` flag syntax is `HOST_PORT:CONTAINER_PORT`:

```bash
-p 8080:80       # Host 8080 -> Container 80
-p 127.0.0.1:8080:80  # Only bind to localhost (not all interfaces)
-p 8080:80/udp   # UDP instead of TCP
```

Without `-p`, the container's ports are not accessible from the host, even though the process inside is listening. The port exists only on the container's virtual network.

`EXPOSE` in a Dockerfile documents which ports the container listens on, but does not publish them. It is metadata for humans and tooling, not a runtime configuration. You still need `-p` when running the container.

## Container-to-Container Communication

**Same user-defined network:** Containers resolve each other by name via Docker's DNS. This is the standard pattern for multi-container apps.

**Different networks:** Containers on separate networks cannot communicate by default. You can attach a container to multiple networks if it needs to bridge them.

**Default bridge:** Containers can talk by IP but not by name. Avoid using the default bridge for multi-container setups.

## Key Takeaways

- Bridge is the default: containers get private IPs, and you use `-p` to expose ports to the host.
- User-defined bridge networks add DNS resolution by container name. Always use them for multi-container apps.
- Host mode shares the host's network directly. Fast, but no isolation.
- None mode disables networking entirely. Use for security-sensitive workloads.
- `EXPOSE` in a Dockerfile is documentation only -- it does not publish ports.
