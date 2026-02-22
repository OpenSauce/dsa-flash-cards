---
title: "API Design and Communication Patterns"
summary: "REST principles, HTTP methods and status codes, pagination, idempotency, GraphQL vs REST, gRPC for internal services, webhooks, and API versioning."
reading_time_minutes: 5
order: 7
---

## Why This Matters

APIs are contracts. They define how services communicate with clients and with each other. A poorly designed API is expensive to fix: clients have already built around it, and breaking changes break their integrations. In system design interviews, interviewers expect you to know how to design a clean API for the system you are proposing, including which communication style fits the use case and how to handle evolution over time.

## REST Principles

REST (Representational State Transfer) is the dominant architectural style for web APIs. A REST API:

- **Uses HTTP methods with their intended semantics** -- GET to read, POST to create, PUT/PATCH to update, DELETE to remove
- **Addresses resources with URLs** -- `/users/123` represents user 123, not `/getUser?id=123`
- **Is stateless** -- each request contains all information needed to process it; the server holds no client session state between requests
- **Returns representations** -- the server returns a representation of the resource (usually JSON), not a procedure call result

These constraints give REST APIs predictability. Any developer who knows HTTP knows how to interact with a REST API without reading documentation for every call.

## HTTP Methods and Status Codes

### Methods

| Method | Purpose | Idempotent? | Safe? |
|--------|---------|-------------|-------|
| GET | Read a resource | Yes | Yes |
| POST | Create a resource | No | No |
| PUT | Replace a resource | Yes | No |
| PATCH | Partially update | No | No |
| DELETE | Remove a resource | Yes | No |

**Idempotent** means calling it N times has the same effect as calling it once. GET, PUT, and DELETE are idempotent. POST is not -- submitting a form twice creates two orders.

**Safe** means the call has no side effects. GET is safe (reading does not change state). All writes are unsafe.

### Status Codes

Know the common codes and what they signal:

- **200 OK** -- success for GET, PUT, PATCH
- **201 Created** -- success for POST that creates a resource; include a `Location` header with the new resource URL
- **204 No Content** -- success for DELETE; no body needed
- **400 Bad Request** -- client sent malformed input (missing required field, invalid format)
- **401 Unauthorized** -- not authenticated (no token or invalid token)
- **403 Forbidden** -- authenticated but not authorized for this resource
- **404 Not Found** -- resource does not exist
- **409 Conflict** -- request would create a conflict (duplicate key, optimistic lock failure)
- **422 Unprocessable Entity** -- input is syntactically valid but semantically invalid (invalid enum value, date in the past)
- **429 Too Many Requests** -- rate limit exceeded
- **500 Internal Server Error** -- something broke on the server
- **503 Service Unavailable** -- server is overloaded or down for maintenance

## Pagination

APIs that return lists must support pagination. Returning 10 million rows in one response is not viable.

### Offset Pagination

`GET /posts?limit=20&offset=40` -- skip 40 results, return the next 20.

Simple to implement and understand. Supports jumping to any page directly.

**Problem:** If items are inserted or deleted while a user pages through, pages shift. Items appear twice or are skipped. Becomes slow on large offsets because the database must scan and discard the offset rows.

### Cursor-Based Pagination

`GET /posts?limit=20&after=cursor_abc` -- return 20 items after the item identified by `cursor_abc`.

The cursor is typically an encoded form of the last item's sort key (ID or timestamp). The query becomes `WHERE id > cursor_value LIMIT 20`.

**Advantages:** Consistent even when items are inserted or deleted. Efficient -- no scanning of skipped rows. Works well for real-time feeds.

**Trade-off:** Cannot jump to page 5 directly. Only forward (and sometimes backward) navigation.

Use cursor-based pagination for real-time feeds and large datasets. Offset pagination is acceptable for admin UIs where data is stable and datasets are small.

## Idempotency

An operation is idempotent if performing it multiple times produces the same result as performing it once.

