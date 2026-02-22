---
title: "Space Complexity"
order: 4
summary: "What space complexity measures. Auxiliary space versus total space. Common space patterns: in-place algorithms, recursive call stacks, building new data structures. Time-space trade-offs."
---

## Why This Matters

Time complexity gets most of the attention, but space complexity determines whether an algorithm is practical given memory constraints. An algorithm that uses O(n²) extra memory is often worse than a slightly slower algorithm that uses O(1). More importantly, interviews regularly ask about space separately from time — and recursive algorithms use space implicitly through the call stack, even when they look like they use none.

## What Space Complexity Measures

Space complexity measures the **memory an algorithm uses as a function of input size**. This includes:

- Variables and data structures the algorithm creates
- The call stack for recursive algorithms
- It does NOT include the input itself (in most conventions)

The memory used exclusively by the algorithm — excluding the input — is called **auxiliary space**.

### Auxiliary Space vs Total Space

| Term | Includes input? | When to use |
|---|---|---|
| Auxiliary space | No | Most common meaning in algorithms |
| Total space | Yes | When input storage is part of the analysis |

When a problem says "sort in-place," it means auxiliary space = O(1). The O(n) input array is already in memory; the algorithm is not allowed to allocate a second O(n) array.

## Common Space Patterns

### O(1) — In-Place

The algorithm uses a fixed amount of extra memory regardless of n.

Examples:
- Bubble sort: two index variables, a swap buffer — same size regardless of input
- Two-pointer: two integer pointers
- Most iterative algorithms that avoid building new data structures

In-place does not mean the input is unchanged — it means the algorithm does not allocate memory proportional to n.

### O(n) — Linear Space

The algorithm builds a data structure proportional to input size.

Examples:
- Copying an array: creates a new array of size n
- Hash set for deduplication: stores up to n keys
- Merge sort's merge step: temporary array of size n

The space trade-off is often intentional: an O(n) hash set enables O(1) lookup, replacing an O(n²) nested-loop solution with O(n) time.

### O(log n) — Recursive Call Stack (Divide and Conquer)

Recursive algorithms consume stack frames. Each frame stores local variables, the return address, and the current arguments.

Divide-and-conquer algorithms that split the problem in half each time reach a maximum recursion depth of log n:

```
function binarySearch(arr, target, low, high):
    if low > high: return -1
    mid = (low + high) // 2
    if arr[mid] == target: return mid
    if target < arr[mid]:
        return binarySearch(arr, target, low, mid - 1)
    return binarySearch(arr, target, mid + 1, high)
```

Maximum recursion depth: log₂(n). Space used by the call stack: **O(log n)**.

Note: the iterative version of binary search uses O(1) space. The recursive version uses O(log n) due to the call stack.

### O(n) — Recursive Call Stack (Linear Recursion)

Recursion that goes n levels deep uses O(n) stack space:

```
function factorial(n):
    if n == 0: return 1
    return n * factorial(n - 1)
```

n frames deep → **O(n) space**. For large n, this causes a stack overflow. The iterative version is O(1).

Linked list traversal via recursion, naive tree traversal on a degenerate tree — all can hit O(n) stack depth.

## The Time-Space Trade-Off

Many algorithms trade space for time. The hash set example is canonical:

**Problem:** Check if an array has duplicates.

- **O(1) space, O(n²) time:** Compare every pair. Two nested loops, no extra memory.
- **O(n) space, O(n) time:** Insert into a hash set as you scan. First duplicate found in O(1) lookup.

Neither is universally better. Memory-constrained systems may prefer the O(n²) approach. Most application code prefers O(n) time.

Other common trade-offs:

| Technique | Space cost | Time benefit |
|---|---|---|
| Memoization | O(n) to O(n²) | Reduces O(2ⁿ) recursion to O(n) |
| Precomputed prefix sums | O(n) | O(n²) range sum queries become O(1) |
| Index structure (hash map) | O(n) | O(n) linear search becomes O(1) average |

## Key Takeaways

- Auxiliary space is the extra memory an algorithm allocates — it excludes the input.
- In-place means O(1) auxiliary space, not that the input is unmodified.
- Recursive algorithms consume stack space equal to the maximum recursion depth. A recursion that goes n levels deep uses O(n) space even with no explicit data structures.
- Divide-and-conquer recursion (halving each step) uses O(log n) stack space.
- The most common time-space trade-off: spend O(n) extra memory to replace O(n²) time with O(n) time. A hash set for O(1) lookup is the canonical example.
