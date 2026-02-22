---
title: "The DP Problem-Solving Framework"
summary: "A systematic 5-step approach to any DP problem: state definition, recurrence, base cases, iteration order, and space optimization."
reading_time_minutes: 5
order: 1
---

## Why This Matters

If you already know what dynamic programming *is* (overlapping subproblems, optimal substructure -- covered in the Algorithms category), the next challenge is knowing *how to approach* a DP problem you've never seen before. Without a systematic method, you end up pattern-matching against memorized examples. With a framework, you can derive the solution from first principles.

This lesson teaches that framework. Every DP problem in the remaining lessons is solved using these same five steps.

> New to DP? Start with the Algorithms category's DP Introduction lesson first, then return here.

## The 5-Step Framework

### Step 1: Define the State

A **state** is a minimal set of variables that uniquely describes a subproblem. The state answers: "What do I need to know to solve a subproblem?"

For the climbing stairs problem (reach step n taking 1 or 2 steps at a time):
- The only thing that matters is which step you're currently on.
- State: `dp[i]` = number of ways to reach step i.

Ask yourself: "If I'm solving a subproblem, what information do I need -- and nothing more?" Extra variables in the state inflate the table size; missing variables make the recurrence wrong.

### Step 2: Write the Recurrence

A **recurrence relation** expresses the current state in terms of smaller states. It encodes the decision you make at each step.

For climbing stairs, at step i you arrived from either step i-1 (one step) or step i-2 (two steps):

```
dp[i] = dp[i-1] + dp[i-2]
```

The recurrence comes from the decision: what are the last things that happened before reaching this state?

### Step 3: Identify Base Cases

**Base cases** are states small enough to answer directly, without the recurrence. They anchor the computation.

For climbing stairs:
```
dp[0] = 1   (one way to stand at the bottom: do nothing)
dp[1] = 1   (one way to reach step 1: take one step)
```

A common bug is missing a base case or setting it to the wrong value. Always verify: "Does the recurrence break down at the boundary? What's the answer there directly?"

### Step 4: Determine Iteration Order

For **tabulation (bottom-up)**, you must fill the table so that every dependency is computed before it's needed.

For climbing stairs, `dp[i]` depends on `dp[i-1]` and `dp[i-2]`, so iterate i from 2 to n.

For a 2D table (like LCS), the direction matters: if `dp[i][j]` depends on `dp[i-1][j-1]`, `dp[i-1][j]`, and `dp[i][j-1]`, iterate i left to right, j top to bottom.

For **memoization (top-down)**, iteration order is implicit -- the recursion handles it. The tradeoff: memoization is easier to write, tabulation avoids stack overflow and has better cache behavior.

### Step 5: Optimize Space

Many DP solutions use more space than necessary. Two patterns cover most optimizations:

**Rolling array:** If `dp[i]` only depends on the previous one or two rows/entries, discard earlier rows.

For climbing stairs, `dp[i]` depends on `dp[i-1]` and `dp[i-2]`. You only need two variables:

```
prev2 = 1  (dp[i-2])
prev1 = 1  (dp[i-1])
for i from 2 to n:
    curr = prev1 + prev2
    prev2 = prev1
    prev1 = curr
return prev1
```

Space drops from O(n) to O(1).

**Row compression:** For 2D DP where each row depends only on the previous row, keep a single 1D array and update it in-place (iterating carefully to avoid using updated values prematurely).

## Converting Memoization to Tabulation

Every memoized solution can be mechanically converted to tabulation:

1. Replace the recursive function with a loop.
2. Iterate in reverse topological order (smallest subproblems first).
3. Replace the cache lookup with a table access.
4. The recurrence stays the same.

The climbing stairs memoized version:
```
memo = {}
def ways(n):
    if n <= 1: return 1
    if n in memo: return memo[n]
    memo[n] = ways(n-1) + ways(n-2)
    return memo[n]
```

Becomes the tabulation version by iterating i from 2 to n and filling `dp[i]` directly.

## When NOT to Use DP

DP applies when subproblems overlap (the same subproblem is solved repeatedly in the naive recursion). It does NOT apply when:

- **No overlapping subproblems:** Binary search, merge sort, and quicksort use divide and conquer with non-overlapping subproblems. Caching would waste memory with no benefit.
- **Greedy works:** If a locally optimal choice is always globally optimal (e.g., interval scheduling by earliest finish time, Dijkstra's for non-negative weights), greedy is simpler and faster.
- **The problem has no optimal substructure:** The optimal solution to the whole problem can't be built from optimal solutions to subproblems.

Draw the recursion tree for a small input. If you see repeated nodes, DP applies. If every node is unique, it doesn't.

## Key Takeaways

- The 5 steps: define the state, write the recurrence, identify base cases, determine iteration order, optimize space.
- The state encodes exactly what you need to solve a subproblem -- no more, no less.
- The recurrence comes from asking "what decision was made last, and what did it cost?"
- Convert memoization to tabulation by iterating in topological order.
- DP only applies when subproblems overlap. When greedy works, use greedy.
