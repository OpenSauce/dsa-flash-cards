---
title: "APIs, Proxies, and Real-Time Communication"
order: 6
reading_time_minutes: 5
summary: "REST vs gRPC, forward vs reverse proxies, WebSocket vs long-polling vs SSE, CORS and the same-origin policy, and how these fit together in modern architectures."
---

## Why This Matters

HTTP gives you a transport. What you build on top of it -- how you structure APIs, where you place proxies, how you push data to clients -- defines your system's architecture. REST, gRPC, forward proxies, reverse proxies, WebSockets, SSE, and CORS are all patterns that appear in every real system design conversation. Understanding when to use each, and why, distinguishes engineers who have thought through trade-offs from those who reach for the familiar.

## REST vs gRPC

Both REST and gRPC are API styles for service-to-service communication, but they make very different choices.

**REST (Representational State Transfer):**
- Runs over HTTP/1.1 or HTTP/2, JSON payloads (typically)
- Resource-oriented: URLs are nouns (`/users/123`, `/orders/456`)
- Stateless: each request contains all needed context
- Human-readable: easy to debug with a browser or `curl`
- Universally supported -- every language, every platform
- No built-in streaming (workarounds: Server-Sent Events, chunked encoding)

**gRPC:**
- Runs over HTTP/2 exclusively, Protocol Buffer payloads (binary)
- Method-oriented: defined in `.proto` files (`GetUser`, `StreamOrders`)
- Auto-generates client and server stubs in any language from the `.proto` definition
- Four call types: unary (single request/response), server-streaming, client-streaming, bidirectional streaming
- 2-10x more compact than JSON due to binary encoding, faster to serialize/deserialize
- Harder to debug (binary, not human-readable); requires gRPC-aware infrastructure

**When to choose REST:** Public APIs, browser clients (gRPC-web adds complexity), simple CRUD services, anything where debuggability and broad tooling matter.

**When to choose gRPC:** Internal microservice communication where latency and throughput are critical, polyglot service meshes (generated stubs eliminate manual client code), and workloads requiring bidirectional streaming.

Many organizations use both: REST for external-facing APIs, gRPC for internal service-to-service communication.

## Forward Proxies and Reverse Proxies

Proxies sit between clients and servers, but they face different directions.

**Forward proxy:** Sits in front of clients. The client sends all requests through the forward proxy, which forwards them to the internet. The destination server sees the proxy's IP, not the client's.

```
Client → [Forward Proxy] → Internet → Server
```

Use cases: corporate internet gateways (content filtering, logging), bypassing geo-restrictions, anonymizing client traffic.

**Reverse proxy:** Sits in front of servers. External clients send requests to the reverse proxy, which routes them to the appropriate backend. The client never knows the backend servers' addresses.

```
Client → Internet → [Reverse Proxy] → Backend servers
```

Use cases: load balancing (distributing requests across multiple servers), TLS termination (the proxy handles HTTPS so backend servers see plain HTTP), caching, DDoS protection, and A/B routing.

**The key distinction:** A forward proxy hides the client from the server. A reverse proxy hides the servers from the client.

In system design, "add a reverse proxy" almost always means Nginx, HAProxy, Envoy, or a cloud load balancer that handles TLS termination and distributes load.

## Real-Time Communication: WebSocket, Long-Polling, SSE

Standard HTTP is request-response: the client asks, the server answers, the connection closes. But many applications need the server to push data to clients without waiting for a request. Three patterns handle this:

**HTTP Long-Polling:**
1. Client sends a request.
2. Server holds the connection open until new data is available (or a timeout occurs).
3. Server responds with the data. Client immediately sends a new request.

Works with any HTTP infrastructure. High overhead -- each exchange involves full HTTP headers, and frequent reconnections add latency. No true bidirectionality (each direction is a separate request/response cycle).

**WebSocket:**
After a standard HTTP upgrade handshake (`GET /ws` + `101 Switching Protocols`), the connection becomes a persistent, full-duplex TCP channel. Either side can send messages at any time with minimal framing overhead (2-14 bytes per frame instead of HTTP's kilobytes of headers).

True bidirectional communication with low per-message overhead. Requires WebSocket-aware infrastructure (some proxies need explicit configuration). Does not auto-reconnect on failure.

**Server-Sent Events (SSE):**
A persistent HTTP connection where the server streams data in a text-based event format. The client opens one connection and receives events indefinitely. Client-to-server communication still uses separate HTTP requests.

Simpler than WebSocket when you only need server-to-client push. Works over standard HTTP/2 multiplexing. Auto-reconnects on failure (built into the EventSource browser API). Not suitable for bidirectional real-time communication.

**Decision guide:**
- Server-push only (feeds, notifications, dashboards): **SSE**
- Bidirectional real-time (chat, gaming, collaborative editing): **WebSocket**
- Constrained environments (proxies that strip WebSocket): **Long-polling as a fallback**

## CORS and the Same-Origin Policy

Browsers enforce the **same-origin policy**: JavaScript on `app.example.com` cannot make requests to `api.other.com` by default. An origin is the combination of scheme, host, and port -- `https://app.example.com:443` is one origin, `https://api.example.com:443` is a different origin (different subdomain).

Without this restriction, a malicious page could silently fetch your bank data using your browser's stored cookies for the bank's domain.

**CORS (Cross-Origin Resource Sharing)** is the controlled exception. Servers opt in by setting response headers that tell the browser which origins are trusted:

```
Access-Control-Allow-Origin: https://app.example.com
Access-Control-Allow-Methods: GET, POST, PUT
Access-Control-Allow-Headers: Authorization, Content-Type
```

**Preflight requests:** For "complex" requests (PUT, DELETE, custom headers, `Content-Type: application/json`), the browser first sends an OPTIONS request to ask permission. Only if the server responds with the right CORS headers does the browser send the actual request. This preflight adds a round trip -- use it for non-simple requests.

**Important distinctions:**
- CORS is a browser enforcement mechanism. `curl` and server-to-server requests ignore it entirely.
- `Access-Control-Allow-Origin: *` cannot be combined with `Access-Control-Allow-Credentials: true` -- browsers reject this combination because it would allow any origin to read credentialed responses.
- Setting CORS on your API is not a security measure for non-browser clients. It only controls what browser-side JavaScript can access.

## Key Takeaways

- REST is resource-oriented, JSON/HTTP, universally supported, human-readable. gRPC is method-oriented, binary/HTTP2, high-performance, with code generation from `.proto` files. Use REST externally, gRPC internally when performance matters.
- Forward proxy hides the client from servers. Reverse proxy hides servers from the client. Reverse proxies handle load balancing, TLS termination, and caching.
- WebSocket: bidirectional, persistent, low overhead per message. SSE: server-to-client push, simpler, auto-reconnects. Long-polling: works everywhere, high overhead, use as a fallback.
- The same-origin policy prevents JavaScript from reading cross-origin responses. CORS lets servers opt in to cross-origin access via response headers.
- CORS is enforced by browsers only -- it does not protect against server-to-server or `curl` requests.
