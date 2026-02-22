---
title: "Divide-and-Conquer Sorts"
summary: "The divide-and-conquer paradigm applied to sorting: merge sort, quick sort, and heap sort, with their trade-offs in time, space, stability, and cache performance."
reading_time_minutes: 5
order: 2
---

## Why This Matters

The three O(n log n) sorts -- merge sort, quick sort, and heap sort -- are the workhorses of real-world sorting. Every production sorting library is built from one or more of them. Understanding their trade-offs is essential for interview discussions about algorithm selection, and divide-and-conquer itself is a paradigm you will use far beyond sorting.

## The Divide-and-Conquer Paradigm

Divide-and-conquer solves a problem in three steps:

1. **Divide** the problem into smaller subproblems of the same type.
2. **Conquer** each subproblem recursively (or directly if small enough).
3. **Combine** the subproblem solutions into a solution for the original problem.

Merge sort and quick sort are both divide-and-conquer, but they divide differently. Merge sort splits in the middle (easy divide, hard combine). Quick sort partitions around a pivot (hard divide, easy combine).

## Merge Sort

Split the array in half, recursively sort each half, then merge the two sorted halves.

- **Time:** O(n log n) guaranteed. No input triggers worse performance.
- **Space:** O(n) auxiliary for the merge step.
- **Stable:** Yes.
- **Cache performance:** Moderate. Sequential access during merge, but the auxiliary array causes extra memory traffic.

The merge step walks two sorted arrays with two pointers, picking the smaller element each time. This takes O(n) per level, and there are log(n) levels, giving O(n log n) total.

**When to use merge sort:** when you need a worst-case guarantee and stability. External sorting (data too large for RAM) is naturally merge-based -- merge sorted chunks from disk.

## Quick Sort

Pick a pivot element, partition the array so everything less than the pivot is on the left and everything greater is on the right, then recursively sort the two sides.

- **Time:** O(n log n) average. O(n^2) worst case when the pivot is always the minimum or maximum (e.g., sorted input with last-element pivot).
- **Space:** O(log n) stack space on average. O(n) worst case (degenerate recursion).
- **Stable:** No.
- **Cache performance:** Excellent. Partitioning works in-place on contiguous memory.

**Pivot selection matters.** Fixed-position pivots (first or last element) are vulnerable to sorted or nearly-sorted input. Mitigation strategies:

- **Randomized pivot:** pick a random element. Expected O(n log n).
- **Median-of-three:** take the median of the first, middle, and last elements. Handles sorted input well.

Quick sort is typically the fastest general-purpose sort in practice due to small constant factors and cache-friendly access patterns, even though merge sort has a better worst case.

## Heap Sort

Build a max-heap from the array, then repeatedly extract the maximum and place it at the end.

- **Time:** O(n log n) guaranteed. Heapify takes O(n), then n extractions each cost O(log n).
- **Space:** O(1). In-place -- the heap is built within the input array.
- **Stable:** No.
- **Cache performance:** Poor. Heap operations jump between parent and child indices, causing cache misses on large arrays.

Heap sort combines merge sort's worst-case guarantee with quick sort's O(1) space. But poor cache locality makes it slower in practice than quick sort on modern hardware.

**When to use heap sort:** when you need an in-place sort with a guaranteed O(n log n) worst case. Introsort uses it as a fallback when quicksort's recursion depth suggests degenerate behavior.

## Comparison of O(n log n) Sorts

| Property | Merge Sort | Quick Sort | Heap Sort |
|---|---|---|---|
| Worst-case time | O(n log n) | O(n^2) | O(n log n) |
| Average time | O(n log n) | O(n log n) | O(n log n) |
| Space | O(n) | O(log n) | O(1) |
| Stable | Yes | No | No |
| Cache locality | Moderate | Excellent | Poor |
| In practice | External sort | General purpose | Fallback in introsort |

## Key Takeaways

- Divide-and-conquer splits a problem into subproblems, solves them recursively, and combines the results.
- Merge sort guarantees O(n log n) and is stable, but costs O(n) extra space.
- Quick sort averages O(n log n) with excellent cache performance, but O(n^2) worst case with bad pivot choice. Randomized or median-of-three pivot selection avoids this in practice.
- Heap sort is O(n log n) guaranteed and in-place, but poor cache locality makes it slower than quick sort on modern hardware.
- Quick sort is typically fastest in practice. Merge sort is preferred when stability or worst-case guarantees matter. Heap sort is a fallback for worst-case safety without extra memory.
