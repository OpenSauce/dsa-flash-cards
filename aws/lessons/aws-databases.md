---
title: "Databases"
order: 6
summary: "RDS (managed relational), Aurora (cloud-native relational), DynamoDB (NoSQL key-value), ElastiCache (in-memory caching). When to choose each. Read replicas and Multi-AZ."
---

## Why This Matters

AWS offers several managed database services with meaningfully different architectural trade-offs. Choosing the wrong one is expensive to fix -- migrating from DynamoDB to Aurora (or vice versa) after building a production application is painful. Understanding when to use each database type is a core AWS architecture skill.

## Amazon RDS: Managed Relational Databases

**RDS (Relational Database Service)** is a managed service that runs familiar relational database engines: PostgreSQL, MySQL, MariaDB, Oracle, SQL Server.

"Managed" means AWS handles: hardware provisioning, OS patching, database software updates, automated backups, and minor version upgrades. You manage: schema design, query optimization, index management, and connection pooling.

RDS runs on EBS volumes you size in advance. You choose instance type and storage capacity. If you underestimate growth, you resize (with brief downtime for some changes).

**Use RDS when**: You need SQL, ACID transactions, complex joins, or a relational data model. The access patterns are flexible and may evolve. You're migrating an existing relational database to the cloud.

## Aurora: Cloud-Native Relational Database

**Aurora** is AWS's proprietary relational database, compatible with MySQL and PostgreSQL wire protocols. You can use the same drivers and many of the same tools -- but the internals are completely different.

Aurora separates compute from storage. The storage layer is a distributed system that:
- Auto-scales up to 128 TB with no manual provisioning
- Replicates data 6 ways across 3 Availability Zones automatically
- Provides sub-10ms replication lag to Aurora read replicas (versus seconds for RDS replicas)
- Handles failover in ~30 seconds (versus 1–2 minutes for RDS Multi-AZ)

Aurora is 3–5x more expensive than RDS at baseline, but its distributed storage architecture makes it more efficient per transaction at scale. For high-availability, high-throughput relational workloads, Aurora often wins on total cost once you factor in the operational work and downtime it eliminates.

**Aurora Serverless**: Aurora has a serverless option that scales compute capacity automatically based on load and pauses when idle. Useful for infrequently accessed databases or development environments.

**Use Aurora when**: You need high availability with fast failover, you expect the database to grow significantly, or replica lag is a concern.

## DynamoDB: Managed NoSQL

**DynamoDB** is a fully managed, serverless key-value and document store. It provides single-digit millisecond latency at any scale -- whether your table has 100 rows or 100 billion.

DynamoDB's data model is built around a partition key (and optional sort key). Every read and write targets a specific partition key. The partition key is how DynamoDB distributes data across its underlying storage layer.

**Key properties:**
- Serverless: no cluster to provision. Pay per read/write request or reserve capacity.
- Scales horizontally to any throughput level without downtime
- Eventually consistent reads by default; strongly consistent reads available at higher cost
- Global Tables: multi-region active-active replication built in

**The fundamental trade-off**: DynamoDB requires you to design your data model around your access patterns upfront. Queries must target the partition key or a configured Global Secondary Index (GSI). Flexible ad-hoc queries (arbitrary WHERE clauses, joins) are not supported.

If your access patterns are well-known and simple (get a user by ID, get all orders for a user), DynamoDB excels. If your access patterns are evolving or complex, the upfront design cost and the difficulty of retrofitting indexes make DynamoDB painful.

**Use DynamoDB when**: You need massive scale with simple access patterns. Session storage, shopping carts, gaming leaderboards, IoT device state, user preferences. Any key-value workload.

## DynamoDB vs RDS: The Decision

| Need | Choose |
|------|--------|
| SQL and complex joins | RDS / Aurora |
| ACID transactions across multiple tables | RDS / Aurora |
| Flexible, evolving query patterns | RDS / Aurora |
| Massive scale, simple key-based access | DynamoDB |
| Serverless pricing (scale to zero) | DynamoDB |
| Sub-millisecond key lookups at scale | DynamoDB |

Neither is universally better. DynamoDB trades query flexibility for scale and operational simplicity. RDS trades scale and operational simplicity for query flexibility.

## ElastiCache: In-Memory Caching

**ElastiCache** is a managed in-memory data store supporting Redis and Memcached. It reduces database load by serving frequently accessed data from memory.

The fundamental caching pattern:
1. Application checks the cache for the requested data
2. **Cache hit**: return data from cache immediately (microseconds)
3. **Cache miss**: query the database, store result in cache, return result

**When to use ElastiCache:**
- Read-heavy workloads where the same data is requested repeatedly
- Expensive computations (aggregations, complex joins) whose results can be cached
- Session storage for stateless application servers
- Rate limiting counters (Redis atomic increment)

**Cache invalidation** is the hardest part: when the underlying data changes, the cache entry becomes stale. Strategies include TTL-based expiration (set it and forget it), explicit invalidation on write (application deletes/updates cache when it updates the database), and write-through caching (writes update the cache and database simultaneously).

Redis vs Memcached: Redis supports persistence, replication, more complex data structures (lists, sets, sorted sets), and Lua scripting. Memcached is simpler and multi-threaded. In practice, Redis is almost always the right choice.

## Read Replicas and Multi-AZ

Both RDS and Aurora support two horizontal scaling mechanisms:

**Read replicas**: Copies of the primary database that serve read traffic. Write traffic still goes to the primary; reads can be distributed across replicas. Reduces load on the primary for read-heavy workloads. Replica lag means reads may not reflect the most recent writes.

**Multi-AZ**: The primary database synchronously replicates to a standby in a different AZ. The standby handles no traffic during normal operation. If the primary fails, AWS automatically promotes the standby and updates the DNS endpoint. This is a high-availability feature, not a scaling feature.

Key distinction: read replicas scale reads; Multi-AZ ensures availability.

## Key Takeaways

- RDS runs familiar SQL engines (PostgreSQL, MySQL, etc.). Use it when you need SQL, ACID transactions, or flexible query patterns.
- Aurora is cloud-native MySQL/PostgreSQL with distributed storage, 6-way replication, and faster failover. Higher baseline cost, better at scale.
- DynamoDB is serverless NoSQL with single-digit millisecond latency at any scale. Requires designing your data model around access patterns upfront.
- ElastiCache (Redis or Memcached) sits in front of your database, serving frequent reads from memory. Cache invalidation is the hard problem.
- Read replicas scale reads. Multi-AZ ensures availability via automatic failover. These are separate concerns.
