---
title: "Trees and Traversals"
summary: "Binary tree properties, full/complete/balanced/perfect definitions, in-order/pre-order/post-order/level-order traversals, and DFS vs BFS space trade-offs."
reading_time_minutes: 4
order: 5
---

## Why This Matters

Trees are the backbone of hierarchical data: file systems, DOM elements, org charts, syntax trees. Binary trees specifically are the foundation for BSTs, heaps, and segment trees. Traversals are among the most common interview topics -- you need to know all four orders, their use cases, and their space characteristics without hesitation.

## Binary Tree Basics

A **binary tree** is a hierarchical structure where each node has at most two children, called **left** and **right**. The topmost node is the **root**. A node with no children is a **leaf**.

```
        1
       / \
      2   3
     / \   \
    4   5   6
```

Key terminology:

- **Depth** of a node: number of edges from the root to that node. The root has depth 0.
- **Height** of a tree: maximum depth across all nodes. The tree above has height 2.
- **Subtree**: any node and all its descendants form a subtree.

## Tree Shape Definitions

These four terms describe the shape of a binary tree. Interviewers expect precise definitions.

**Full binary tree:** Every node has either 0 or 2 children. No node has exactly one child.

**Complete binary tree:** Every level is fully filled except possibly the last, which is filled left to right. Heaps are complete binary trees.

**Perfect binary tree:** Every internal node has exactly 2 children and all leaves are at the same depth. A perfect tree with height h has 2^(h+1) - 1 nodes.

**Balanced binary tree:** The heights of the left and right subtrees of every node differ by at most 1. AVL trees enforce this property.

## Traversals

All four traversals visit every node exactly once, so they are all O(n) time. They differ in the **order** nodes are visited and the **space** they use.

### Depth-First Traversals (DFS)

DFS explores one branch fully before backtracking. The three DFS orders differ only in when the root is processed:

**In-order (Left, Root, Right):** On a BST, this produces sorted output. Used for sorted iteration and BST validation.

**Pre-order (Root, Left, Right):** Visits the root first. Used for tree serialization -- recording nodes in pre-order lets you reconstruct the tree.

**Post-order (Left, Right, Root):** Visits children before the parent. Used for safe deletion (free children before parent) and evaluating expression trees (operands before operator).

All three use O(h) space for the recursion stack, where h is the tree height. On a balanced tree, h = O(log n). On a skewed tree, h = O(n).

### Breadth-First Traversal (BFS)

**Level-order:** Uses a queue to visit nodes level by level, left to right. At each step, dequeue a node, process it, and enqueue its children.

```
Visit order: 1, 2, 3, 4, 5, 6
```

Space is O(w), where w is the maximum width. For a complete binary tree, the last level holds about n/2 nodes, so BFS uses O(n) space. On a skewed tree, width is 1, so BFS uses O(1) extra space.

## DFS vs BFS Space Trade-off

| Tree Shape | DFS Space O(h) | BFS Space O(w) | Better Choice |
|------------|----------------|-----------------|---------------|
| Balanced | O(log n) | O(n) | DFS |
| Skewed (linear) | O(n) | O(1) | BFS |

On balanced trees (the common case), DFS is more space-efficient. BFS shines when the problem requires level-by-level processing.

## Choosing a Traversal

- **Need sorted order on a BST?** In-order.
- **Need to serialize or clone a tree?** Pre-order.
- **Need to process children before parent (deletion, subtree aggregation)?** Post-order.
- **Need level-by-level info (depth, width, right-side view)?** Level-order (BFS).

Rule of thumb: if the problem says "depth" or "level," use BFS. If it says "subtree," use DFS.

## Recursive Tree Pattern

Most tree problems follow a single recursive template:

1. **Base case:** if the node is nil, return a default value.
2. **Recurse** on left and right subtrees.
3. **Combine** the results.

Maximum depth, for example: `depth(node) = 1 + max(depth(left), depth(right))`, with base case `depth(nil) = 0`. This visits every node once (O(n)) and uses O(h) stack space.

## Key Takeaways

- A binary tree has at most two children per node. Full, complete, perfect, and balanced describe different shape constraints.
- Four traversals: in-order (sorted on BST), pre-order (serialize), post-order (delete/evaluate), level-order (by depth).
- DFS uses O(h) space; BFS uses O(w) space. DFS is better on balanced trees; BFS when you need level information.
- Most tree problems reduce to: base case, recurse, combine.
