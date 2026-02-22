---
title: "System Design Fundamentals"
summary: "How to approach a system design interview: requirements gathering, estimation, high-level architecture, and core building blocks."
reading_time_minutes: 4
order: 1
---

## Why This Matters

System design interviews are open-ended by design. There is no single correct answer, and interviewers are evaluating how you think — not just what you know. Without a structured approach, it is easy to jump to solutions before understanding the problem, miss scale requirements entirely, or get lost in implementation details when you should be drawing a high-level diagram.

This lesson gives you the framework. The remaining lessons in this series cover the individual components that populate that framework.

## The Four-Step Framework

When you receive a system design prompt, work through these four phases in order.

### Step 1: Clarify Requirements (5 minutes)

Never start drawing until you understand what you are building. Requirements divide into two categories:

**Functional requirements** define what the system does:
- What are the core user actions? (post a tweet, upload a photo, place an order)
- What does the system return? (list of results, a URL, a confirmation)
- What is in scope for this interview? (users want to narrow it; do not design everything)

**Non-functional requirements** define how the system must behave:
- **Scale:** How many daily active users? How many requests per second at peak?
- **Latency:** What response time is acceptable? Real-time (< 100ms)? Near real-time (< 1s)?
- **Availability:** 99.9% (8.7 hours downtime per year) or 99.99% (52 minutes)?
- **Consistency:** Can users see stale data, or does every read need the latest write?
- **Durability:** What happens if data is lost? (critical for financial systems, less so for caches)

These non-functional requirements determine which architectural trade-offs you make in every subsequent step.

### Step 2: Estimate Scale (5 minutes)

Back-of-the-envelope estimation sizes your system before you design it. The numbers tell you whether you need one server or one thousand.

**Key metrics to estimate:**
- **QPS (queries per second):** DAU × actions per day / 86,400. 100M DAU × 10 reads/day = ~12,000 QPS at average, ~36,000 at peak (3x average).
- **Storage:** Data per item × items per day × retention period. 1KB per tweet × 500M tweets/day × 365 days = ~178TB/year.
- **Bandwidth:** QPS × average response size.

**Useful numbers to remember:**
- 1 million requests/day ≈ 12 QPS
- 1 billion requests/day ≈ 12,000 QPS
- 100M DAU is a medium-scale service (Slack, Reddit tier)
- 1B DAU is hyperscale (Facebook, YouTube tier)

You do not need exact numbers. You need to know the **order of magnitude** — thousands vs millions vs billions of requests determines whether you need caching, sharding, or CDN.

### Step 3: High-Level Architecture (10 minutes)

Draw the core components and how they connect. Start from the client and trace a request through the system.

**Standard building blocks:**

- **Client:** Browser, mobile app, or external service.
- **Load balancer:** Distributes traffic across backend servers. The first component after the client.
- **Backend servers / API servers:** Process requests, apply business logic.
- **Database:** Persistent storage. Choose relational (strong consistency, structured data) or NoSQL (flexible schema, horizontal scale).
- **Cache:** Fast in-memory store (Redis, Memcached) in front of the database. Reduces latency and database load.
- **CDN:** Distributes static content (images, JS, CSS) geographically close to users.
- **Message queue:** Decouples producers from consumers for async processing (email, notifications, background jobs).
- **Object storage:** Stores large binary files (images, videos, documents). S3 is the archetype.

Not every system needs all of these. A simple CRUD API needs a load balancer, backend servers, and a database. Add caches, queues, and CDNs when you can justify them with scale requirements.

### Step 4: Deep Dives (15 minutes)

After the high-level diagram, the interviewer will ask you to go deeper on specific areas. Common deep dives:

- How does the database scale when you hit 100M writes/day?
- How does the cache prevent thundering herd?
- How do you ensure the message queue delivers every event at least once?
- How do you handle the hot-partition problem when users query popular content?

This is where the knowledge from the rest of this series applies. Load balancing, caching, database scaling, CAP theorem, message queues, API design, and rate limiting are the topics interviewers drill into.

## Core Architectural Patterns

Beyond the building blocks, two high-level architectural patterns come up constantly.

**Monolith:** All functionality in a single deployable unit. Easier to develop, test, and operate. The right starting point for most products. The wrong choice when independent teams need to deploy at different rates or when one feature's load threatens another.

**Microservices:** Functionality split into independently deployable services. Enables independent scaling and deployment. Introduces distributed systems complexity: network calls fail, services go down, transactions span service boundaries.

In an interview, start with a monolith or a simple service split and introduce microservices only when the scale requirements demand it.

## Key Takeaways

- Always start with requirements: functional (what it does) and non-functional (how it must behave). Non-functional requirements drive architectural decisions.
- Estimate scale before drawing. QPS, storage, and bandwidth determine whether you need caching, sharding, and CDNs.
- Draw the high-level architecture first, left to right from client to database. Use standard building blocks.
- Interviewers probe the weak points of your design. Know the deep-dive topics for the components you place.
- Start with a simple design and justify every component you add. Complexity is a cost.
