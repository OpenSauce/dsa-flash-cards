---
title: "Analyzing Code Complexity"
order: 3
summary: "How to derive time complexity from code: sequential operations, single loops, nested loops, logarithmic patterns, and amortized analysis."
---

## Why This Matters

Memorizing complexity values for standard algorithms is not enough. Interviews regularly ask you to analyze novel code or to justify why your solution has a given complexity. The ability to read a block of code and derive its complexity from first principles is a core skill — and it is entirely learnable by applying four rules consistently.

## Rule 1: Sequential Operations — Add

When two blocks of code run one after the other, their complexities add:

```
block A: O(n)
block B: O(n²)
total:   O(n + n²) = O(n²)  [drop lower-order term]
```

In practice, sequential operations reduce to the dominant term. Two O(n) passes over the same array is still O(n), not O(2n).

## Rule 2: Nested Loops — Multiply

When one loop is inside another, their complexities multiply:

```
for i in range(n):       # O(n)
    for j in range(n):   # O(n)
        do_work()        # O(1)
```

Total: O(n) × O(n) = O(n²).

If the inner loop runs m times instead of n:

```
for i in range(n):       # O(n)
    for j in range(m):   # O(m)
        do_work()        # O(1)
```

Total: O(n × m). If m is independent of n, this stays O(n × m). If m = n, it's O(n²). If m is a constant, it collapses to O(n).

### Triangular loops

A common variant: inner loop runs fewer iterations each time.

```
for i in range(n):
    for j in range(i):
        do_work()
```

The inner loop runs 0, 1, 2, ..., n−1 iterations. Total work: 0 + 1 + 2 + ... + (n−1) = n(n−1)/2. Dominant term: n²/2 → **O(n²)**.

## Rule 3: Logarithmic Pattern — Halving

An algorithm is O(log n) when each step eliminates half (or some constant fraction) of the remaining problem:

```
low, high = 0, n - 1
while low <= high:
    mid = (low + high) // 2
    if target == arr[mid]:
        return mid
    elif target < arr[mid]:
        high = mid - 1
    else:
        low = mid + 1
```

Each iteration halves the search space. Starting from n, the space reaches 1 after log₂(n) iterations. **O(log n).**

The same pattern appears in any algorithm that repeatedly divides by a constant:
- Binary search: halving
- Balanced BST traversal: halving
- Heap sift-up/sift-down: moves through log n levels

## Rule 4: Recursive Complexity — Count the Work

For recursive functions, the total work is: **(number of recursive calls) × (work per call)**.

Simple recursion — each call reduces n by 1:

```
function factorial(n):
    if n == 0: return 1
    return n * factorial(n - 1)
```

n calls, O(1) work each → **O(n)**.

Divide and conquer — each call splits n into two halves, then does O(n) merge work:

```
function mergeSort(arr):
    if len(arr) <= 1: return arr
    mid = len(arr) // 2
    left = mergeSort(arr[:mid])
    right = mergeSort(arr[mid:])
    return merge(left, right)  # O(n) work
```

The recurrence is T(n) = 2T(n/2) + O(n). This resolves to **O(n log n)**: there are log n levels of recursion, and each level does O(n) total merge work.

Exponential recursion — each call branches into two calls of size n−1:

```
function fib(n):
    if n <= 1: return n
    return fib(n - 1) + fib(n - 2)
```

Two calls per invocation, depth n → roughly 2ⁿ calls → **O(2ⁿ)**. Memoization collapses this to O(n).

## Amortized Analysis

Some operations are occasionally expensive but cheap on average over a sequence of calls. The per-call cost, averaged across many operations, is the **amortized cost**.

Classic example: dynamic array append.

- Most appends: O(1) — add to end of existing capacity.
- Occasional append: O(n) — the array is full, so it doubles and copies all n elements.

But resizes happen at sizes 1, 2, 4, 8, ..., n. Total copy work: 1 + 2 + 4 + ... + n ≈ 2n. Over n append operations, total work is O(n), so the amortized cost per append is **O(1)**.

The distinction matters in interviews: "append is O(1) amortized" is precise. "Append is always O(1)" is wrong — individual worst-case appends are O(n).

## Putting It Together: Walk-Through Example

```
function twoSumSorted(arr, target):
    left, right = 0, len(arr) - 1
    while left < right:
        sum = arr[left] + arr[right]
        if sum == target:
            return [left, right]
        elif sum < target:
            left += 1
        else:
            right -= 1
    return []
```

- Single while loop over indices converging toward each other: at most n iterations → **O(n)**.
- Each iteration does O(1) work (array accesses, comparison, increment).
- No nested loops, no recursive calls.
- **Total: O(n) time, O(1) space.**

## Key Takeaways

- Sequential operations: add complexities, drop lower-order terms.
- Nested loops: multiply complexities.
- Halving patterns (binary search, balanced tree traversal): O(log n).
- Recursive complexity = (number of calls) × (work per call). Recognize divide-and-conquer (O(n log n)) versus linear recursion (O(n)) versus exponential branching (O(2ⁿ)).
- Amortized O(1) means "cheap on average across many calls," not "always O(1)." Dynamic array append is the canonical example.