**Why it matters for APIs:** Networks are unreliable. A client sends a POST request, the server processes it, but the response is lost. The client retries. Without idempotency, the server creates two resources.

**Idempotency keys:** Clients generate a unique key per logical operation (a UUID) and include it in the request header. The server stores the key and its response. On a duplicate request (same key), the server returns the stored response without re-executing the operation.

This is critical for financial operations: charging a credit card twice because of a retry is a serious bug.

## GraphQL vs REST

### REST

Fixed endpoints, each returning a defined shape. Simple and widely understood.

**Over-fetching:** Endpoint returns more fields than the client needs. A mobile app endpoint returns 30 fields when the client uses 5.

**Under-fetching:** One endpoint does not return enough data. Client must call multiple endpoints and join the results.

### GraphQL

Clients specify exactly what fields they need in a query. The server returns exactly that shape. One endpoint, flexible responses.

**Strengths:**
- Eliminates over-fetching and under-fetching
- Strongly typed schema serves as documentation
- Excellent for complex product UIs with many data relationships (social graphs, product pages with many related entities)

**Weaknesses:**
- Complex to implement and cache (no URL-based caching; queries are POST bodies)
- N+1 query problem: fetching a list of users with their posts can cause one DB query per user without careful optimization (DataLoader pattern solves this)
- Overkill for simple CRUD APIs

**When to choose:** GraphQL fits product APIs consumed by varied clients (mobile, web, third-party) with different data needs. REST fits simpler APIs, public developer APIs, and microservice-to-microservice communication.

## gRPC

gRPC is a remote procedure call framework that uses Protocol Buffers (protobuf) for serialization and HTTP/2 for transport.

**Strengths over REST:**
- Protobuf is smaller and faster to serialize than JSON (~3-10x reduction in payload size)
- HTTP/2 multiplexes multiple calls over one connection and supports server-side streaming
- Strongly typed interfaces enforce contracts between services
- Code generation produces client and server stubs in multiple languages

**Use for:** Internal service-to-service communication where performance and type safety matter. Not ideal for public APIs (browser support for gRPC is limited without a proxy layer).

## Webhooks

A webhook is a reverse API call: instead of the client polling for updates, the server calls the client's URL when an event occurs.

**Pattern:** The client registers a URL with the server. When an event happens (payment processed, CI build completed, order shipped), the server sends an HTTP POST to that URL with event data.

**Advantage over polling:** No wasted requests. The client only receives data when something happens.

**Challenges:** The client's server must be publicly reachable. Delivery is not guaranteed (if the client's server is down, the event may be lost -- require the sender to retry with exponential backoff). The client should verify the request came from the expected sender (HMAC signature).

## API Versioning

APIs change over time. Versioning strategies:

**URL versioning** (`/v1/users`, `/v2/users`): Explicit and visible. Easy to route, test, and cache separately. Clients can pin to a version. Requires maintaining multiple versions simultaneously.

**Header versioning** (`Accept: application/vnd.api+json;version=2`): Keeps URLs clean. Harder to test in a browser or curl without extra headers.

**Additive changes are not breaking:** Adding new fields to a response does not break existing clients. Removing or renaming fields does. Design APIs to be extensible: never remove required fields, use nullable new fields with defaults, deprecate before removing.

## Key Takeaways

- REST uses HTTP methods semantically and addresses resources by URL. Design around resources, not operations.
- Know the HTTP status codes: 201 for creation, 401 vs 403 for auth errors, 429 for rate limiting.
- Use cursor-based pagination for large or real-time datasets; offset pagination for small stable datasets.
- Idempotency keys prevent duplicate operations on retry. Critical for financial and side-effectful operations.
- GraphQL eliminates over/under-fetching but adds complexity. Use it when clients have varied data needs. Use gRPC for internal services.
- Webhooks push events to clients; clients must be reachable and handle retries.
