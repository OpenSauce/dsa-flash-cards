---
title: "Arrays and Strings"
summary: "Contiguous memory layout, O(1) index access, O(n) insert/delete, dynamic arrays with amortized resizing, and why strings are just character arrays."
reading_time_minutes: 6
order: 1
---

## Why This Matters

Arrays are the most fundamental data structure. Every other structure -- linked lists, hash tables, heaps, even graphs -- is often built on top of arrays or compared against them. Interviewers expect you to know array complexity by heart and to explain *why* operations cost what they do, not just state the numbers.

## Memory Layout

An array stores elements in a **contiguous block of memory** -- think of it like a row of numbered mailboxes in an apartment building. Element `i` lives at address `base + i * element_size`. This arithmetic is why index access is O(1) -- the CPU computes the address directly without traversing anything.

```
Index:     0     1     2     3     4
         ┌─────┬─────┬─────┬─────┬─────┐
Memory:  │  10 │  20 │  30 │  40 │  50 │
         └─────┴─────┴─────┴─────┴─────┘
         base  base+4 base+8  ...
```

Contiguous layout also means arrays have excellent **cache locality**. When the CPU loads element 0, it pulls neighboring elements into the cache line too. Sequential iteration is fast because the next element is almost always already cached.

## Core Operations and Complexities

| Operation | Time | Why |
|-----------|------|-----|
| Access by index | O(1) | Direct address calculation |
| Search (unsorted) | O(n) | Must scan every element |
| Search (sorted) | O(log n) | Binary search halves the search space |
| Insert at end | O(1) amortized | Append to dynamic array |
| Insert at beginning/middle | O(n) | Must shift all subsequent elements |
| Delete at end | O(1) | Shrink length |
| Delete at beginning/middle | O(n) | Must shift all subsequent elements |

The O(n) cost of mid-array insertion and deletion is the array's main weakness. Every element after the insertion point must shift one position to make room (or close the gap).

```python
# Basic array operations in Python
nums = [10, 20, 30, 40, 50]

# O(1) — access by index
print(nums[2])  # 30

# O(n) — search (unsorted)
print(30 in nums)  # True, scans up to every element

# O(n) — insert in the middle (shifts elements right)
nums.insert(2, 25)  # [10, 20, 25, 30, 40, 50]

# O(1) amortized — append to end
nums.append(60)     # [10, 20, 25, 30, 40, 50, 60]

# O(n) — delete from the middle (shifts elements left)
nums.pop(2)         # removes 25 -> [10, 20, 30, 40, 50, 60]
```

## Dynamic Arrays

Fixed-size arrays require knowing the capacity upfront. Dynamic arrays (Go slices, Python lists, Java ArrayList) solve this by **resizing automatically** when the backing array is full.

The resizing strategy: allocate a new array with double the capacity, copy all elements over, then insert the new element. An individual resize is O(n), but it happens infrequently. Over a sequence of n appends, total work is proportional to n, making the **amortized cost per append O(1)**.

The intuition: after doubling from capacity k to 2k, the next resize won't happen until k more appends. The O(k) copy is "paid for" by those k cheap appends.

```python
# Python lists are dynamic arrays -- they resize automatically
items = []
for i in range(5):
    items.append(i)  # O(1) amortized, occasional O(n) resize
print(items)  # [0, 1, 2, 3, 4]
```

## Strings as Character Arrays

A string is a sequence of characters stored contiguously -- functionally an array. Most string operations have the same complexities as array operations:

- Accessing character at index i: O(1)
- Concatenation: O(n + m) where n and m are the lengths -- a new array is allocated and both strings are copied
- Substring search (naive): O(n * m) -- for each position in the haystack, compare up to m characters

In many languages (including Python), strings are **immutable** -- you cannot change a string in place. Repeated concatenation in a loop creates a new string each time, leading to O(n^2) total work. Use a list and `join()` to batch writes into a single allocation.

```python
# Bad: O(n^2) -- creates a new string each iteration
result = ""
for word in ["hello", "world", "foo"]:
    result += word + " "

# Good: O(n) -- join builds the string in one pass
words = ["hello", "world", "foo"]
result = " ".join(words)  # "hello world foo"
```

## Arrays vs Linked Lists

| | Array | Linked List |
|---|---|---|
| Access by index | O(1) | O(n) |
| Insert at head | O(n) | O(1) |
| Insert at tail | O(1) amortized | O(1) with tail pointer |
| Search | O(n), O(log n) if sorted | O(n) |
| Memory | Contiguous, cache-friendly | Scattered, pointer overhead |

Use arrays when you need fast random access or will iterate sequentially. Use linked lists when you need frequent insertions/deletions at arbitrary positions and don't need index access.

## Key Takeaways

- Arrays store elements contiguously, giving O(1) index access via address arithmetic.
- Insertion and deletion in the middle cost O(n) because elements must shift.
- Dynamic arrays resize by doubling, achieving O(1) amortized append.
- Strings are character arrays. Immutability means concatenation in a loop is O(n^2) without a builder.
- Arrays beat linked lists on cache locality and random access; linked lists win on head insertion.

## Related Problems

- **Two Sum** -- find two numbers that add up to a target (hash map + array)
- **Valid Anagram** -- check if two strings are anagrams (character counting with arrays)
- **Contains Duplicate** -- detect duplicates in an array (hash set)
