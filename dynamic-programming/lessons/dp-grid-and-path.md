---
title: "Grid and Path DP"
summary: "DP on grids: minimum path sum, unique paths, obstacle handling, in-place space optimization, and longest increasing path."
reading_time_minutes: 4
order: 5
---

## Why This Matters

Grid DP problems are visually intuitive -- the DP table IS the grid itself. They reinforce two-dimensional state thinking from string DP but in a more concrete domain. Unique paths and minimum path sum are extremely common interview problems. Understanding why movement restrictions make DP valid (and greedy invalid) is the conceptual key to this entire problem family.

## Why DP Works on Restricted-Movement Grids

In most grid problems, movement is restricted to specific directions -- typically only right and down. This restriction is not incidental. It **eliminates cycles**.

Without cycles, every path through the grid is a DAG (directed acyclic graph). Each cell can only be reached from a fixed set of predecessor cells. This is exactly the condition DP requires: you can compute each cell's answer once, in a fixed order, and each cell depends only on already-computed cells.

A greedy approach fails because the locally cheapest next step might lead to an expensive later path. DP evaluates all paths by building up optimal subpaths.

## Minimum Path Sum

**Problem:** Find the path from the top-left to bottom-right of an m x n grid that minimizes the sum of values along the path. Movement: right or down only.

**State:** `dp[i][j]` = minimum sum to reach cell (i, j).

**Recurrence:**
```
dp[i][j] = grid[i][j] + min(dp[i-1][j], dp[i][j-1])
```

Each cell is reached from above or from the left. Take the cheaper predecessor.

**Base cases:**
- `dp[0][0] = grid[0][0]`
- First row: `dp[0][j] = dp[0][j-1] + grid[0][j]` (can only come from left)
- First column: `dp[i][0] = dp[i-1][0] + grid[i][0]` (can only come from above)

**Time:** O(m * n), **Space:** O(m * n).

### In-Place Optimization (O(1) extra space)

Modify the grid directly by overwriting each cell with its minimum sum:

```
for i from 0 to m-1:
    for j from 0 to n-1:
        if i == 0 and j == 0: continue
        elif i == 0: grid[i][j] += grid[i][j-1]
        elif j == 0: grid[i][j] += grid[i-1][j]
        else: grid[i][j] += min(grid[i-1][j], grid[i][j-1])
```

The answer is `grid[m-1][n-1]`. This works because each cell is only needed after its value has been updated.

## Unique Paths

**Problem:** Count the number of distinct paths from top-left to bottom-right of an m x n grid, moving only right or down.

**Recurrence:**
```
dp[i][j] = dp[i-1][j] + dp[i][j-1]
```

Each cell is the sum of paths arriving from above and from the left (counting, not optimizing -- addition, not min/max).

**Base cases:** `dp[0][j] = 1` and `dp[i][0] = 1` (only one way to traverse any first row or column).

**Mathematical shortcut:** You must make exactly (m-1) down moves and (n-1) right moves in any order. The answer is C(m+n-2, m-1) -- choose which steps are "down" from total steps.

## Unique Paths with Obstacles

**Problem:** Same as unique paths, but some cells contain obstacles. Paths cannot pass through obstacles.

**Recurrence:** Same as unique paths, but set `dp[i][j] = 0` if `grid[i][j] == 1` (obstacle).

```
if grid[i][j] == 1:
    dp[i][j] = 0    # obstacle: no path passes through here
else:
    dp[i][j] = dp[i-1][j] + dp[i][j-1]
```

**Base cases:** `dp[0][0] = 1` if no obstacle; `dp[0][j]` and `dp[i][0]` become 0 as soon as they hit an obstacle (an obstacle in the first row blocks all cells to its right).

## The Triangle Problem

**Problem:** Given a triangle of numbers, find the path from top to bottom that minimizes the sum, where from each element you can move to the two adjacent elements in the row below.

**Bottom-up approach:** Start from the second-to-last row and work up. For each cell, add the minimum of the two values below it. No boundary handling needed because both neighbors always exist when iterating bottom-up.

```
for i from n-2 down to 0:
    for j from 0 to i:
        triangle[i][j] += min(triangle[i+1][j], triangle[i+1][j+1])
return triangle[0][0]
```

Top-down would require handling row boundaries (the leftmost and rightmost cells each have only one valid predecessor).

## Longest Increasing Path in a Matrix

**Problem:** Find the length of the longest strictly increasing path in an m x n matrix, where movement is allowed in all four directions.

**Why not pure tabulation?** There is no fixed topological order for the cells -- the valid movement directions depend on the actual values, which can go up, down, left, or right. The DP order is determined by the values themselves, not the cell positions.

**Solution:** DFS with memoization. For each cell, explore all four neighbors that have a strictly larger value. Cache the result for each cell.

```
memo = {}
def dfs(i, j):
    if (i, j) in memo: return memo[(i, j)]
    best = 1
    for (ni, nj) in neighbors(i, j):
        if matrix[ni][nj] > matrix[i][j]:
            best = max(best, 1 + dfs(ni, nj))
    memo[(i, j)] = best
    return best
return max(dfs(i, j) for all cells)
```

No cycle is possible because each step must go strictly upward in value. This guarantees termination.

## Key Takeaways

- **Restricted movement (right/down only)** creates a DAG -- no cycles -- making tabulation possible with a fixed iteration order.
- **Minimum path sum recurrence:** `dp[i][j] = grid[i][j] + min(dp[i-1][j], dp[i][j-1])`.
- **Base cases:** first row and column are prefix sums -- only one direction available.
- **In-place grid modification** gives O(1) extra space when the original values aren't needed.
- **Unique paths** counts (addition) rather than optimizes (min/max); answer is also C(m+n-2, m-1).
- **Longest increasing path** requires memoized DFS, not tabulation, because the topological order depends on values, not positions.
