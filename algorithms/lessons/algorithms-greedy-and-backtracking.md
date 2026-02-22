---
title: "Greedy Algorithms and Backtracking"
summary: "Two algorithmic strategies: greedy (always pick the local optimum) and backtracking (explore and undo). When each works, classic examples, and their relationship to dynamic programming."
reading_time_minutes: 5
order: 6
---

## Why This Matters

Sorting and searching are specific algorithms. Greedy and backtracking are *strategies* -- general approaches for solving optimization and search problems. Recognizing whether a problem has greedy structure or requires exhaustive backtracking is a key skill in interviews, because it determines whether your solution is O(n log n) or O(2^n).

## Greedy Algorithms

A greedy algorithm builds a solution step by step, always choosing the option that looks best right now, without reconsidering past choices.

### When Greedy Works

A greedy approach produces an optimal solution when the problem has two properties:

**Greedy choice property:** a globally optimal solution can be reached by making locally optimal choices. You never need to undo a choice.

**Optimal substructure:** an optimal solution to the problem contains optimal solutions to its subproblems.

Both properties must hold. Optimal substructure alone is not enough -- dynamic programming problems also have optimal substructure, but they lack the greedy choice property (the locally optimal choice is not always globally optimal).

### Classic Example: Activity Selection

Given a set of activities with start and end times, select the maximum number of non-overlapping activities.

**Greedy strategy:** always pick the activity that finishes earliest. This leaves the most room for remaining activities.

**Why it works:** choosing the earliest-finishing activity never eliminates a better option. Any solution that picks a later-finishing activity could swap in the earlier one without reducing the count.

### Classic Example: Interval Scheduling / Merge Intervals

Sort intervals by start time. Merge overlapping intervals by extending the current interval's end when the next interval overlaps. This is greedy because processing intervals in sorted order and merging greedily produces the correct merged set in O(n log n).

### Greedy vs Dynamic Programming

Both require optimal substructure. The difference:

- **Greedy:** makes one choice per step, never revisits. Faster (often O(n log n) or O(n)).
- **DP:** considers all choices per step, picks the best after comparing subproblem results. Slower (often O(n^2) or O(n * W)).

If the greedy choice is always safe, use greedy. If you cannot prove the greedy choice is always optimal, you likely need DP.

**Example:** the coin change problem is greedy with standard US denominations (25, 10, 5, 1) but requires DP with arbitrary denominations (e.g., [1, 3, 4] -- greedy gives 4+1+1 = 3 coins for amount 6, but 3+3 = 2 coins is better).

## Backtracking

Backtracking explores all possible solutions by building candidates incrementally and abandoning a candidate ("backtracking") as soon as it violates a constraint.

### The Pattern

```
function backtrack(state):
    if state is a complete solution:
        record or return it
    for each choice in available choices:
        if choice is valid given current state:
            make the choice (modify state)
            backtrack(state)
            undo the choice (restore state)
```

The key operations: **choose**, **explore**, **unchoose**. The "unchoose" step is what makes it backtracking rather than plain recursion.

### Pruning

Backtracking is inherently exponential (it explores a tree of possibilities). **Pruning** skips branches that cannot lead to valid solutions, dramatically reducing the search space in practice.

Example: in N-queens, if placing a queen on row i creates a conflict, you skip all configurations that extend from that placement. Without pruning, N-queens is O(n!). With pruning, the practical search space is much smaller.

### Classic Examples

**Generating permutations:** build each permutation by choosing one unused element at a time. Backtrack by unmarking the element as used.

**Generating subsets:** for each element, choose to include it or not. This generates all 2^n subsets.

**N-queens:** place queens row by row. At each row, try each column. If the placement conflicts with an existing queen (same column, same diagonal), skip it. Otherwise, recurse to the next row and backtrack.

**Sudoku solver:** fill cells one at a time. For each empty cell, try digits 1-9. If a digit violates row, column, or box constraints, skip it. Otherwise, place it and recurse. Backtrack if no digit works.

### Backtracking vs Brute Force

Brute force generates all candidates and checks each one. Backtracking generates candidates incrementally and abandons bad ones early. The distinction is pruning: backtracking avoids exploring subtrees that cannot produce valid solutions.

### Backtracking Complexity

Without pruning, backtracking on n choices with branching factor b has O(b^n) time. Pruning reduces this in practice but does not change the worst case. Backtracking problems are typically NP-hard (no known polynomial-time solution), and the exponential cost is inherent.

## Recognizing the Strategy

| Signal in the problem | Strategy |
|---|---|
| "Maximize/minimize" with a simple rule that never needs revisiting | Greedy |
| "Find all" permutations, subsets, or configurations | Backtracking |
| "Find the optimal" and greedy fails on counterexamples | Dynamic programming |
| Constraint satisfaction (Sudoku, N-queens) | Backtracking |
| Interval scheduling, activity selection | Greedy |

## Key Takeaways

- Greedy makes the locally optimal choice at each step. It works when the problem has both the greedy choice property and optimal substructure.
- Greedy is fast (often O(n log n)). If you cannot prove the greedy choice is safe, you need DP.
- Backtracking explores all candidates incrementally, abandoning (pruning) branches that violate constraints.
- Backtracking is exponential but pruning makes it practical for many constraint satisfaction and enumeration problems.
- Greedy decides once per step. Backtracking tries everything and undoes. DP tries everything and remembers.
