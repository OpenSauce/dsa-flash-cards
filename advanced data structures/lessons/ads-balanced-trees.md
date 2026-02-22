---
title: "Balanced Trees"
summary: "Why balance matters, red-black tree invariants and rotations, skip lists as a probabilistic alternative, and trade-offs between AVL, red-black, and skip list."
reading_time_minutes: 5
order: 2
---

## Why This Matters

A binary search tree gives O(log n) search when balanced, but nothing in the basic BST contract forces balance. Insert keys in sorted order and you get a linked list — O(n) search. Balanced BSTs solve this by enforcing structural invariants that keep height logarithmic. Red-black trees and skip lists are the two most widely deployed solutions.

## The BST Degradation Problem

A BST inserted with keys 1, 2, 3, 4, 5 in order looks like this:

```
1
 \
  2
   \
    3
     \
      4
       \
        5
```

Search for 5 takes O(n) steps. The tree becomes a sorted linked list with extra pointer overhead. Any self-balancing BST restructures itself on insert and delete to prevent this.

## Red-Black Trees

A red-black tree is a BST where every node is colored red or black. The coloring is not cosmetic — it enforces five invariants that together guarantee the tree's height never exceeds 2 log₂(n).

### The Five Red-Black Invariants

1. Every node is either red or black.
2. The root is black.
3. Every null leaf (NIL sentinel) is black.
4. A red node's children are always black (no two consecutive red nodes on any path).
5. Every path from a node to any of its null leaves contains the same number of black nodes (the "black-height").

Invariant 4 and 5 together do the work: any root-to-leaf path has at most twice as many total nodes as black nodes alone, keeping the height bounded at 2 log₂(n).

### Insert: Why New Nodes Are Red

New nodes are always inserted as red. If they were black, inserting any node would change the black-height of every path through that node — a violation of invariant 5 that would require rebalancing the entire subtree. A red insertion might only violate invariant 4 (red-red parent-child), which is fixable with local operations.

### Fix-Up: Recoloring and Rotations

After a red insert, if the parent is also red, the fix-up handles three cases:

- **Case 1 (uncle is red):** Recolor parent and uncle to black, grandparent to red. Move the violation pointer up to the grandparent and continue.
- **Case 2 (uncle is black, node is an inner child):** Rotate to make the node an outer child, reducing to Case 3.
- **Case 3 (uncle is black, node is an outer child):** Rotate the grandparent, swap grandparent's and parent's colors.

At most 2 rotations happen per insert. This is cheaper than AVL trees, which can rotate on every ancestor during insert.

### Red-Black vs AVL

| Property | Red-Black | AVL |
|---|---|---|
| Height bound | ≤ 2 log n | ≤ 1.44 log n |
| Rotations per insert | At most 2 | O(log n) in worst case |
| Rotations per delete | At most 3 | O(log n) in worst case |
| Lookup speed | Slightly slower (taller tree) | Slightly faster |
| Standard library use | Java TreeMap, C++ std::map | Some databases |

Red-black trees win in write-heavy workloads. AVL trees win in read-heavy workloads where lookup speed dominates.

## Skip Lists

A skip list is a probabilistic alternative to a balanced BST. It starts with a standard sorted linked list (level 0), then adds "express lanes" at higher levels that skip over multiple nodes.

```
Level 3: head ──────────────────────────────────── 50 ──── tail
Level 2: head ──────────── 20 ──────────── 50 ──── 70 ──── tail
Level 1: head ──── 10 ──── 20 ──── 30 ──── 50 ──── 70 ──── tail
Level 0: head ─ 5 ─ 10 ─ 15 ─ 20 ─ 25 ─ 30 ─ 40 ─ 50 ─ 60 ─ 70 ─ tail
```

### Probabilistic Level Assignment

When inserting a new element, its height is determined randomly: flip a coin. If heads, add another level. Keep flipping until tails. With probability p = 0.5, the expected height of any element is O(log n).

This is the key trade-off: the structure is self-organizing in expectation, not by strict invariant. The O(log n) bounds are *expected*, not worst-case. With bad luck, a skip list could degrade, though the probability is negligible in practice.

### Search, Insert, Delete: O(log n) Expected

Search starts at the highest level and moves right until the next node exceeds the target, then drops a level and repeats. Insert runs a search pass to find insertion points at each level, then splices the new node in. Delete finds and removes at all levels. All three operations are O(log n) expected.

### Real-World Use of Skip Lists

Skip lists are used where concurrent access matters. Lock-free skip list implementations are straightforward because insertions only modify local pointers, not ancestors. Redis sorted sets and Java's `ConcurrentSkipListMap` use skip lists for this reason.

## Key Takeaways

- An unbalanced BST degrades to O(n) search when keys are inserted in sorted order.
- Red-black trees enforce five invariants that guarantee height ≤ 2 log n, using at most 2 rotations per insert.
- New nodes are inserted as red to avoid immediately violating the black-height invariant.
- AVL trees are more strictly balanced (height ≤ 1.44 log n) but require more rotations per insert/delete. Use AVL for read-heavy workloads, red-black for write-heavy.
- Skip lists achieve O(log n) expected time probabilistically. They are simpler to implement concurrently than balanced BSTs.
