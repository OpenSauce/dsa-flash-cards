---
title: "HTTP: The Web's Protocol"
order: 4
reading_time_minutes: 5
summary: "HTTP request/response structure, methods and idempotency, status code ranges, and the evolution from HTTP/1.1 to HTTP/2 to HTTP/3 and what each version fixed."
---

## Why This Matters

HTTP is the foundation of the modern web. Every API call, every web page load, every webhook is an HTTP transaction. Understanding HTTP methods, status codes, and headers is table stakes for backend engineering. Understanding the evolution from HTTP/1.1 to HTTP/3 explains why high-traffic systems invest in protocol upgrades -- and what performance problems those upgrades solve.

## Request and Response Structure

An HTTP transaction has two parts: a request from the client and a response from the server.

**Request:**
```
GET /api/users/123 HTTP/1.1
Host: api.example.com
Authorization: Bearer eyJhbG...
Accept: application/json

(empty body for GET)
```

**Response:**
```
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 84

{"id": 123, "name": "Alice", "email": "alice@example.com"}
```

The request line (`GET /api/users/123 HTTP/1.1`) identifies the method, path, and protocol version. Headers follow: key-value pairs that communicate metadata about the request or response. The body (if present) is separated from headers by a blank line.

**Important headers:**
- `Content-Type`: The media type of the body (`application/json`, `text/html`, `multipart/form-data`).
- `Authorization`: Credentials for authenticating the request.
- `Cache-Control`: Directives for caching behavior.
- `Accept`: What content types the client can handle in the response.

## HTTP Methods and Idempotency

HTTP defines several methods (verbs) with specific semantics:

| Method | Purpose | Idempotent | Safe |
|--------|---------|------------|------|
| GET | Retrieve a resource | Yes | Yes |
| POST | Create or trigger an action | No | No |
| PUT | Replace a resource entirely | Yes | No |
| PATCH | Partially update a resource | Not guaranteed | No |
| DELETE | Remove a resource | Yes | No |
| HEAD | Same as GET, headers only | Yes | Yes |
| OPTIONS | Describe allowed methods | Yes | Yes |

**Idempotent** means calling the method multiple times with the same input produces the same result as calling it once. `DELETE /users/123` called twice results in the user being gone -- same outcome. `POST /users` called twice may create two users -- different outcomes.

**Safe** means the method does not modify server state. GET and HEAD are safe; they only read data.

**Why idempotency matters for reliability:** When a network request fails, you often do not know whether the server received it. For idempotent methods, retrying is always safe. For non-idempotent methods (POST), retrying risks duplicate effects -- you need idempotency keys or deduplication logic.

## Status Code Ranges

HTTP status codes are grouped by their first digit:

| Range | Meaning | Common Codes |
|-------|---------|-------------|
| 1xx | Informational | 100 Continue, 101 Switching Protocols |
| 2xx | Success | 200 OK, 201 Created, 204 No Content |
| 3xx | Redirection | 301 Moved Permanently, 302 Found, 304 Not Modified |
| 4xx | Client error | 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 429 Too Many Requests |
| 5xx | Server error | 500 Internal Server Error, 502 Bad Gateway, 503 Service Unavailable |

The range tells you whose fault the error is: 4xx means the client sent something wrong, 5xx means the server failed. This distinction matters for retry logic -- 4xx errors (except 429) are rarely worth retrying; 5xx errors often are.

**Key codes to know:**
- `401 Unauthorized`: Missing or invalid authentication credentials.
- `403 Forbidden`: Authenticated, but not permitted to access this resource.
- `429 Too Many Requests`: Rate limit exceeded.
- `502 Bad Gateway`: The server was acting as a proxy and received an invalid response from upstream.

## HTTP/1.1, HTTP/2, and HTTP/3

HTTP has evolved to solve increasingly subtle performance problems.

### HTTP/1.1 (1997)
- Text-based protocol. Headers are ASCII strings.
- One outstanding request per TCP connection at a time -- **application-layer head-of-line blocking**.
- Workaround: browsers open 6-8 parallel TCP connections per domain, wasting resources.
- Features added over time: persistent connections (keep-alive), chunked transfer encoding, conditional requests (304).

### HTTP/2 (2015)
- **Binary framing.** Headers and data are binary, not text. More compact, faster to parse.
- **Multiplexing.** Multiple requests and responses share a single TCP connection simultaneously, interleaved as frames. No more 6-8 parallel connections needed.
- **Header compression (HPACK).** Repeated headers (like `Authorization`, `User-Agent`) are sent once and indexed -- dramatic reduction for API clients sending many requests.
- **Server push.** Server can proactively send resources before the client asks (rarely used in practice).
- **Still has TCP head-of-line blocking.** A single lost TCP packet stalls all multiplexed streams on that connection until the packet is retransmitted.

### HTTP/3 (2022)
- Runs over **QUIC** instead of TCP. QUIC is built on UDP.
- **Eliminates head-of-line blocking entirely.** Each multiplexed stream is independent at the transport layer. A lost packet in stream A does not stall stream B.
- **Built-in TLS 1.3.** Security is not optional -- QUIC requires encryption. This also means 0-RTT connection establishment for known servers.
- **Connection migration.** When your device switches from Wi-Fi to LTE, the QUIC connection can survive using a Connection ID instead of a (IP, port) tuple that would change.

The progression of HTTP versions solved different problems: HTTP/2 fixed application-layer blocking. HTTP/3 fixed transport-layer blocking.

## Key Takeaways

- An HTTP transaction is a request (method, path, headers, body) and a response (status code, headers, body).
- Idempotent methods (GET, PUT, DELETE, HEAD, OPTIONS) can be retried safely. POST is not idempotent by default.
- Status code ranges: 2xx success, 3xx redirect, 4xx client error (client's fault), 5xx server error (server's fault).
- HTTP/1.1: text-based, one request per TCP connection at a time.
- HTTP/2: binary multiplexing over one TCP connection, but still has TCP head-of-line blocking.
- HTTP/3: runs over QUIC (UDP), eliminates head-of-line blocking, includes built-in TLS 1.3.
