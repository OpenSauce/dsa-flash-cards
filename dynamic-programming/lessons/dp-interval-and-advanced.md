---
title: "Interval DP and Advanced Patterns"
summary: "Interval DP (matrix chain, burst balloons), LIS in O(n log n), state machine DP (stock cooldown), bitmask DP, and pattern recognition heuristics."
reading_time_minutes: 5
order: 6
---

## Why This Matters

After mastering 1D, knapsack, string, and grid DP, you're ready for the harder patterns. Interval DP has a non-obvious iteration order (by subrange length, not by left endpoint). State machine DP requires modeling explicit states. Bitmask DP handles exponential state spaces compactly. Knowing which pattern fits a new problem is its own skill -- this lesson closes with recognition heuristics.

## Interval DP

**Pattern:** The state is a contiguous subrange `[left, right]`. The answer is computed by trying all possible split points within that range.

**Template:**
```
for length from 2 to n:              # start from smallest intervals
    for left from 0 to n - length:
        right = left + length - 1
        dp[left][right] = infinity
        for split from left to right - 1:
            dp[left][right] = min(dp[left][right],
                                  f(dp[left][split], dp[split+1][right], split))
```

### Why Iterate by Length, Not by Left Endpoint

If you iterate by left endpoint (outer loop: left, inner: right), when you compute `dp[left][right]` you need `dp[left][split]` for split < right. This sub-interval has the same left endpoint but a smaller right endpoint -- it may not have been computed yet.

By iterating by **length**, all intervals of length k-1 are fully computed before you compute any interval of length k. This guarantees every dependency exists.

### Matrix Chain Multiplication

**Problem:** Given matrices M1, M2, ..., Mn, find the order of multiplying them that minimizes the total number of scalar multiplications. Parenthesization doesn't change the result, only the cost.

**State:** `dp[i][j]` = minimum cost to multiply matrices i through j.

**Split:** try every matrix Mk as the last multiplication -- split the chain into (i..k) and (k+1..j):

```
dp[i][j] = min over k from i to j-1 of:
    dp[i][k] + dp[k+1][j] + dims[i-1] * dims[k] * dims[j]
```

where `dims[i-1] * dims[k] * dims[j]` is the cost of multiplying the two result matrices.

**Base case:** `dp[i][i] = 0` (one matrix, no multiplication needed).

### Burst Balloons

**Problem:** Given n balloons with values, burst them one at a time. Bursting balloon k earns `val[k-1] * val[k] * val[k+1]` (neighbors at time of bursting). Find the maximum coins.

**Interval DP insight:** Instead of thinking about which balloon to burst first (hard -- it changes neighbors), think about which balloon to burst **last** within a range. The last balloon to burst in `[left, right]` still has its boundary neighbors `val[left-1]` and `val[right+1]` intact.

```
dp[left][right] = max over k from left to right of:
    dp[left][k-1] + val[left-1] * val[k] * val[right+1] + dp[k+1][right]
```

This "think last" inversion is the key insight of burst balloons interval DP.

## LIS in O(n log n): Patience Sorting

The O(n^2) DP for LIS (`dp[i] = max(dp[j]+1)` for j < i with arr[j] < arr[i]`) can be improved.

**Patience sorting approach:** Maintain a `tails` array where `tails[k]` is the smallest tail element of all increasing subsequences of length k+1. For each new element:
- If it's larger than all tails, append it (extends the longest subsequence).
- Otherwise, binary search for the leftmost tail it can replace (it creates a better subsequence of that length with a smaller tail).

```
tails = []
for x in arr:
    pos = bisect_left(tails, x)    # find leftmost position where tails[pos] >= x
    if pos == len(tails):
        tails.append(x)            # extends the longest
    else:
        tails[pos] = x             # better tail for subsequence of length pos+1
return len(tails)
```

**Why the greedy insight works:** A smaller tail for a given length is strictly better -- it's easier to extend. Replacing a larger tail with a smaller one never hurts and can only help future elements.

**Time:** O(n log n), **Space:** O(n). Note: `tails` is not the actual LIS, just its length. Reconstructing the actual subsequence requires additional bookkeeping.

## State Machine DP

**Pattern:** Model a problem as a set of distinct states with transitions between them. `dp[state]` = optimal value when currently in that state.

**Stock trading with cooldown (buy/sell with 1-day cooldown after selling):**

States:
- `held`: you currently hold a stock
- `sold`: you just sold today (next day you must rest)
- `rest`: you are in cooldown or simply not holding

Transitions:
- `held[i] = max(held[i-1], rest[i-1] - price[i])` -- keep holding or buy from rest state
- `sold[i] = held[i-1] + price[i]` -- sell what you hold
- `rest[i] = max(rest[i-1], sold[i-1])` -- stay resting or enter rest after cooldown

**Base cases:** `held[-1] = -infinity`, `sold[-1] = 0`, `rest[-1] = 0`.

Answer: `max(sold[n-1], rest[n-1])` (can't end while holding for maximum profit).

**When to use:** problems with phases or modes that constrain what you can do next, especially "stock" problems, lock/unlock states, or cooldown constraints.

## Bitmask DP

**Concept:** When the state includes a subset of items (e.g., which cities have been visited in TSP), encode the subset as a bitmask. Bit k is 1 if item k is in the set.

**State:** `dp[mask][v]` = minimum cost to visit exactly the cities in `mask`, ending at city v.

```
for mask from 0 to 2^n - 1:
    for last in cities where bit is set in mask:
        for next in cities where bit is NOT set in mask:
            new_mask = mask | (1 << next)
            dp[new_mask][next] = min(dp[new_mask][next], dp[mask][last] + dist[last][next])
```

**Time:** O(2^n * n^2), **Space:** O(2^n * n). Practical for n <= 20.

**Bitmask DP encodes:** the set of items/nodes already processed. Each bit is a boolean flag for one item.

## Pattern Recognition Heuristics

When you see a new DP problem, ask these questions in order:

1. **Single sequence, optimize prefix?** -> Linear DP (house robber, climbing stairs, Kadane's).
2. **Items + capacity constraint?** -> Knapsack family (each item once = 0/1, unlimited = unbounded).
3. **Two strings/sequences?** -> 2D DP indexed `(i, j)` into both strings (LCS, edit distance).
4. **Grid, restricted movement?** -> Grid DP (min path sum, unique paths).
5. **Contiguous subrange, try all splits?** -> Interval DP (matrix chain, burst balloons).
6. **Explicit modes/states with constrained transitions?** -> State machine DP (stock problems).
7. **Need to track a subset of n <= 20 items?** -> Bitmask DP (TSP, assignment).

If none fit, look for the decision tree: what choices do you make at each step? The state is everything needed to make the next decision optimally.

## Key Takeaways

- **Interval DP:** state is `(left, right)`, iterate by subrange length to guarantee dependencies are ready.
- **Matrix chain:** split at every k; cost is `dp[i][k] + dp[k+1][j] + multiply_cost`.
- **Burst balloons:** think about the *last* balloon to burst in a range, not the first.
- **LIS O(n log n):** maintain `tails` array of best (smallest) tail per subsequence length; binary search for each new element.
- **State machine DP:** define states explicitly, write transition equations between states.
- **Bitmask DP:** bitmask encodes which items are in the current subset; practical for n <= 20.
- Pattern recognition: check linear -> knapsack -> two-string -> grid -> interval -> state machine -> bitmask in order.
