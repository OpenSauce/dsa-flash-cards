---
title: "Searching"
summary: "Linear search, binary search and its variations (lower bound, upper bound, search on answer space), and hash-based lookup trade-offs."
reading_time_minutes: 6
order: 3
---

## Why This Matters

Searching is the complement of sorting. Once data is organized, you need to find things in it. Binary search alone accounts for a disproportionate share of interview questions -- not because the concept is hard, but because the implementation details are tricky and the technique generalizes far beyond "find a value in a sorted array."

## Linear Search

Scan each element from left to right until you find the target or reach the end.

- **Time:** O(n) worst and average. O(1) best (target is the first element).
- **Space:** O(1).
- **Precondition:** None. Works on unsorted data.

Linear search is the right choice when the data is small, unsorted, and searched infrequently. The overhead of sorting (O(n log n)) or building a hash table (O(n) time and space) is not justified if you are only searching once or twice.

```python
def linear_search(arr, target):
    for i, val in enumerate(arr):
        if val == target:
            return i
    return -1

print(linear_search([4, 2, 7, 1], 7))  # 2
```

## Binary Search

Repeatedly halve the search space by comparing the target to the middle element. Requires sorted input.

- **Time:** O(log n).
- **Space:** O(1) iterative, O(log n) recursive.
- **Precondition:** The input must be sorted.

```python
def binary_search(arr, target):
    lo, hi = 0, len(arr) - 1
    while lo <= hi:
        mid = lo + (hi - lo) // 2  # avoids overflow
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            lo = mid + 1
        else:
            hi = mid - 1
    return -1  # not found

print(binary_search([1, 3, 5, 7, 9, 11], 7))  # 3
```

### The Off-by-One Trap

Binary search is famously error-prone. The most common bug is using `lo < hi` instead of `lo <= hi`. With `lo < hi`, you skip checking the last remaining element when `lo == hi`. The condition must match your update rules: if you set `hi = mid - 1`, use `lo <= hi`. If you set `hi = mid`, use `lo < hi`.

### Lower Bound and Upper Bound

Standard binary search finds *any* matching index. Variations find boundaries:

**Lower bound:** the first position where `arr[i] >= target`. Useful for "insert position" or "first occurrence."

**Upper bound:** the first position where `arr[i] > target`. Useful for "one past the last occurrence."

Together, upper bound minus lower bound gives the count of a value in a sorted array.

```python
from bisect import bisect_left, bisect_right

arr = [1, 2, 2, 2, 3, 4]
# Lower bound: first position where arr[i] >= 2
print(bisect_left(arr, 2))   # 1
# Upper bound: first position where arr[i] > 2
print(bisect_right(arr, 2))  # 4
# Count of 2s
print(bisect_right(arr, 2) - bisect_left(arr, 2))  # 3
```

### Binary Search on the Answer Space

Binary search does not require an array. If a problem has a monotonic condition -- "for values below X, the condition is false; at X and above, it is true" -- you can binary search on the answer space.

Example: "what is the minimum capacity to ship all packages within D days?" The feasibility check is monotonic (higher capacity always works if lower capacity does), so you binary search on capacity rather than iterating through every possibility.

This technique converts many optimization problems from O(n) or worse into O(log(range) * cost_of_check).

```python
def min_capacity_to_ship(weights, days):
    def can_ship(capacity):
        day_count, current_load = 1, 0
        for w in weights:
            if current_load + w > capacity:
                day_count += 1
                current_load = 0
            current_load += w
        return day_count <= days

    lo, hi = max(weights), sum(weights)
    while lo < hi:
        mid = (lo + hi) // 2
        if can_ship(mid):
            hi = mid
        else:
            lo = mid + 1
    return lo

print(min_capacity_to_ship([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 5))  # 15
```

## Hash-Based Lookup

A hash table maps keys to values using a hash function.

- **Time:** O(1) average for insert, delete, and lookup. O(n) worst case (all keys collide).
- **Space:** O(n).
- **Precondition:** None. Works on unsorted data.

Hash tables beat binary search on average-case lookup speed, but they use more memory and have no ordering. You cannot do range queries or find the "next larger element" with a hash table.

**When to choose each:**

| Need | Use |
|---|---|
| Single lookup in unsorted data | Hash table |
| Many lookups in sorted data | Binary search |
| Range queries or ordered iteration | Binary search / balanced BST |
| One-time lookup in small data | Linear search |

## Key Takeaways

- Linear search is O(n) and works on unsorted data. Appropriate for small or infrequently searched collections.
- Binary search is O(log n) but requires sorted input. The off-by-one bug is the most common implementation error.
- Lower/upper bound variations find boundaries instead of exact matches. Upper minus lower gives count.
- Binary search on the answer space applies to any problem with a monotonic feasibility condition.
- Hash lookup is O(1) average but O(n) space with no ordering. Binary search uses O(1) space and supports range queries.

## Related Problems

- **Binary Search** -- the direct application of this lesson
- **Best Time to Buy and Sell Stock** -- can be framed as searching for an optimal answer
