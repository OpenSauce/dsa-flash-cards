---
title: "Caches and Specialized Structures"
summary: "LRU cache implementation with hash map and doubly linked list, monotonic stack for next-greater-element problems, and bloom filters for probabilistic membership."
reading_time_minutes: 5
order: 5
---

## Why This Matters

Some problems do not fit neatly into a single classic data structure — they require combining primitives or accepting approximations. This lesson covers three patterns that appear in interviews and production systems: an LRU cache (which combines a hash map and a linked list to achieve O(1) everything), a monotonic stack (which solves "next greater element" problems in O(n) instead of O(n²)), and a bloom filter (which accepts a small chance of false positives in exchange for dramatic space savings).

## LRU Cache

An LRU (Least Recently Used) cache evicts the item that was accessed least recently when the cache reaches capacity. It must support:

- **get(key):** Return the cached value, or -1 if not present. Mark the key as most recently used.
- **put(key, value):** Insert or update the key-value pair. If at capacity, evict the least recently used key first.

Both operations must be O(1).

### Why Two Data Structures

A hash map alone gives O(1) lookup but O(n) reordering. A doubly linked list alone gives O(1) reordering but O(n) lookup. Together they give O(1) for both.

```
get(key):
    if key not in map:
        return -1
    node = map[key]
    move node to front of list  // O(1) with doubly linked list
    return node.value

put(key, value):
    if key in map:
        node = map[key]
        node.value = value
        move node to front of list
    else:
        if size == capacity:
            lru_node = list.tail  // tail is least recently used
            remove lru_node from list
            delete map[lru_node.key]  // note: node stores its key for this reason
        new_node = Node(key, value)
        prepend new_node to list front
        map[key] = new_node
```

The critical detail: **each linked list node stores its own key**. When evicting from the tail, you need to remove the key from the hash map. Without the key stored in the node, this requires a reverse lookup — O(n). Storing the key in the node keeps eviction at O(1).

### Real-World Uses

CPU caches, database buffer pools, CDN edge caches, and DNS resolvers all use LRU or approximations of LRU. When memory is bounded and temporal locality exists (recently-used items are likely to be used again soon), LRU maximizes the hit rate.

## Monotonic Stack

A monotonic stack is a standard stack with one constraint: elements are always either strictly increasing or strictly decreasing from bottom to top. Elements that would violate the order are popped before the new element is pushed.

The key insight: every element is pushed once and popped at most once, so the total work across all push operations is O(n) even though individual pushes may trigger multiple pops.

### Next Greater Element

The classic monotonic stack problem: for each element in an array, find the next element to its right that is strictly greater than it.

```
next_greater(nums):
    result = [-1] * len(nums)  // default: no greater element
    stack = []  // stores indices, decreasing stack (decreasing by value)
    for i in 0..len(nums)-1:
        while stack is not empty and nums[stack.top()] < nums[i]:
            idx = stack.pop()
            result[idx] = nums[i]  // nums[i] is the "next greater" for idx
        stack.push(i)
    return result
```

When a new value enters, it is larger than whatever is on top — so it is the "next greater element" for all those popped items. Write their answers immediately.

```
Input:  [2, 1, 4, 3, 5]
Output: [4, 4, 5, 5, -1]
```

Monotonic stacks solve: next greater element, previous greater element, largest rectangle in histogram, daily temperatures, and trapping rain water — all in O(n).

### Increasing vs Decreasing Stack

- **Decreasing stack (top is smallest):** Pop when a larger value arrives — useful for "next greater."
- **Increasing stack (top is largest):** Pop when a smaller value arrives — useful for "next smaller."

## Bloom Filters

A bloom filter answers the question "is this element in the set?" using much less memory than storing the actual set — at the cost of a small probability of false positives.

### How It Works

A bloom filter is a bit array of m bits, all initialized to 0, and k independent hash functions.

**Insert(x):**
1. Hash x with each of the k hash functions, producing k positions in the bit array.
2. Set all k bits to 1.

**Query(x):**
1. Hash x with all k hash functions.
2. If any of the k bits is 0, x is definitely NOT in the set.
3. If all k bits are 1, x is probably in the set (could be a false positive).

```
Insert "apple":  hash1("apple")=3, hash2("apple")=7, hash3("apple")=11
Bits: ...1...1...1...

Query "apple":   check bits 3, 7, 11 → all 1 → probably in set
Query "grape":   hash1("grape")=3, hash2("grape")=7, hash3("grape")=5
                 check bits 3, 7, 5 → bit 5 is 0 → definitely NOT in set
```

### False Positives, Never False Negatives

A false positive occurs when all k bits for an element are 1 from prior insertions of different elements. The filter reports "probably in set" for an element that was never inserted.

A false negative is impossible: if x was inserted, its bits were set to 1 and will remain 1 (bits are never reset to 0). A query on x will always see all 1s.

**The trade-off:** As more elements are inserted, more bits become 1, and the probability of a false positive increases. A bloom filter has a fixed false positive rate determined by m (bits), n (expected elements), and k (hash functions). The optimal k is `(m/n) × ln(2)`.

### Deletions Are Not Supported

Because multiple elements can set the same bit, clearing a bit during deletion might cause false negatives for other elements. Standard bloom filters do not support deletion. A counting bloom filter (replacing each bit with a counter) supports deletion at the cost of 8–32× more memory.

### Real-World Uses

- **Databases (Cassandra, RocksDB):** Before doing an expensive disk lookup, check the bloom filter. If it says "not present," skip the disk read.
- **Web browsers:** Chrome uses a bloom filter to check URLs against a list of malicious sites without sending every URL to a server.
- **CDNs:** Determine whether a resource has been cached at the edge without storing the full cache index.
- **Spam filters:** Quick first-pass filter before more expensive ML models.

## Key Takeaways

- LRU cache = hash map (O(1) lookup) + doubly linked list (O(1) reorder). Store the key inside each node to enable O(1) eviction from the tail.
- A monotonic stack maintains elements in order (increasing or decreasing). Each element is pushed and popped at most once — total O(n) for the whole pass.
- Use a monotonic stack for next-greater, next-smaller, and "largest rectangle" problems.
- A bloom filter is a probabilistic set membership structure. False positives are possible; false negatives are not.
- Bloom filters support insert and query but not deletion. They are useful when memory is scarce and occasional false positives are acceptable.
