---
title: "Knapsack and Subset Problems"
summary: "The knapsack pattern family: 0/1 knapsack, unbounded knapsack (coin change), subset sum, and partition equal subset sum."
reading_time_minutes: 5
order: 3
---

## Why This Matters

The knapsack pattern is the most commonly tested DP family in technical interviews. Recognizing that a problem is a knapsack variant is half the battle -- once you do, the recurrence and space optimization follow a known template. This lesson covers the full family: 0/1 knapsack, unbounded knapsack, subset sum, and the reduction from partition equal subset sum to knapsack.

## 0/1 Knapsack

**Problem:** Given n items each with a weight and value, and a knapsack with capacity W, maximize total value without exceeding the weight limit. Each item can be taken at most once.

**State:** `dp[i][w]` = maximum value using the first i items with remaining capacity w.

**Decision:** For each item i, either skip it (value doesn't change, capacity unchanged) or take it (add its value, reduce remaining capacity by its weight):

```
dp[i][w] = max(
    dp[i-1][w],                          # skip item i
    dp[i-1][w - weight[i]] + value[i]    # take item i (if weight[i] <= w)
)
```

**Base case:** `dp[0][w] = 0` for all w (no items, no value).

**Time:** O(n * W), **Space:** O(n * W).

### Space Optimization: Single Row, Right-to-Left

Reduce to O(W) by keeping one row and iterating capacity right-to-left:

```
dp = array of size W+1, all zeros
for each item i:
    for w from W down to weight[i]:
        dp[w] = max(dp[w], dp[w - weight[i]] + value[i])
```

**Why right-to-left?** When computing `dp[w]`, you need `dp[w - weight[i]]` to reflect the state *before* item i was considered (from the previous row). Iterating right-to-left ensures that smaller capacities haven't been updated yet in this pass, so `dp[w - weight[i]]` still holds the previous-row value.

If you iterate left-to-right, `dp[w - weight[i]]` may already be updated in this pass, effectively counting item i twice -- turning 0/1 knapsack into unbounded knapsack.

## Unbounded Knapsack

**Problem:** Same as 0/1 knapsack, but each item can be used unlimited times.

The change: iterate capacity **left-to-right**. This lets `dp[w - weight[i]]` reflect the current item already being included, allowing it to be reused.

```
for each item i:
    for w from weight[i] to W:
        dp[w] = max(dp[w], dp[w - weight[i]] + value[i])
```

**Coin change -- minimum coins (unbounded):**
Each coin denomination can be used unlimited times.

```
dp[0] = 0
dp[1..amount] = infinity
for each coin:
    for a from coin to amount:
        dp[a] = min(dp[a], dp[a - coin] + 1)
```

Answer: `dp[amount]` (or -1/infinity if unreachable).

**Coin change -- number of combinations (unbounded):**
Count distinct combinations (not permutations -- order doesn't matter).

```
dp[0] = 1
for each coin:
    for a from coin to amount:
        dp[a] += dp[a - coin]
```

The outer loop iterates over coins, the inner over amounts. This ensures each combination is counted once regardless of order. If you swap the loops (outer: amount, inner: coin), you count permutations instead.

## Subset Sum as Boolean Knapsack

**Problem:** Given a set of numbers, determine whether any subset sums to a target T.

This is 0/1 knapsack where "value = weight" and you only care about feasibility, not the optimal value.

**State:** `dp[j]` = true if some subset of processed items sums to exactly j.

```
dp[0] = true
dp[1..T] = false
for each num:
    for j from T down to num:    # right-to-left: each item used at most once
        dp[j] = dp[j] || dp[j - num]
```

Each cell answers: "can I make exactly this sum?" rather than "what's the maximum value I can achieve?"

## Partition Equal Subset Sum

**Problem:** Can you partition an array into two subsets with equal sum?

**Reduction chain:**
1. If `total_sum` is odd, return false immediately (impossible to split evenly).
2. Target = `total_sum / 2`.
3. Find a subset that sums to `target` -- this is the subset sum problem.
4. Subset sum is 0/1 knapsack (boolean version).

```
target = sum(nums) // 2
dp = [false] * (target + 1)
dp[0] = true
for num in nums:
    for j from target down to num:
        dp[j] = dp[j] || dp[j - num]
return dp[target]
```

The ability to recognize and articulate this reduction chain ("partition -> subset sum -> 0/1 knapsack") is what interviewers are testing.

## Recognizing Knapsack Variants

A problem is a knapsack variant when:
1. You have a **collection of items** to consider one by one.
2. Each item is **included or excluded** (or included a bounded number of times).
3. There is a **capacity constraint** (weight, sum, budget).
4. You want to **optimize a value** subject to the constraint, or check **feasibility**.

The key question to ask: "Can I use each item at most once (0/1), or unlimited times (unbounded)?" This determines iteration direction.

| Variant | Each item used | Iteration direction | Example |
|---|---|---|---|
| 0/1 Knapsack | At most once | Right-to-left | Partition equal subset sum |
| Unbounded Knapsack | Unlimited times | Left-to-right | Coin change (min coins) |
| Subset Sum | At most once | Right-to-left | Subset sum feasibility |

## Key Takeaways

- **0/1 knapsack recurrence:** `dp[w] = max(dp[w], dp[w - wt] + val)`, iterated right-to-left.
- **Unbounded knapsack:** same recurrence, but iterated left-to-right to allow reuse.
- **Right-to-left prevents double-counting** (0/1); left-to-right enables reuse (unbounded).
- **Subset sum** is boolean 0/1 knapsack: replace max/value with OR/feasibility.
- **Partition equal subset sum** reduces to: odd total -> false; even total -> subset sum with target = total/2.
- Recognize the pattern by asking: items chosen with a capacity constraint? -> knapsack family.
