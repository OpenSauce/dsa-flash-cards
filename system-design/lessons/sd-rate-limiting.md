---
title: "Rate Limiting and Throttling"
summary: "Why rate limiting matters, token bucket, leaky bucket, fixed and sliding window algorithms, where to enforce limits, HTTP 429, and distributed rate limiting with Redis."
reading_time_minutes: 4
order: 8
---

## Why This Matters

Without rate limiting, any user can exhaust your API, database, or downstream services. DDoS attacks, runaway scrapers, and buggy clients can take down a system with no malicious intent. Rate limiting is the first line of defense and a standard topic in system design interviews -- especially for public APIs, user-facing services, and any system where abuse is a realistic concern.

## Why Rate Limit?

Three primary motivations:

**Abuse prevention:** Stop scrapers, brute-force login attempts, and DDoS attacks. An attacker sending 10,000 requests per second is rate-limited before causing damage.

**Cost control:** Downstream services (LLM APIs, SMS providers, payment processors) charge per call. Rate limiting prevents runaway clients from generating unexpected costs.

**Fairness:** In a multi-tenant system, one heavy user should not consume resources at the expense of others. Rate limiting ensures each user gets a proportional share.

## Rate Limiting Algorithms

### Token Bucket

Each user has a bucket with a maximum capacity of N tokens. Tokens refill at a constant rate (e.g., 10 tokens per second). Each request consumes one token. If the bucket is empty, the request is rejected.

**Key property:** Allows bursting up to N requests at once (if the bucket is full), then enforces a steady rate afterward.

**Use when:** You want to allow short bursts while enforcing a long-term average rate. Common for API rate limiting (allow a burst of 100 requests, then 10 per second).

**Implementation:** Store `(token_count, last_refill_time)` per user. On each request, calculate tokens earned since last refill, cap at bucket size, subtract 1 if tokens > 0.

### Leaky Bucket

Requests enter a queue (the bucket). They are processed at a fixed, constant output rate -- like water leaking from a bucket at a steady drip. If the bucket (queue) is full, new requests are dropped.

**Key property:** Output rate is perfectly smooth -- exactly N requests per second, regardless of input bursts.

**Use when:** Downstream services need a constant, predictable input rate. Useful for smoothing traffic spikes before they hit a database or a payment processor.

**Difference from token bucket:** Token bucket allows bursts to pass through; leaky bucket absorbs bursts and smooths them out.

### Fixed Window Counter

Divide time into fixed windows (e.g., one minute each). Count requests per user in the current window. Reject requests when the count exceeds the limit.

**Simple to implement.** One counter per (user, window) stored in Redis with a TTL.

**Edge case problem:** A user can send the limit at the end of one window and the limit again at the start of the next. This doubles the effective rate for that two-second window. A user limited to 100 requests/minute can send 200 in a two-second window straddling the boundary.

### Sliding Window Log

Record the timestamp of each request. On each new request, remove timestamps older than the window (e.g., older than 60 seconds), count remaining timestamps, and reject if the count exceeds the limit.

**Precise:** No boundary artifact. The window always looks back exactly N seconds from now.

**Memory cost:** Must store one timestamp per request. For a user allowed 10,000 requests/hour, that is up to 10,000 stored timestamps.

### Sliding Window Counter

A hybrid: combine the previous window's count (weighted by how much of that window overlaps the current sliding window) with the current window's count.

**Approximation of sliding window log** with much lower memory. One counter per window, not one timestamp per request. Accurate enough for most use cases.

## Where to Rate Limit

**API gateway layer:** Rate limit before requests reach application servers. The gateway has global visibility across all instances and can enforce limits without application code changes. AWS API Gateway, Kong, and Nginx all support rate limiting.

**Application layer:** Fine-grained, business-logic-aware limits. Limit specific endpoints differently (login attempts vs. search queries). Easier to express complex rules (per user tier, per operation type).

**Client-side throttling:** An SDK or library throttles itself before hitting the API. Reduces wasted requests but cannot be trusted for security -- only for well-behaved clients.

Most production systems apply limits at the API gateway for global protection and at the application layer for per-feature granularity.

### Per-User vs Per-IP Rate Limiting

**Per-IP:** Simple, no authentication required. Works for unauthenticated endpoints (login, signup). Breaks down when users share an IP (corporate NATs, university networks) -- one abusive user blocks everyone on that IP.

**Per-user:** Requires authentication. More precise and fair. Cannot protect unauthenticated endpoints.

**Both:** A best practice for APIs that have both authenticated and unauthenticated flows. Per-IP limits protect login/signup; per-user limits protect authenticated APIs.

## HTTP 429 and Retry-After

When a client is rate limited, the server returns HTTP **429 Too Many Requests**.

Include a `Retry-After` header telling the client when to retry:

```
HTTP/1.1 429 Too Many Requests
Retry-After: 30
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1700000060
```

Well-behaved clients read `Retry-After` and back off. Without it, clients immediately retry, generating more rejected requests and wasting both sides' resources.

## Distributed Rate Limiting with Redis

A single server can rate limit its own traffic with in-memory counters. Across multiple servers, each server sees only its own fraction of traffic and cannot enforce a global limit.

**The solution:** Use Redis as a shared counter store. All rate-limiting checks go through Redis.

**Pattern:**
1. On each request, call `INCR user:123:window:1700000` (atomic increment for user 123 in the current time window)
2. Set `EXPIRE` on the key for the window duration (so old windows are cleaned up automatically)
3. If the returned count exceeds the limit, return 429

Redis's atomic `INCR` prevents race conditions: two servers incrementing simultaneously cannot both see a count below the limit and both allow the request through.

**Lua scripting:** For the sliding window algorithm, use a Redis Lua script to atomically check-and-increment in one round trip.

## Key Takeaways

- Rate limiting prevents abuse, controls costs, and enforces fairness. Always include it in designs for public APIs.
- Token bucket allows bursting, then enforces a steady rate. Leaky bucket produces a constant output rate, absorbing bursts.
- Fixed window is simple but has a boundary artifact. Sliding window log is precise but memory-intensive. Sliding window counter is a practical approximation.
- Rate limit at the API gateway for global protection. Add application-layer limits for per-feature control.
- Distributed systems need shared state (Redis) for rate limiting. In-memory counters only see a fraction of total traffic.
- Return HTTP 429 with a `Retry-After` header so clients know when to retry.
