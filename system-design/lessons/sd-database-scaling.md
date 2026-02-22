---
title: "Database Scaling"
summary: "Vertical vs horizontal scaling, leader-follower replication, sharding strategies, consistent hashing with virtual nodes, and connection pooling."
reading_time_minutes: 5
order: 4
---

## Why This Matters

Almost every system design interview question eventually hits the database. A single database server has finite capacity -- at some point it cannot accept more reads, more writes, or more data. Knowing when and how to scale the database is one of the most important skills in system design.

## Vertical vs Horizontal Scaling

The first scaling decision is the simplest.

**Vertical scaling (scale up):** Replace the server with a larger one. More CPU, more RAM, faster disks. No application changes required.

**Horizontal scaling (scale out):** Add more servers. Distribute data or load across them.

Start vertical. A single powerful machine is simpler to operate, easier to query (no distributed joins), and cheap. Scale vertically until you hit a hardware limit or a failure tolerance requirement. Then scale horizontally.

The ceiling on vertical scaling is real: the largest cloud database instance has 96 vCPUs and 384GB RAM. If your workload exceeds that, horizontal scaling is mandatory.

## Leader-Follower Replication

The most common horizontal scaling pattern for read-heavy workloads.

**How it works:** One leader (primary) accepts all writes. Multiple followers (replicas) replicate the leader's changes and serve read queries. The application routes writes to the leader and reads to any follower.

**What it solves:** Read scalability. Most web applications are 90%+ reads. Adding followers distributes the read load without changing the write path.

**Replication lag:** Followers replicate asynchronously. There is a window -- typically milliseconds -- where a follower has not yet applied the leader's latest change. A read from a follower during this window returns slightly stale data.

For most use cases, replication lag is acceptable. For cases where it is not (checking your account balance immediately after a transfer), route that specific query to the leader.

**Failover:** If the leader dies, a follower must be promoted. Automated failover systems (Patroni for PostgreSQL, MySQL Group Replication) detect leader failure and elect a new leader. Writes that the leader accepted but had not yet replicated are lost. This is the durability trade-off of async replication.

## Database Sharding

Sharding splits data across multiple independent database servers. No single machine stores all the data.

### Range-Based Sharding

Divide data by a natural range. Users A-M go to shard 1, N-Z to shard 2. Or user IDs 1-1M go to shard 1, 1M-2M to shard 2.

**Simple to implement.** Range queries (all users from A to F) hit a single shard.

**Hotspot risk:** If most users have names starting with A-M, shard 1 is overloaded. Range sharding assumes data is uniformly distributed -- it often is not.

### Hash-Based Sharding

Apply a hash function to the shard key: `shard = hash(user_id) % N`. The hash distributes data evenly regardless of key distribution.

**Uniform distribution** eliminates hotspots.

**Naive modulo problem:** When you add a shard (N changes to N+1), nearly every key maps to a different shard. Adding a server triggers a massive data migration.

### Directory-Based Sharding

A lookup table maps each key (or key range) to a shard. The lookup table is consulted on every request.

**Maximum flexibility.** You can move individual keys between shards at will.

**Single point of failure:** The lookup table is a bottleneck and a failure point. Caching the directory mitigates latency, but cache invalidation adds complexity.

## Consistent Hashing

Consistent hashing solves the modulo problem for hash-based sharding.

**The ring:** Map both servers and keys onto a circular hash space (0 to 2³²). Each key is assigned to the nearest server clockwise on the ring.

**Adding a server:** Only keys between the new server and its predecessor move. All other keys stay put. On average, only K/N keys move (K = total keys, N = servers). Naive modulo moves (N-1)/N keys.

**Removing a server:** Only its keys move to the next server clockwise. All other keys are unaffected.

### Virtual Nodes

With few servers on the ring, the distribution is uneven -- some servers own larger arc segments and handle more keys than others.

Virtual nodes give each physical server multiple positions on the ring (typically 150+). These positions are spread evenly across the hash space, so no single server dominates.

Benefits:
- **Even load distribution** across servers with different arc sizes
- **Smoother rebalancing** when a server is added: load shifts away from many existing servers, not just the immediate neighbor
- **Heterogeneous capacity:** Assign more virtual nodes to more powerful servers

Cassandra, DynamoDB, and Redis Cluster all use consistent hashing with virtual nodes.

## Connection Pooling

Opening a database connection is expensive: TCP handshake, authentication, SSL negotiation, server-side memory allocation. Without pooling, a service handling 1,000 requests/second attempts to open 1,000 connections/second. Most databases cap connections at 100-500.

**A connection pool** keeps a fixed set of connections open and reuses them across requests. A request borrows a connection, executes its query, and returns the connection to the pool.

Pool size is tunable. Too small and requests queue waiting for a connection. Too large and you exhaust the database's connection limit.

Common tools: PgBouncer (PostgreSQL), HikariCP (Java), SQLAlchemy pool (Python).

## Key Takeaways

- Start vertical, scale horizontal when you hit limits. Vertical is simpler and cheaper until it is not.
- Leader-follower replication solves read scalability. Know the replication lag trade-off: followers may serve stale data.
- Sharding splits data horizontally. Range sharding is simple but creates hotspots. Hash sharding distributes evenly but breaks when you add shards.
- Consistent hashing solves the shard-addition problem: only K/N keys move when a server changes. Virtual nodes ensure even distribution across the ring.
- Connection pooling is a prerequisite for high-traffic databases. Always mention it when your design includes database access at scale.
