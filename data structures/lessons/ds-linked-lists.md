---
title: "Linked Lists"
summary: "Pointer-based node chains, singly vs doubly linked, O(1) head/tail operations, O(n) search, and common interview patterns like reversal and two-pointer techniques."
reading_time_minutes: 4
order: 2
---

## Why This Matters

Linked lists test your ability to manipulate pointers -- a skill that transfers to trees, graphs, and any recursive data structure. They also appear constantly in interviews: reverse a list, detect a cycle, merge sorted lists. Knowing the trade-offs vs arrays lets you justify data structure choices under pressure.

## Structure

A linked list is a sequence of **nodes**, each containing a value and a pointer to the next node. The list is accessed through a `head` pointer. The last node points to `nil`.

```
head -> [10 | *] -> [20 | *] -> [30 | nil]
```

There is no contiguous memory. Nodes can live anywhere on the heap. This means no index access -- to reach node i, you walk from the head through i pointers (O(n)).

## Singly vs Doubly Linked

A **singly linked list** has one pointer per node (`Next`). You can only traverse forward.

A **doubly linked list** adds a `Prev` pointer, enabling backward traversal. The trade-off is double the pointer storage per node, but you gain O(1) deletion of any node given a direct reference (no need to find the predecessor).

```
Singly:  [A | *] -> [B | *] -> [C | nil]

Doubly:  nil <- [A | *] <-> [B | *] <-> [C | *] -> nil
```

Doubly linked lists are used when you need efficient removal from the middle -- the classic example is an **LRU cache**, which pairs a hash map (O(1) lookup) with a doubly linked list (O(1) eviction of the least-recently-used node).

## Core Operations

| Operation | Singly | Doubly |
|-----------|--------|--------|
| Insert at head | O(1) | O(1) |
| Insert at tail (with tail pointer) | O(1) | O(1) |
| Insert at tail (no tail pointer) | O(n) | O(n) |
| Delete head | O(1) | O(1) |
| Delete node given pointer | O(n)* | O(1) |
| Search by value | O(n) | O(n) |

*In a singly linked list, deleting a node requires updating the previous node's `Next` pointer. Without a `Prev` pointer, you must walk from the head to find the predecessor.

### The Tail Pointer Optimization

Without a tail pointer, appending to a singly linked list requires walking the entire list to find the end (O(n)). Maintaining a separate `tail` pointer makes append O(1). This optimization is standard in queue implementations.

## Common Patterns

### Reversing a Singly Linked List

Use three pointers: `prev`, `cur`, and `next`. At each step, save `cur.Next`, point `cur.Next` to `prev`, then advance both pointers. After the loop, `prev` is the new head.

This is O(n) time, O(1) space, and one of the most frequently asked interview questions.

### Two-Pointer Technique

Many linked list problems use two pointers moving at different speeds:

**Finding the middle:** Slow pointer moves one step, fast pointer moves two. When fast reaches the end, slow is at the middle. This is the splitting step in merge sort for linked lists.

**Detecting a cycle (Floyd's algorithm):** Same setup. If there is a cycle, the fast pointer laps the slow pointer and they meet inside the cycle. If there is no cycle, fast reaches nil. O(n) time, O(1) space.

**Finding the cycle start:** After detection, reset one pointer to head. Advance both one step at a time. They meet at the cycle entry point.

### Merging Two Sorted Lists

Use a **dummy head node** to avoid special-casing the first insertion. Compare the heads of both lists, attach the smaller one, advance that list's pointer. When one is exhausted, attach the remainder of the other. O(n + m) time, O(1) space since existing nodes are re-linked, not copied.

## Key Takeaways

- Linked lists trade random access (O(n)) for O(1) insertion/deletion at known positions.
- Singly linked: one pointer per node, forward-only. Doubly linked: two pointers, bidirectional, O(1) delete-by-reference.
- A tail pointer turns append from O(n) to O(1).
- Floyd's cycle detection uses slow/fast pointers for O(n) time, O(1) space.
- The dummy head node pattern simplifies edge cases in merge and insert operations.
