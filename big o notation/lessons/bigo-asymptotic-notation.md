---
title: "Asymptotic Notation"
order: 1
summary: "What Big O is and why we use it. Growth rate intuition. O, Omega, Theta notation. Best/average/worst case versus asymptotic bounds. Dropping constants and lower-order terms."
---

## Why This Matters

When you write an algorithm, two questions matter more than any language choice or micro-optimization: how does the runtime grow as input size grows, and how much memory does it use? Asymptotic notation gives you a precise, hardware-independent vocabulary for answering both. Every complexity claim in a coding interview — "binary search is O(log n)," "merge sort is O(n log n)" — relies on this foundation.

## What Big O Actually Describes

Big O notation describes an **upper bound on a function's growth rate** as input size n approaches infinity. When we say an algorithm is O(f(n)), we mean: beyond some threshold n₀, the algorithm's resource use (time or space) never exceeds c · f(n) for some constant c.

Two things to internalize immediately:

1. **Big O is about growth rate, not exact runtime.** An algorithm that takes 10,000 steps for n=100 and 20,000 steps for n=200 is O(n). The constants (10,000, c=100 steps-per-unit) are irrelevant to the notation.

2. **Big O is an upper bound, not a worst-case claim.** This is the most common misconception. Big O describes how the cost grows; it says nothing about which input triggers the worst case. An algorithm can be O(n) in its best case and O(n) in its worst case simultaneously — or O(1) best case and O(n) worst case.

## The Three Asymptotic Notations

| Notation | Reads as | Means |
|---|---|---|
| O(f(n)) | "big O of f(n)" | Upper bound — growth is at most f(n) |
| Ω(f(n)) | "omega of f(n)" | Lower bound — growth is at least f(n) |
| Θ(f(n)) | "theta of f(n)" | Tight bound — growth is exactly f(n) |

In practice, engineers say "O(n)" when they mean "this algorithm grows linearly." Formally, they often mean Θ(n) (a tight bound), but Big O notation is used colloquially for both. When precision matters, Θ distinguishes "exactly linear" from "at most linear."

Example: Insertion sort on a sorted array is Ω(n) (must check every element) and O(n) (no swaps needed), so it is Θ(n). On a reverse-sorted array, it is Θ(n²). The Big O of insertion sort across all inputs is O(n²).

## Best, Average, and Worst Case

These describe **which input** we are analyzing, not the asymptotic notation itself. They are orthogonal concepts:

- **Best case:** the most favorable possible input (e.g., sorted array for insertion sort)
- **Average case:** average over a distribution of inputs (often the hardest to compute)
- **Worst case:** the most expensive possible input

You can apply any asymptotic notation (O, Ω, Θ) to any case. "Worst-case O(n²)" and "best-case O(n)" are both valid statements about the same algorithm. When someone says "this algorithm is O(n log n)" without qualification, they almost always mean worst-case O(n log n).

## Dropping Constants and Lower-Order Terms

Asymptotic analysis ignores constants and lower-order terms because they become irrelevant as n grows large:

- O(3n) → O(n)
- O(n² + 5n + 100) → O(n²)
- O(2 log n) → O(log n)

Why? At n = 1,000,000, a 3x constant factor matters far less than whether your algorithm is O(n) versus O(n²). The growth *shape* is what determines scalability.

This does not mean constants are irrelevant in practice — an O(n) algorithm with a constant of 10,000 might be slower than O(n²) for small n. But for asymptotic analysis, which measures behavior as n → ∞, constants drop out.

```
Growth of common functions (n = 1,000):

O(1)       → 1 operation
O(log n)   → ~10 operations
O(n)       → 1,000 operations
O(n log n) → ~10,000 operations
O(n²)      → 1,000,000 operations
O(2ⁿ)      → 10^301 operations  (computationally impossible)
```

At n=1,000, O(2ⁿ) algorithms are not just slow — they are physically impossible. That gap is why understanding growth rates matters more than any constant-factor optimization.

## Key Takeaways

- Big O is an **upper bound on growth rate**, not exact runtime.
- Big O ≠ worst case. They are independent concepts. Big O describes growth; worst/best/average case describes which input.
- Ω is a lower bound; Θ is a tight (exact) bound. In practice, O is used informally to mean Θ.
- Drop constants and lower-order terms: O(5n² + 3n + 7) = O(n²).
- Asymptotic analysis shows behavior as n → ∞. Small-n constant factors can dominate in practice, but growth rate determines scalability.
