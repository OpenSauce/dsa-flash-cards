---
title: "Caching Strategies"
order: 2
summary: "Write-through, write-back, and write-around caching patterns, eviction policies (LRU, LFU, FIFO), and the hard problem of cache invalidation."
---

## Why This Matters

Caching is the single most common performance optimization you will discuss in system design interviews. Almost every system at scale has a cache somewhere -- between the application and the database, at the CDN edge, in the browser, or all three. Knowing which caching strategy to pick, and why, is the difference between a system that handles 10x traffic and one that collapses.

## The Core Idea

A cache stores a copy of frequently accessed data closer to the consumer, trading freshness for speed. The fundamental tension in caching is between **performance** (serve data fast) and **consistency** (serve data that is correct). Every caching decision is a position on this spectrum.

## Write Strategies

When data changes, the system must decide how the cache and the backing store (database, disk, origin server) stay in sync. There are three standard approaches.

### Write-Through

Every write goes to the cache **and** the backing store simultaneously. The write is not acknowledged to the client until both have completed.

**Strengths:**
- Cache and store are always consistent -- no stale data risk
- Reads after writes always return the latest value
- No data loss if the cache crashes -- the store already has the data

**Weakness:** Higher write latency, because every write waits for the slower backing store. If your database takes 50ms per write, every cached write takes at least 50ms.

**Use when:** Consistency is non-negotiable. Financial records, user profiles, anything where serving stale data causes visible bugs.

### Write-Back (Write-Behind)

Writes go to the cache only. The cache asynchronously flushes dirty entries to the backing store on a schedule or when evicted.

**Strengths:**
- Low write latency -- only the fast cache write is synchronous
- Write coalescing: if the same key is updated 10 times before a flush, only the final value is written to the store

**Weakness:** If the cache crashes before flushing, those writes are lost. This is real data loss, not just stale data.

**Use when:** Write throughput matters more than durability. Metrics collection, analytics counters, leaderboards -- data you can afford to lose a few seconds of.

### Write-Around

Writes go directly to the backing store, bypassing the cache entirely. The cache is only populated on read misses.

**Strengths:**
- Avoids polluting the cache with data that may never be read again
- Write-heavy workloads do not churn through cache entries

**Weakness:** The first read after a write always misses the cache. If your workload is write-then-immediately-read, write-around gives the worst of both worlds.

**Use when:** Write-heavy workloads where most written data is rarely re-read. Log ingestion, bulk imports, archival writes.

## Read Strategies

Two patterns govern how reads interact with the cache.

### Cache-Aside (Lazy Loading)

The application checks the cache first. On a miss, it reads from the backing store, writes the result into the cache, and returns it.

This is the most common pattern. The application owns the caching logic, and the cache is a passive store.

**Downside:** The first request for any piece of data is always a cache miss. Cold starts can cause load spikes.

### Read-Through

The cache itself sits in front of the store. On a miss, the cache fetches from the backing store transparently. The application always reads from the cache and never talks to the store directly.

**Advantage over cache-aside:** Simpler application code -- no cache-miss handling logic. The cache acts as a unified data access layer.

## Eviction Policies

Caches have finite memory. When full, the cache must decide which entry to discard to make room. This decision is the eviction policy.

### LRU (Least Recently Used)

Evicts the entry that has not been accessed for the longest time. Based on temporal locality: data accessed recently is likely to be accessed again soon.

**Implementation:** A hash map for O(1) lookups plus a doubly linked list to track access order. On access, move the entry to the head. On eviction, remove from the tail. This gives O(1) for both get and put.

LRU is the default choice for most workloads and the most commonly asked eviction policy in interviews.

### LFU (Least Frequently Used)

Evicts the entry with the fewest total accesses. Keeps popular items cached even if they have not been accessed in the last few seconds.

**Better than LRU when:** Access patterns have clear hot and cold data. A viral video that gets 10,000 hits per hour should not be evicted just because a batch job briefly accessed 1,000 other entries.

**Worse than LRU when:** Popularity shifts over time. Old entries that were once popular accumulate high counts and resist eviction even after they become irrelevant (frequency pollution). Some implementations decay counts over time to mitigate this.

### FIFO (First In, First Out)

Evicts the oldest entry regardless of access pattern. No bookkeeping overhead beyond insertion order.

**Use when:** All entries have roughly equal access probability, or when simplicity and performance matter more than hit rate optimization.

### Random Eviction

Pick an entry at random. Surprisingly competitive with LRU at scale (the law of large numbers smooths out bad luck) and has zero tracking overhead.

## Cache Invalidation

Keeping cached data consistent with the source of truth is famously difficult. Phil Karlton's quote -- "There are only two hard things in computer science: cache invalidation and naming things" -- exists for a reason.

### Why It Is Hard

**Race conditions:** A read and a write can interleave. Thread 1 reads stale data from the store, Thread 2 updates both the store and the cache, then Thread 1 writes its stale read into the cache. The cache now holds an old value.

**Distributed delays:** In a multi-node system, an invalidation message takes time to propagate. During that window, other nodes serve stale data.

**Thundering herd:** A popular cache entry expires. Hundreds of concurrent requests simultaneously miss the cache and hit the backing store. The store is overwhelmed.

### Invalidation Strategies

**TTL (Time-to-Live):** Each cache entry has an expiration time. After the TTL, the entry is evicted or treated as stale. Simple and self-healing, but data is stale within the TTL window.

**Event-driven invalidation:** The writer explicitly deletes or updates the cache entry after modifying the store. Precise, but requires coordination between the write path and the cache, and is vulnerable to race conditions.

**Versioning:** Each entry carries a version number. Readers reject entries with a stale version. Handles races better than simple invalidation because the version check is atomic with the read.

### Thundering Herd Mitigation

**Lock on miss:** When a cache miss occurs, the first request acquires a lock and fetches from the store. Other requests for the same key wait for the lock to release, then read the now-populated cache entry. This collapses N store requests into one.

**Stale-while-revalidate:** Serve the stale entry immediately while asynchronously fetching a fresh copy in the background. Trades temporary staleness for zero latency impact.

## Key Takeaways

- Write-through guarantees consistency at the cost of write latency. Write-back optimizes write throughput but risks data loss. Write-around avoids cache pollution from write-heavy workloads.
- LRU is the default eviction policy -- know how to implement it with a hash map and a doubly linked list for O(1) operations.
- Cache invalidation is hard because of race conditions, distributed delays, and thundering herds. TTL is the simplest mitigation; event-driven invalidation is the most precise.
- In system design interviews, always state which caching strategy you are using and why. "We use a write-through cache with LRU eviction and a 5-minute TTL" is a strong signal that you understand the trade-offs.
