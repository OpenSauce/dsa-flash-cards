---
title: "Hash Tables"
summary: "Hash functions, buckets, collision resolution via chaining and open addressing, load factor and rehashing, and the relationship between hash maps and hash sets."
reading_time_minutes: 4
order: 4
---

## Why This Matters

Hash tables power the most common data structures in practical programming: dictionaries, sets, caches, and counters. They give O(1) average-case lookup, insert, and delete -- unmatched by any other general-purpose structure. Understanding how they achieve this (and when they fail) is essential for both interviews and system design.

## How Hash Tables Work

A hash table is an array of **buckets**. To store a key-value pair:

1. Compute `hash(key)` -- a function that converts the key into an integer.
2. Map the hash to a bucket index: `index = hash(key) % num_buckets`.
3. Store the key-value pair in that bucket.

Lookup reverses the process: hash the key, go to the bucket, find the pair.

```
hash("alice") = 42
42 % 8 = 2  ->  bucket[2] stores ("alice", 100)
```

When the hash function distributes keys evenly across buckets, each bucket holds at most one or two items, and operations are O(1).

## Collisions

A **collision** occurs when two different keys map to the same bucket. Collisions are inevitable -- you are mapping a potentially infinite key space to a finite array.

### Chaining

Each bucket holds a linked list (or other collection). Colliding keys are appended to the list. Lookup walks the list to find the matching key.

- Average case: O(1) if the lists are short (good hash function, low load factor).
- Worst case: O(n) if all keys land in the same bucket (the table degrades to a linked list).

### Open Addressing

Instead of a list, the table probes for the next empty slot. Common strategies:

- **Linear probing:** Check index, index+1, index+2, ...
- **Quadratic probing:** Check index, index+1^2, index+2^2, ...
- **Double hashing:** Use a second hash function to determine the step size.

Open addressing avoids pointer overhead and has better cache locality than chaining, but it is more sensitive to load factor -- as the table fills, probe sequences get longer.

## Load Factor and Rehashing

The **load factor** is `n / num_buckets`, where n is the number of stored keys. As the load factor increases, collisions become more frequent and operations slow down.

When the load factor exceeds a threshold (typically 0.7-0.75), the table **rehashes**: allocate a new array with double the buckets, recompute the index for every key, and reinsert them. An individual rehash is O(n), but it happens infrequently, so the amortized cost per insert remains O(1).

This is the same doubling strategy as dynamic arrays, and the amortized analysis works the same way.

## Hash Maps vs Hash Sets

A **hash map** stores key-value pairs. You look up a value by its key.

A **hash set** stores keys only (no values). It answers one question: "is this element in the set?" You can think of it as a hash map where every value is `true`.

Both have the same performance characteristics: O(1) average insert, delete, and lookup; O(n) worst case.

### Common Set Operations

| Operation | Description | Time (average) |
|-----------|-------------|----------------|
| Add | Insert element | O(1) |
| Contains | Membership test | O(1) |
| Remove | Delete element | O(1) |
| Union | All elements from both sets | O(n + m) |
| Intersection | Elements in both sets | O(min(n, m)) |
| Difference | Elements in A but not B | O(n) |

Sets are the go-to structure for deduplication and fast membership testing.

## Hash Tables vs BSTs

| | Hash Table | BST (balanced) |
|---|---|---|
| Search | O(1) avg, O(n) worst | O(log n) guaranteed |
| Insert | O(1) avg, O(n) worst | O(log n) guaranteed |
| Ordered iteration | Not supported | In-order traversal |
| Range queries | Not supported | O(log n + k) |
| Worst case | Degrades to O(n) | Always O(log n) |

Use a hash table when you need raw speed and don't care about ordering. Use a BST when you need sorted traversal or range queries.

## Key Takeaways

- Hash tables map keys to array indices via a hash function, achieving O(1) average-case operations.
- Collisions are resolved by chaining (linked list per bucket) or open addressing (probe for empty slots).
- Load factor triggers rehashing: double the buckets and reinsert all keys. Amortized cost stays O(1).
- A hash set is a hash map with keys only -- same performance, used for membership testing and deduplication.
- Choose hash tables for speed; choose BSTs when you need ordering or guaranteed worst-case performance.
