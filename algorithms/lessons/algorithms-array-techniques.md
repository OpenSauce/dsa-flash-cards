---
title: "Array Techniques"
summary: "Three interview staple patterns for array problems: two-pointer, sliding window, and prefix sum. How each reduces brute force O(n^2) to O(n)."
reading_time_minutes: 5
order: 5
---

## Why This Matters

Most coding interviews start with an array problem. Brute force solutions are usually O(n^2) -- check every pair, check every subarray. Two-pointer, sliding window, and prefix sum are the three patterns that collapse those nested loops into a single pass. Recognizing which pattern applies is often the entire interview.

## Two-Pointer Technique

Use two indices that move through the array based on a condition. The most common variants:

### Opposite-Direction Pointers

One pointer starts at the beginning, one at the end, and they move toward each other.

```
left = 0
right = n - 1
while left < right:
    if condition met:
        return result
    if need larger sum:
        left += 1
    else:
        right -= 1
```

**Classic problem:** find a pair in a sorted array that sums to a target. If the sum is too small, advance the left pointer (increase). If too large, advance the right pointer (decrease). O(n) instead of O(n^2).

**Precondition:** the array must be sorted (or the structure must give a monotonic property that tells you which pointer to move).

### Same-Direction Pointers (Fast/Slow)

Both pointers start at the beginning. The fast pointer advances every step; the slow pointer advances only when a condition is met.

**Classic problems:**
- Remove duplicates from a sorted array in-place. Slow pointer marks the write position; fast pointer scans ahead.
- Linked list cycle detection (Floyd's algorithm). Fast moves two steps, slow moves one. If they meet, there is a cycle.

**Precondition:** varies. Sorted input for deduplication, linked list structure for cycle detection.

### When Two-Pointer Does Not Apply

Two-pointer needs a condition that tells you which pointer to move -- typically a sorted order or a monotonic relationship. For unsorted pair-sum problems, a hash set in O(n) is usually better than sorting (O(n log n)) + two-pointer (O(n)).

## Sliding Window

Maintain a window (contiguous subarray or substring) and slide it across the input, updating state incrementally.

### Fixed-Size Window

The window always has exactly k elements. Slide right by adding one element and removing one.

```
windowSum = sum of first k elements
best = windowSum
for i from k to n - 1:
    windowSum += arr[i]       // add new element
    windowSum -= arr[i - k]   // remove leftmost element
    best = max(best, windowSum)
```

O(n) instead of O(nk). Each element enters and leaves the window exactly once.

**Classic problem:** maximum sum subarray of size k.

### Variable-Size Window

The window expands by advancing the right pointer and shrinks by advancing the left pointer. The window grows until a constraint is violated, then shrinks until the constraint is restored.

```
left = 0
for right from 0 to n - 1:
    add arr[right] to window state
    while window violates constraint:
        remove arr[left] from window state
        left += 1
    update answer
```

O(n) because left and right each advance at most n times total.

**Classic problems:** longest substring without repeating characters, minimum window substring containing all target characters.

### When Sliding Window Does Not Apply

Sliding window requires contiguity. If the problem asks about non-contiguous subsequences (e.g., longest increasing subsequence), sliding window cannot help. It also requires that expanding the window can only make the constraint harder to satisfy (monotonic relationship), so shrinking the window always helps restore feasibility.

## Prefix Sum

Precompute cumulative sums so that any range sum can be answered in O(1).

### Building the Prefix Sum Array

```
prefix[0] = 0
for i from 0 to n - 1:
    prefix[i + 1] = prefix[i] + arr[i]
```

The prefix array has n + 1 elements. `prefix[i]` stores the sum of `arr[0..i-1]`.

### Range Sum Query

The sum of elements from index `l` to `r` (inclusive) is:

```
sum(l, r) = prefix[r + 1] - prefix[l]
```

O(n) build, O(1) per query. Worth it when you have many range queries on static data.

### Applications Beyond Range Sums

- **Subarray sum equals k:** for each index, check if `prefix[i] - k` exists in a hash set of previously seen prefix sums. O(n) total.
- **2D prefix sums:** extend to matrices for O(1) rectangle sum queries after O(mn) preprocessing.

### When Prefix Sum Does Not Apply

Prefix sum assumes the underlying array is static. If the array is updated between queries, a Fenwick tree (binary indexed tree) or segment tree handles both updates and queries in O(log n).

## Key Takeaways

- Two-pointer reduces pair/subarray problems on sorted data from O(n^2) to O(n). Opposite-direction for pair problems, same-direction for in-place modifications.
- Sliding window handles contiguous subarray/substring problems in O(n) by incrementally updating window state. Fixed-size for known k, variable-size for constraint-based problems.
- Prefix sum precomputes cumulative sums for O(1) range queries after O(n) build. Extend with hash sets for subarray-sum-equals-k problems.
- All three techniques exploit structure (sorting, contiguity, cumulative sums) to avoid nested loops.
