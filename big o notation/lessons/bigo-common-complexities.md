---
title: "Common Complexity Classes"
order: 2
summary: "The seven main complexity classes: O(1), O(log n), O(n), O(n log n), O(n^2), O(2^n), O(n!). Concrete examples and growth rate comparisons. Data structure operation complexities explained."
reading_time_minutes: 6
---

## Why This Matters

Every algorithm you encounter maps to one of a small set of complexity classes. Knowing these classes — what they mean, what they look like in code, and where they appear — lets you immediately classify any algorithm or data structure operation. This is the vocabulary that makes complexity analysis fast in practice.

## The Seven Classes

### O(1) — Constant Time

Cost does not depend on input size. Always the same number of operations.

Examples:
- Array access by index: `arr[5]`
- Hash map lookup by key (average case)
- Push/pop on a stack
- Reading the top of a heap (min or max)

```python
# O(1) — constant time regardless of input size
nums = [10, 20, 30, 40, 50]
print(nums[2])  # always one operation, no matter how long the list
```

### O(log n) — Logarithmic

Cost grows by 1 each time n doubles. Occurs when the algorithm repeatedly halves the problem space.

Examples:
- Binary search on a sorted array
- Balanced BST search, insert, delete
- Heap insert and delete (bubble up/down through log n levels)

```
n = 8     → 3 operations
n = 16    → 4 operations
n = 1024  → 10 operations
n = 10^6  → ~20 operations
```

Logarithmic algorithms are extremely fast even at enormous scale. Doubling input size costs you one extra step.

```python
# O(log n) — halving pattern
def binary_search(arr, target):
    lo, hi = 0, len(arr) - 1
    while lo <= hi:
        mid = (lo + hi) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            lo = mid + 1
        else:
            hi = mid - 1
    return -1
```

### O(n) — Linear

Cost grows in proportion to input size. The algorithm must touch every element at least once.

Examples:
- Linear search (unsorted array)
- Array traversal
- Linked list traversal
- Copying an array

```python
# O(n) — must look at every element
def find_max(arr):
    best = arr[0]
    for x in arr:
        if x > best:
            best = x
    return best
```

### O(n log n) — Linearithmic

Cost grows faster than linear but much slower than quadratic. Typical of efficient comparison-based sorting.

Examples:
- Merge sort
- Heap sort
- Quick sort (average case)
- Building a heap from n elements

```
n = 1000   → ~10,000 operations
n = 10^6   → ~20,000,000 operations
```

This is the optimal lower bound for comparison-based sorting — no comparison sort can do better than O(n log n) in the worst case.

### O(n²) — Quadratic

Cost grows with the square of input size. Typical of algorithms with nested loops over the input.

Examples:
- Bubble sort, insertion sort, selection sort
- Comparing all pairs of elements
- Matrix multiplication (naive)
- Nested loops, each running n iterations

```python
# O(n^2) — nested loops, each running n times
def has_duplicate_pair(arr):
    for i in range(len(arr)):
        for j in range(i + 1, len(arr)):
            if arr[i] == arr[j]:
                return True
    return False
```

Quadratic algorithms become unacceptably slow around n = 10,000-100,000, depending on the constant.

### O(2ⁿ) — Exponential

Cost doubles with each additional element. Typical of naive recursive algorithms that branch into two subproblems of size n−1.

Examples:
- Naive Fibonacci without memoization
- Generating all subsets of a set
- Brute-force recursive solutions to combinatorial problems

```
n = 10  → 1,024 operations
n = 30  → 1,073,741,824 operations
n = 50  → ~10^15 operations  (centuries of compute time)
```

Exponential algorithms are only feasible for very small inputs (n <= 20-30).

```python
# O(2^n) — naive Fibonacci (each call branches into two)
def fib(n):
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)
# fib(30) takes over a billion operations!
```

### O(n!) — Factorial

Cost grows as the product of all integers up to n. Even more extreme than exponential.

Examples:
- Generating all permutations of n elements
- Brute-force traveling salesman problem

```
n = 10  → 3,628,800 operations
n = 15  → 1,307,674,368,000 operations
n = 20  → 2.4 × 10^18 operations  (not computable in any reasonable time)
```

## Data Structure Operation Complexity Reference

The complexity values below are derived from structural properties of each data structure. Lessons 1–3 explain the derivations. This table is for recall:

| Data Structure | Access | Search | Insert | Delete |
|---|---|---|---|---|
| Array | O(1) | O(n) | O(n) | O(n) |
| Dynamic array (end) | O(1) | O(n) | O(1) amortized | O(n) |
| Singly linked list | O(n) | O(n) | O(1) at head | O(1) at head |
| Doubly linked list | O(n) | O(n) | O(1) at head/tail | O(1) at head/tail |
| Stack | — | O(n) | O(1) push | O(1) pop |
| Queue | — | O(n) | O(1) enqueue | O(1) dequeue |
| Hash map | — | O(1) avg | O(1) avg | O(1) avg |
| Balanced BST | — | O(log n) | O(log n) | O(log n) |
| Binary heap | O(1) peek | O(n) | O(log n) | O(log n) |

## Key Takeaways

- The seven classes in ascending order of cost: O(1) < O(log n) < O(n) < O(n log n) < O(n²) < O(2ⁿ) < O(n!).
- O(log n) is doubly efficient — doubling n only adds one step. This is why binary search and balanced BSTs are so powerful.
- O(n log n) is the floor for comparison-based sorting. Algorithms that claim to beat it either use non-comparison methods (counting sort, radix sort) or are wrong.
- O(n²) is feasible for n up to ~10,000. Beyond that, look for an O(n log n) approach.
- O(2ⁿ) and O(n!) are only feasible for tiny inputs. If you see these in a solution, look for dynamic programming or pruning to reduce the class.
