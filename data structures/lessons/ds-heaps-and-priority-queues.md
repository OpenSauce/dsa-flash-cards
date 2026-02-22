---
title: "Heaps and Priority Queues"
summary: "Min/max heap property, array-based representation, sift-up and sift-down operations, O(n) heapify, and the priority queue abstraction with top-k patterns."
reading_time_minutes: 4
order: 7
---

## Why This Matters

Heaps are the standard implementation of priority queues -- any problem that asks "give me the smallest/largest element efficiently" is a heap problem. They appear in Dijkstra's algorithm, median finding, merge k sorted lists, and top-k patterns. The array representation is elegant and worth understanding deeply.

## The Heap Property

A **binary heap** is a complete binary tree where every parent satisfies an ordering constraint:

- **Min-heap:** every parent is less than or equal to its children. The root is the minimum.
- **Max-heap:** every parent is greater than or equal to its children. The root is the maximum.

The heap property applies only between parent and child -- siblings have no ordering relationship.

## Array Representation

Because a heap is always a **complete** binary tree (every level filled left to right), it maps naturally to an array with no gaps:

```
        1
       / \
      3   5
     / \
    7   4

Array: [1, 3, 5, 7, 4]
Index:  0  1  2  3  4
```

For a node at index `i`:
- **Left child:** `2i + 1`
- **Right child:** `2i + 2`
- **Parent:** `(i - 1) / 2` (integer division)

No pointers are needed. The array layout gives excellent cache locality since parent and children are close in memory.

## Core Operations

### Insert (Sift-Up) -- O(log n)

Append the new element at the end of the array (maintaining completeness), then **sift up**: compare with the parent and swap if the heap property is violated. Repeat until the element reaches its correct position or the root.

Maximum swaps = height of the tree = O(log n).

### Extract-Min/Max (Sift-Down) -- O(log n)

Replace the root with the last element in the array (maintaining completeness), then **sift down**: compare with children and swap with the smaller child (min-heap) or larger child (max-heap). Repeat until the element settles.

Maximum swaps = height = O(log n).

### Peek -- O(1)

The root (index 0) is always the min or max. No computation needed.

## Heapify: Building a Heap in O(n)

Given an unsorted array, you can build a heap in O(n) -- not O(n log n). Start from the last non-leaf node and sift down each node.

The insight: leaf nodes (about half the array) are already valid heaps. Nodes near the bottom sift down at most 1 level. Only the root sifts down O(log n) levels. The total work across all nodes sums to O(n).

This matters when you need to build a heap from scratch, such as in heap sort or when initializing a priority queue from a batch of elements.

## Priority Queue

A **priority queue** is an abstract data type: insert elements with priorities, and always extract the highest-priority element first. A binary heap is the standard concrete implementation.

| Operation | Time |
|-----------|------|
| Insert | O(log n) |
| Extract-min/max | O(log n) |
| Peek | O(1) |

Go provides `container/heap` -- you implement the `heap.Interface` on a slice to get a priority queue.

## The Top-K Pattern

"Find the k largest elements in a stream" is a classic interview problem.

**Solution:** Maintain a min-heap of size k. For each new element, if it is larger than the heap's minimum, replace the minimum and sift down. At the end, the heap contains the k largest elements.

Why a min-heap for the *largest* elements? Because you want to quickly discard the smallest of your k candidates. The root of a min-heap gives you that smallest candidate in O(1).

Time: O(n log k) for n elements. Space: O(k).

## Heap Sort

Heap sort builds a max-heap from the array (O(n)), then repeatedly extracts the maximum and places it at the end of the array. Total time: O(n log n), in-place, but not stable.

In practice, quicksort is faster due to better cache behavior, but heap sort has a guaranteed O(n log n) worst case.

## Key Takeaways

- A binary heap is a complete binary tree satisfying the min-heap or max-heap property.
- Array representation: children of index i are at 2i+1 and 2i+2, parent at (i-1)/2. No pointers needed.
- Insert (sift-up) and extract (sift-down) are both O(log n). Peek is O(1).
- Building a heap from an unsorted array is O(n), not O(n log n).
- Priority queues are the main abstraction. The top-k pattern uses a min-heap of size k.
