---
title: "CAP Theorem and Consistency Models"
summary: "CAP theorem and why partition tolerance is non-negotiable, CP vs AP systems, the PACELC extension, and consistency models from strong to eventual."
reading_time_minutes: 5
order: 5
---

## Why This Matters

Distributed systems fail in ways that single-machine systems cannot. Nodes crash. Networks partition. When things go wrong, a distributed system must choose: do I return a potentially wrong answer, or no answer at all? The CAP theorem formalizes this choice. Understanding it prevents you from designing systems that make impossible consistency guarantees.

## The CAP Theorem

A distributed system can guarantee at most two of three properties simultaneously:

- **Consistency (C):** Every read returns the most recent write. All nodes see the same data at the same time.
- **Availability (A):** Every request receives a response -- not necessarily the latest data, but always a response.
- **Partition Tolerance (P):** The system continues operating when network partitions cause some nodes to be unable to communicate.

### Why You Cannot Have All Three

During a network partition, some nodes cannot communicate with others. When a request arrives at an isolated node, it must choose:

- **Respond with potentially stale data** -- preserves Availability, sacrifices Consistency (AP).
- **Refuse to respond until it can confirm the latest state** -- preserves Consistency, sacrifices Availability (CP).

There is no third option. You cannot simultaneously guarantee a fresh response (C) and any response (A) when nodes cannot communicate (P).

### Why Partition Tolerance Is Non-Negotiable

Network failures happen in production. Switches fail, cables are cut, AWS availability zones lose connectivity. A system that cannot tolerate partitions stops working every time there is a network hiccup. This is unacceptable for any real distributed system.

The real choice, therefore, is **C vs A during a partition**. The CAP theorem is not about choosing two of three -- it is about choosing between consistency and availability when the network fails.

## CP vs AP Systems

### CP Systems

Sacrifice availability during partitions. When nodes cannot communicate, they refuse to serve requests rather than risk returning stale data.

**Examples:** ZooKeeper, HBase, MongoDB (default configuration).

**Use when:** Correctness matters more than uptime. Financial transactions, distributed locking, leader election -- scenarios where an incorrect answer is worse than no answer.

### AP Systems

Sacrifice consistency during partitions. Nodes keep serving requests even if they cannot verify they have the latest data.

**Examples:** Cassandra, DynamoDB, CouchDB, DNS.

**Use when:** Availability matters more than perfect consistency. Shopping carts, social media feeds, DNS resolution -- scenarios where a slightly stale answer is better than no answer.

### Tunable Consistency

Many modern databases blur the CP/AP line. Cassandra lets you choose a consistency level per operation: `QUORUM` for reads and writes gives strong consistency; `ONE` gives high availability with potential staleness. DynamoDB offers both eventually consistent reads (lower latency) and strongly consistent reads (higher latency). The CAP trade-off becomes a per-operation choice.

## PACELC: Beyond CAP

CAP only describes behavior during partitions. In practice, partitions are rare. PACELC extends CAP to cover the trade-off that matters during normal operation.

**PACELC:** If there is a **P**artition, choose **A**vailability or **C**onsistency; **E**lse (normal operation), choose **L**atency or **C**onsistency.

Even when the network is healthy, strong consistency requires coordination between nodes -- which adds latency. A system that waits for all replicas to acknowledge a write before responding is more consistent but slower. A system that acknowledges immediately and replicates asynchronously is faster but eventually consistent.

**System classifications:**
- **DynamoDB: PA/EL** -- available during partitions, low latency during normal operation
- **HBase: PC/EC** -- consistent during partitions, accepts higher latency for strong reads
- **Cassandra: PA/EL** -- defaults favor availability and low latency, tunable per operation

Mentioning PACELC shows you understand that the latency-consistency trade-off is the everyday concern, not just the partition-time concern.

## Consistency Models

Not all consistency is the same. There is a spectrum from strongest to weakest:

### Strong Consistency

Every read returns the most recent write. After a write completes, all subsequent reads see that value. Reads may block until all replicas confirm.

**Cost:** Higher latency (coordination required), lower availability during partitions.

**Use when:** Correctness is non-negotiable. Bank balances, inventory counts, anything where users expect to see their own writes immediately.

### Causal Consistency

If event A causally precedes event B (A happened before B and B depends on A), all nodes see A before B. Unrelated events may be seen in different orders by different nodes.

**Example:** If you post a comment and then reply to it, any user who sees your reply must also see the original comment. But two unrelated posts can appear in any order.

**Cost:** Lower than strong consistency, but still requires tracking causality metadata.

### Eventual Consistency

Given no new updates, all nodes will eventually converge to the same value. Reads may return stale data, but the system guarantees convergence.

**Cost:** Lowest latency. No coordination required before responding.

**Use when:** Staleness is tolerable. DNS propagation (changes take minutes to propagate globally), social media likes, shopping cart totals. Users accept that another user's edit might take a second to appear.

## Key Takeaways

- CAP: a distributed system can guarantee at most two of Consistency, Availability, and Partition Tolerance.
- Partition tolerance is non-negotiable in real networks. The real trade-off is C vs A during partitions.
- CP systems refuse requests during partitions to stay correct. AP systems keep responding, accepting potential staleness.
- PACELC extends CAP to normal operation: even without partitions, strong consistency costs latency.
- Consistency is a spectrum: strong consistency > causal consistency > eventual consistency, trading off latency and availability as you move down.
