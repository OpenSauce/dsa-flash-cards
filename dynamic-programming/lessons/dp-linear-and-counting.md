---
title: "Linear DP and Counting"
summary: "1D DP where the state is a single index: Kadane's extend-or-restart pattern, house robber's skip-or-take pattern, and counting ways problems."
reading_time_minutes: 7
order: 2
---

## Why This Matters

Linear DP problems -- where the state is a single index into a sequence -- are the entry point to most DP interviews. Two core decision patterns appear over and over: *extend or restart* (Kadane's) and *skip or take* (house robber). Once you recognize which pattern you're dealing with, the recurrence almost writes itself.

This lesson also covers counting DP problems, which differ subtly from optimization DP in how you initialize and combine subproblem answers.

## The Extend-or-Restart Pattern: Kadane's Algorithm

**Problem:** Find the contiguous subarray with the largest sum.

At each index i, you face one decision: extend the running subarray by including `arr[i]`, or abandon it and start a new subarray at `arr[i]`.

**Recurrence:**
```
dp[i] = max(arr[i], dp[i-1] + arr[i])
```

Equivalently: `dp[i] = arr[i] + max(0, dp[i-1])`. If the previous running sum is negative, don't carry it forward.

**Answer:** `max(dp[0], dp[1], ..., dp[n-1])` -- the best subarray ending at any index.

**Space optimization:** Only `dp[i-1]` is needed, so this reduces to two variables:
```
curr_max = arr[0]
global_max = arr[0]
for i from 1 to n-1:
    curr_max = max(arr[i], curr_max + arr[i])
    global_max = max(global_max, curr_max)
```

Time: O(n), Space: O(1).

```python
def max_subarray(nums):
    curr_max = global_max = nums[0]
    for num in nums[1:]:
        curr_max = max(num, curr_max + num)
        global_max = max(global_max, curr_max)
    return global_max

print(max_subarray([-2, 1, -3, 4, -1, 2, 1, -5, 4]))  # 6 (subarray [4,-1,2,1])
```

**When to restart vs extend:** Restart when `dp[i-1] < 0`. Extending a negative running sum only makes the new subarray worse.

## The Skip-or-Take Pattern: House Robber

**Problem:** Maximize total value from a row of houses where you cannot take from two adjacent houses.

At each house i, you decide: skip house i (the best you can do is what you achieved up to house i-1), or take house i (add its value to the best you achieved up to house i-2, since i-1 is off-limits).

**Recurrence:**
```
dp[i] = max(dp[i-1], dp[i-2] + nums[i])
```

**Base cases:** `dp[0] = nums[0]`, `dp[1] = max(nums[0], nums[1])`

**Why greedy fails:** Consider the greedy rule "take every other house starting from the first". On `[5, 1, 1, 5]`, this rule picks houses at indices 0 and 2 for a total of 6, but the optimal choice is indices 0 and 3 for a total of 10. A simple local or fixed pattern rule can miss the best non-adjacent combination, which is why we need the skip-or-take DP recurrence.

**Space optimization:** Like Kadane's, only the two previous values are needed. Reduce to O(1) with `prev2` and `prev1` variables.

```python
def house_robber(nums):
    if len(nums) == 1:
        return nums[0]
    prev2, prev1 = nums[0], max(nums[0], nums[1])
    for i in range(2, len(nums)):
        curr = max(prev1, prev2 + nums[i])
        prev2 = prev1
        prev1 = curr
    return prev1

print(house_robber([2, 7, 9, 3, 1]))  # 12 (rob houses 0, 2, 4)
```

## Counting DP vs Optimization DP

Both use the same recurrence structure, but they differ in how subproblem answers combine:

| | Optimization | Counting |
|---|---|---|
| **Combines subproblems with** | `max()` or `min()` | Addition (`+`) |
| **Base case for "zero cost"** | 0 | 1 |
| **Base case for "unreachable"** | infinity | 0 |
| **Example** | Minimum coin change | Number of ways to make change |

**Counting example -- Climbing Stairs (again, as a counting problem):**
How many ways to climb n stairs taking 1 or 2 steps?

```
dp[i] = dp[i-1] + dp[i-2]
dp[0] = 1, dp[1] = 1
```

Addition because you're summing all distinct paths -- not comparing them to pick the best.

**Counting example -- Decode Ways:**
A string of digits can be decoded as letters (1=A, 2=B, ..., 26=Z). Count the number of valid decodings.

State: `dp[i]` = number of ways to decode the first i characters.

Decision: use the last 1 digit as a letter (if valid) OR use the last 2 digits as a letter (if in range 10-26).

```
dp[i] = 0
if digit[i-1] != '0':
    dp[i] += dp[i-1]          # decode one digit
if 10 <= int(digit[i-2:i]) <= 26:
    dp[i] += dp[i-2]          # decode two digits
```

Base case: `dp[0] = 1` (one way to decode the empty string), `dp[1] = 1` if first digit is non-zero.

The '0' case is critical: '0' alone is invalid, so it contributes nothing as a single digit.

```python
def num_decodings(s):
    if not s or s[0] == '0':
        return 0
    n = len(s)
    dp = [0] * (n + 1)
    dp[0] = 1  # empty string
    dp[1] = 1  # first char is non-zero (checked above)
    for i in range(2, n + 1):
        if s[i - 1] != '0':
            dp[i] += dp[i - 1]  # single digit decode
        two_digit = int(s[i - 2:i])
        if 10 <= two_digit <= 26:
            dp[i] += dp[i - 2]  # two-digit decode
    return dp[n]

print(num_decodings("226"))  # 3: "BZ", "VF", "BBF"
```

## Rolling Variable Optimization for 1D DP

Any 1D DP where `dp[i]` depends only on the previous one or two entries can be reduced from O(n) space to O(1):

- Depends on `dp[i-1]` only: one variable.
- Depends on `dp[i-1]` and `dp[i-2]`: two variables.
- Depends on `dp[i-1]`, `dp[i-2]`, and `dp[i-3]` (e.g., "climb 1, 2, or 3 steps"): three variables.

The pattern: before updating, save what you'll need for the next iteration.

## Key Takeaways

- **Extend-or-restart (Kadane's):** `dp[i] = max(arr[i], dp[i-1] + arr[i])`. Restart when carrying the previous sum would hurt.
- **Skip-or-take (house robber):** `dp[i] = max(dp[i-1], dp[i-2] + nums[i])`. The adjacency constraint forces looking two steps back.
- **Counting vs optimization:** counting adds subproblem answers; optimization takes max/min. Base cases differ accordingly.
- **Rolling variables:** if `dp[i]` depends on a constant number of previous entries, reduce space to O(1) by keeping only those entries.
- Identify which pattern applies before writing the recurrence -- the two patterns have different base cases and different answers (max over all i vs value at i=n).

## Related Problems

- **Climbing Stairs** -- counting DP with the same Fibonacci-like recurrence
