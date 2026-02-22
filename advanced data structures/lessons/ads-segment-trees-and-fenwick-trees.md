---
title: "Segment Trees and Fenwick Trees"
summary: "The range query problem, segment tree structure and operations, Fenwick tree prefix sums and bit manipulation, lazy propagation, and when to use each."
reading_time_minutes: 5
order: 4
---

## Why This Matters

A common class of problems asks: given an array, answer range queries ("what is the sum of elements from index l to r?") while also supporting updates ("set element at index i to value v"). A naive approach answers each query in O(n), but segment trees and Fenwick trees reduce query and update to O(log n), making real-time range aggregation feasible on large arrays.

## The Range Query Problem

Given array `A = [3, 1, 4, 1, 5, 9, 2, 6]`, consider:

- **Range sum query:** What is the sum from index 2 to 5? (4 + 1 + 5 + 9 = 19)
- **Point update:** Set A[3] = 7.
- **Range min query:** What is the minimum from index 1 to 4?

A prefix sum array handles sum queries in O(1), but O(n) updates. A segment tree handles arbitrary range queries *and* updates in O(log n).

## Segment Tree

A segment tree is a complete binary tree where each node represents an interval of the original array. The root covers the entire array. Each internal node covers the union of its children's intervals. Leaves are individual elements.

```
Array: [3, 1, 4, 1, 5, 9, 2, 6]
Index:  0  1  2  3  4  5  6  7

          [0..7]: 31
         /             \
    [0..3]: 9       [4..7]: 22
    /     \          /      \
[0..1]:4 [2..3]:5 [4..5]:14 [6..7]:8
 /  \    /   \    /    \    /    \
[0]:3 [1]:1 [2]:4 [3]:1 [4]:5 [5]:9 [6]:2 [7]:6
```

### Build: O(n)

Build the tree bottom-up: copy the array into the leaves, then compute each internal node as a function of its two children. For sum: `node = left_child + right_child`.

```
build(array):
    n = len(array)
    tree = array of size 2n  // leaves start at index n
    for i in 0..n-1:
        tree[n + i] = array[i]
    for i in n-1 down to 1:
        tree[i] = tree[2*i] + tree[2*i + 1]
```

### Point Update: O(log n)

Update the leaf and propagate the change up by recomputing each ancestor.

```
update(pos, value):
    i = n + pos
    tree[i] = value
    while i > 1:
        i = i / 2
        tree[i] = tree[2*i] + tree[2*i + 1]
```

### Range Query: O(log n)

Walk up from both ends of the query range, collecting results from nodes that fall entirely within the range.

```
query(l, r):  // [l, r) half-open
    result = 0
    l = l + n; r = r + n
    while l < r:
        if l is a right child (odd index): result += tree[l]; l++
        if r is a right child (odd index): r--; result += tree[r]
        l = l / 2; r = r / 2
    return result
```

At most two nodes are processed per level, giving O(log n) total.

## Lazy Propagation

What if you need range updates — "add 5 to all elements from index l to r"? Without lazy propagation, updating every element in the range is O(n). Lazy propagation defers the work:

- Store a "lazy tag" at each node: a pending update that has not yet been pushed to children.
- When visiting a node during query or update, push its lazy tag to its children first, then proceed.

This keeps both range updates and range queries at O(log n). Lazy propagation significantly increases implementation complexity — only add it when range updates are required.

## Fenwick Tree (Binary Indexed Tree)

A Fenwick tree is a compact array-based structure that supports **point updates** and **prefix sum queries** in O(log n). It is simpler to implement than a segment tree and uses less memory, but it is limited to prefix queries.

### The Bit Trick

Each index i in the Fenwick tree array stores the sum of a specific range of the original array. The size of that range is determined by the lowest set bit of i.

```
i = 6  (binary: 110) → stores sum of 2 elements (lowest bit = 10 = 2)
i = 4  (binary: 100) → stores sum of 4 elements (lowest bit = 100 = 4)
i = 5  (binary: 101) → stores sum of 1 element  (lowest bit = 001 = 1)
```

`i & -i` (bitwise AND of i with its two's complement negation) isolates the lowest set bit.

### Prefix Sum Query: O(log n)

```
query(i):  // prefix sum from 1 to i (1-indexed)
    sum = 0
    while i > 0:
        sum += bit[i]
        i -= i & -i   // strip lowest set bit, jump to parent range
    return sum
```

### Point Update: O(log n)

```
update(i, delta):  // add delta to element at index i (1-indexed)
    while i <= n:
        bit[i] += delta
        i += i & -i   // add lowest set bit, jump to next responsible range
```

### Range Query via Two Prefix Queries

`range_sum(l, r) = prefix_sum(r) - prefix_sum(l - 1)`

This requires O(log n) for each prefix query, so range queries cost O(log n) total.

## Comparing Segment Tree vs Fenwick Tree

| Feature | Segment Tree | Fenwick Tree |
|---|---|---|
| Point update | O(log n) | O(log n) |
| Range query | O(log n) | O(log n) (via two prefix queries) |
| Range update | O(log n) with lazy propagation | O(log n) with difference array trick |
| Arbitrary aggregation (min, max, GCD) | Yes | No (sum only, natively) |
| Implementation complexity | High | Low |
| Space | O(2n) to O(4n) | O(n) |

**Use a Fenwick tree when:** You need prefix sums or can express queries as differences of prefix sums. It is simpler and faster in practice.

**Use a segment tree when:** You need non-prefix aggregations (range min, range max, range GCD), or range updates with lazy propagation.

## Key Takeaways

- Segment trees support O(log n) range queries and point updates for any associative aggregation function.
- Build is O(n), using bottom-up computation from leaves.
- Lazy propagation extends segment trees to O(log n) range updates, at the cost of implementation complexity.
- Fenwick trees support O(log n) prefix queries and point updates using a bit manipulation trick (`i & -i`).
- Fenwick trees are simpler and more memory-efficient than segment trees, but limited to operations expressible as prefix sums.
