---
title: "String DP"
summary: "Two-string DP problems: LCS, edit distance, longest common substring vs subsequence, and longest palindromic subsequence."
reading_time_minutes: 5
order: 4
---

## Why This Matters

String DP problems appear constantly in interviews. They introduce the two-index state `(i, j)` pattern that is fundamental to any problem involving two sequences. LCS and edit distance are the two canonical string DP problems -- once you understand their recurrences, you can derive variants (palindromes, diffs, alignment) as modifications.

## The Two-String State Pattern

When a problem involves two strings s1 and s2, the natural state is:

```
dp[i][j] = answer for the first i characters of s1 and first j characters of s2
```

This creates an (m+1) x (n+1) table where m = len(s1), n = len(s2). The first row and column represent empty prefix states (base cases).

The recurrence branches on whether `s1[i-1] == s2[j-1]` (using 1-indexed DP, 0-indexed strings):
- **Match:** both characters are "consumed" together -- look at `dp[i-1][j-1]`.
- **No match:** try all options that advance at least one of the indices.

## Longest Common Subsequence (LCS)

**Problem:** Find the length of the longest subsequence common to both strings. A subsequence preserves relative order but need not be contiguous.

**Recurrence:**
```
if s1[i-1] == s2[j-1]:
    dp[i][j] = dp[i-1][j-1] + 1    # both characters matched, extend
else:
    dp[i][j] = max(dp[i-1][j], dp[i][j-1])   # skip one character from either string
```

**Base cases:** `dp[0][j] = 0` and `dp[i][0] = 0` (LCS with an empty string is 0).

**Time:** O(m * n), **Space:** O(m * n), reducible to O(min(m, n)) by keeping only two rows.

### Reconstructing the Actual LCS

The table gives the *length*. To get the actual subsequence, backtrack from `dp[m][n]`:

```
i = m, j = n
while i > 0 and j > 0:
    if s1[i-1] == s2[j-1]:
        output s1[i-1]    # this character is in the LCS
        i -= 1, j -= 1
    elif dp[i-1][j] >= dp[i][j-1]:
        i -= 1            # came from above
    else:
        j -= 1            # came from left
```

Read the output in reverse order.

## LCS vs Longest Common Substring

| | Subsequence | Substring |
|---|---|---|
| **Contiguous?** | No | Yes |
| **Match case** | `dp[i-1][j-1] + 1` | `dp[i-1][j-1] + 1` |
| **Mismatch case** | `max(dp[i-1][j], dp[i][j-1])` | `0` (reset -- break in contiguity) |
| **Answer** | `dp[m][n]` | `max over all dp[i][j]` |

The only difference: on mismatch, subsequence keeps the best result seen so far; substring resets to 0 because a gap breaks the substring.

## Edit Distance (Levenshtein Distance)

**Problem:** Find the minimum number of insert, delete, or replace operations to convert s1 into s2.

**State:** `dp[i][j]` = minimum edits to convert the first i characters of s1 to the first j characters of s2.

**Recurrence:**
```
if s1[i-1] == s2[j-1]:
    dp[i][j] = dp[i-1][j-1]         # no edit needed
else:
    dp[i][j] = 1 + min(
        dp[i-1][j],                  # delete s1[i-1] (move up in table)
        dp[i][j-1],                  # insert s2[j-1] into s1 (move left in table)
        dp[i-1][j-1]                 # replace s1[i-1] with s2[j-1] (move diagonally)
    )
```

**Table direction semantics:**
- Move up `(i-1, j)`: deleted a character from s1 -- one fewer s1 character to match
- Move left `(i, j-1)`: inserted a character into s1 to match s2 -- one fewer s2 character to match
- Move diagonal `(i-1, j-1)`: replaced s1[i-1] with s2[j-1]

**Base cases:** `dp[i][0] = i` (delete all i characters from s1); `dp[0][j] = j` (insert all j characters of s2).

**Time:** O(m * n), **Space:** O(m * n), reducible to O(min(m, n)).

## Longest Palindromic Subsequence

**Problem:** Find the longest subsequence of a string that is also a palindrome.

**Trick:** A palindrome reads the same forwards and backwards. The longest palindromic subsequence of s is the LCS of s and its reverse.

```
s_rev = reverse(s)
return LCS(s, s_rev)
```

No new recurrence needed -- just recognize the reduction.

**Why it works:** Any subsequence common to s and s_rev appears in order in s and in reverse order in s. A subsequence that appears in both directions is a palindrome.

## Key Takeaways

- **Two-string state:** `dp[i][j]` covers the first i characters of s1 and first j characters of s2.
- **LCS recurrence:** match -> `dp[i-1][j-1] + 1`; no match -> `max(dp[i-1][j], dp[i][j-1])`.
- **Substring vs subsequence:** mismatch resets to 0 for substring; takes max of neighbors for subsequence.
- **Edit distance:** three operations map to three table directions: up (delete), left (insert), diagonal (replace).
- **Reconstruct LCS** by backtracking through the table from `dp[m][n]`, following the path that produced each value.
- **Longest palindromic subsequence** = LCS of the string with its own reverse.
