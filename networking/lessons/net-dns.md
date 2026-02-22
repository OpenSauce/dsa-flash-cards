---
title: "DNS: The Internet's Phone Book"
order: 3
reading_time_minutes: 4
summary: "How DNS translates domain names to IP addresses, the resolution hierarchy, caching and TTL, the five key record types, and DNS in production deployments."
---

## Why This Matters

Before your browser can send an HTTP request to `api.example.com`, it needs an IP address. DNS is the system that performs that translation. DNS failures are some of the most impactful outages on the internet -- when DNS is broken, no service is reachable by name. Understanding the resolution chain tells you where to look when things go wrong, how caching shapes propagation times, and how to plan migrations without taking down your service.

## The DNS Hierarchy

DNS is a distributed, hierarchical database. No single server knows all domain names. Instead, the resolution system delegates authority across three tiers:

```
Root servers (.)
  └── TLD servers (.com, .org, .io, .net)
        └── Authoritative nameservers (example.com, myapp.io)
```

**Root servers:** 13 root server clusters (named A through M) scattered globally. They do not know IP addresses of specific domains, but they know which TLD server to ask for any given top-level domain.

**TLD servers:** One set per top-level domain (`.com`, `.org`, `.io`). They know which authoritative nameserver is responsible for each registered domain under that TLD.

**Authoritative nameservers:** Hosted by domain registrars or DNS providers (Cloudflare, Route 53, NS1). They hold the actual records for a domain -- the IP addresses, mail servers, and aliases.

## The Full Resolution Path

When you query a domain that no one in the chain has cached:

```
1. Your app    → OS resolver  (check local cache + /etc/hosts)
2. OS resolver → Recursive resolver  (your ISP or 8.8.8.8)
3. Recursive resolver → Root server  ("which TLD server handles .com?")
4. Recursive resolver → TLD server   ("which nameserver handles example.com?")
5. Recursive resolver → Authoritative server  ("what is the A record for api.example.com?")
6. Recursive resolver → cache answer + return IP to app
```

The **recursive resolver** does the heavy lifting. It walks the hierarchy on your behalf and caches the answer for future queries. In practice, most queries are served from the recursive resolver's cache in under 10ms. The full 5-hop chain only triggers on a cache miss.

## DNS Record Types

| Record | Maps | Example |
|--------|------|---------|
| **A** | Domain → IPv4 address | `api.example.com → 93.184.216.34` |
| **AAAA** | Domain → IPv6 address | `api.example.com → 2606:2800::1` |
| **CNAME** | Domain → another domain (alias) | `blog.example.com → example.github.io` |
| **MX** | Domain → mail server (with priority) | `example.com → mail.example.com (priority 10)` |
| **TXT** | Domain → arbitrary text | SPF, DKIM, domain ownership proofs |

**Important CNAME constraint:** A CNAME record cannot coexist with other records on the same name. You cannot have both `example.com CNAME` and `example.com A` -- they would conflict. This is why you cannot use a CNAME for a zone apex (the root domain like `example.com`), only for subdomains.

**MX priority:** Lower numbers mean higher priority. A mail server with priority 10 is tried before one with priority 20. This lets you configure a primary and a fallback mail server.

**TXT records** handle a wide range of use cases: SPF (which IP addresses are authorized to send email for a domain), DKIM (cryptographic email signing keys), and domain verification (proving you own a domain to Google, AWS, or GitHub).

## TTL: Caching and Propagation

Every DNS record carries a TTL (Time to Live) value -- the number of seconds recursive resolvers should cache the answer before re-querying.

**High TTL (e.g., 86400 = 24 hours):** Cached everywhere. Fast for repeat visitors. But changing the record takes up to 24 hours to propagate worldwide.

**Low TTL (e.g., 60 seconds):** Propagates quickly, but every minute resolvers re-query, slightly increasing DNS server load.

**Migration strategy:**
1. Days before a migration, lower TTL to 60-300 seconds and wait for the old high TTL to expire from all caches worldwide.
2. Switch the DNS record to the new IP.
3. After confirming the new server is healthy, raise TTL back to a normal value.

**Caveat:** Some resolvers enforce a minimum TTL floor (often 30-60 seconds) regardless of what you set. DNS-based failover is never truly instant -- always have a rollback plan that doesn't depend solely on DNS propagation speed.

## Key Takeaways

- DNS is a distributed hierarchy: root servers → TLD servers → authoritative nameservers. The recursive resolver walks this chain on your behalf and caches results.
- A full resolution chain (cache miss) may take 5+ network hops. Cached responses are served in milliseconds.
- A records map domains to IPv4 addresses. AAAA records map to IPv6. CNAME is an alias from one name to another. MX points to mail servers. TXT stores text data used for authentication and verification.
- CNAME records cannot coexist with other records on the same name -- do not use a CNAME at the zone apex.
- TTL controls how long resolvers cache records. Lower TTL before migrations, wait for global propagation, then cut over.
