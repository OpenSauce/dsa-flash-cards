---
title: "Load Balancing"
summary: "How load balancers distribute traffic, the major algorithms and their trade-offs, L4 vs L7 operation, health checks, and session affinity."
reading_time_minutes: 5
order: 2
---

## Why This Matters

Every production web application sits behind a load balancer. When an interviewer asks you to design a system that handles millions of requests, the load balancer is the first component you draw after the client. Understanding how they work -- not just that they exist -- separates a surface-level answer from a convincing one.

## What a Load Balancer Does

A load balancer sits between clients and a pool of backend servers. It accepts incoming requests and distributes them across servers based on an algorithm. The client talks only to the load balancer; it never knows which backend server actually handled the request.

Beyond traffic distribution, load balancers handle:

- **Health checking:** Detecting failed servers and removing them from the pool
- **SSL termination:** Decrypting HTTPS at the load balancer so backends handle plain HTTP
- **Connection management:** Reusing connections to backends, shielding them from the overhead of thousands of individual client connections

## Load Balancing Algorithms

### Round Robin

Requests go to servers in rotation: A, B, C, A, B, C. No state tracking required.

**Works when:** Servers have equal capacity and requests have similar cost.

**Breaks when:** Servers have different specs (a 2-core machine gets the same share as a 16-core machine) or requests have wildly different durations (a reporting query gets the same weight as a health check).

### Weighted Round Robin

Same rotation, but servers with more capacity get proportionally more turns. If server A has weight 3 and server B has weight 1, A handles 3 out of every 4 requests.

**Use when:** Your servers are heterogeneous -- different instance sizes, different hardware generations.

### Least Connections

Each new request goes to the server with the fewest active connections. This naturally accounts for both server capacity and request duration: fast servers finish requests sooner and free up connection slots.

**Use when:** Request processing times vary widely. A single slow query does not pile more work onto an already-loaded server.

### IP Hash

The client's IP address is hashed to deterministically select a server. The same client always reaches the same backend.

**Use when:** You need simple session affinity without cookies. Common in caching layers where you want a given client's requests to hit the same cache.

**Downside:** Adding or removing a server remaps most clients. Consistent hashing mitigates this.

### Least Response Time

Routes to the server currently responding fastest. Combines connection count with measured latency.

**Use when:** Latency-sensitive applications where you want to actively avoid the slowest node, not just the busiest one.

## L4 vs L7 Load Balancing

Load balancers operate at different network layers, and the layer determines what information is available for routing decisions.

### Layer 4 (Transport)

An L4 load balancer sees TCP or UDP packets. It routes based on **source/destination IP and port** only. It cannot inspect the request payload -- it does not know the URL, headers, or cookies.

**Characteristics:**
- Extremely fast -- it forwards packets with minimal processing
- Protocol-agnostic -- works for HTTP, gRPC, database connections, or any TCP/UDP traffic
- No SSL termination (the encrypted payload passes through untouched)

**Examples:** AWS Network Load Balancer (NLB), HAProxy in TCP mode.

### Layer 7 (Application)

An L7 load balancer parses the full HTTP request. It can route based on **URL path, headers, cookies, query parameters, and request body**.

**Characteristics:**
- Content-aware routing: send `/api/*` to backend servers and `/static/*` to a CDN origin
- SSL termination: decrypt HTTPS, inspect the request, then forward plain HTTP to backends
- Request rewriting, header injection, rate limiting, and authentication at the edge
- Higher latency than L4 because it must read and parse the full request

**Examples:** AWS Application Load Balancer (ALB), Nginx, Envoy, Cloudflare.

### Choosing Between Them

Most web applications use L7 because they need content-aware routing, SSL termination, or both. Choose L4 when you need raw throughput for non-HTTP protocols or when the overhead of request parsing is unacceptable (gaming servers, real-time streaming).

## Health Checks

A load balancer is only useful if it stops sending traffic to dead servers. Health checks are how it knows.

### Active Health Checks

The load balancer periodically sends a probe to each server -- an HTTP GET to `/health`, a TCP connect, or a custom check. If a server fails a configurable number of consecutive probes, the load balancer marks it unhealthy and stops routing traffic to it.

### Passive Health Checks

The load balancer monitors real traffic. If a server returns too many 5xx errors or timeouts within a time window, it is pulled from the pool. No extra probe traffic required, but detection is slower because it depends on real requests.

Most production setups use both: active checks for quick detection of full outages, passive checks for catching degraded performance.

### Recovery

An unhealthy server is not permanently removed. The load balancer continues probing it, and once it passes health checks again, it is added back to the pool -- often with a gradual ramp-up to avoid overwhelming it with a sudden traffic spike.

## Session Affinity (Sticky Sessions)

Some applications store user state in server memory (login sessions, shopping carts). If the load balancer sends a user's second request to a different server, that state is lost.

**Sticky sessions** solve this by binding a user to a specific server for the duration of their session. Two common implementations:

- **Cookie-based:** The load balancer injects a cookie identifying the target server. Subsequent requests include this cookie, and the load balancer routes accordingly.
- **IP hash:** The client's IP is hashed to a server. Simple but breaks when clients share an IP (corporate NATs) or switch networks (mobile users).

### The Trade-Off

Sticky sessions keep stateful apps working, but they undermine the load balancer's ability to distribute load evenly. A server handling a popular session gets disproportionate traffic. Worse, if that server goes down, the session state is lost -- there is no failover.

The standard recommendation in system design interviews: **externalize session state** to Redis or a database. This makes all backend servers stateless and interchangeable, and the load balancer can distribute traffic freely.

## Key Takeaways

- Round robin is the simplest algorithm but assumes equal servers and equal request cost. Least connections adapts to real-time load.
- L4 load balancers route by IP/port and are fast but blind to request content. L7 load balancers parse HTTP and enable content-aware routing at higher overhead.
- Health checks (active and passive) detect failed servers. Always mention them when discussing load balancers in an interview.
- Sticky sessions are a crutch for stateful servers. Externalizing state to a shared store is the production-grade approach.
- The load balancer is typically the first thing you draw in a system design diagram, right after the client.
