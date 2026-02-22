---
title: "Binary Search Trees"
order: 6
summary: "BST properties and invariants, core operations (search, insert, delete), why balance matters, and when to reach for a BST over other data structures."
reading_time_minutes: 5
---

## Why This Matters

Binary search trees are a staple of coding interviews and the foundation for most ordered data structures in real systems. Databases use BST variants (B-trees) for indexing. Language standard libraries use balanced BSTs (red-black trees) for ordered maps and sets. Understanding the core operations and the balance problem gives you a framework for reasoning about logarithmic-time data access.

## The BST Property

A binary search tree is a binary tree where every node satisfies a single invariant:

**All values in the left subtree < node value < all values in the right subtree.**

This is a **global** property, not a local one. It is not enough to check that a node's immediate children are ordered correctly -- every node in the left subtree must be less than the root, and every node in the right subtree must be greater.

```
        8
       / \
      3   10
     / \    \
    1   6    14
       / \   /
      4   7 13
```

An in-order traversal of a valid BST produces values in sorted order: 1, 3, 4, 6, 7, 8, 10, 13, 14. This property is central to many BST operations and interview problems.

## Core Operations

### Search

Start at the root. If the target is less than the current node, go left. If greater, go right. Each comparison eliminates an entire subtree.

```go
func search(root *Node, key int) *Node {
    for root != nil && root.Val != key {
        if key < root.Val {
            root = root.Left
        } else {
            root = root.Right
        }
    }
    return root
}
```

**Time:** O(h), where h is the height. On a balanced tree, h = O(log n). On a skewed tree, h = O(n).

The intuition is identical to binary search on a sorted array: each step halves the search space, but only when the tree is balanced.

### Insert

Walk the tree as if searching for the new key. When you reach a nil pointer, that is where the new node belongs.

```go
func insert(root *Node, key int) *Node {
    if root == nil {
        return &Node{Val: key}
    }
    if key < root.Val {
        root.Left = insert(root.Left, key)
    } else {
        root.Right = insert(root.Right, key)
    }
    return root
}
```

**Time:** O(h) -- same as search, because you are searching for the insertion point.

**Critical observation:** If you insert already-sorted data into a plain BST, every node goes to the right. The tree degrades to a linked list, and all operations become O(n). This is the motivation for self-balancing trees.

### Delete

Deletion has three cases, depending on how many children the target node has.

**Case 1 -- Leaf node (no children):** Remove it. Nothing else to fix.

**Case 2 -- One child:** Replace the node with its single child. The child takes the deleted node's position in the tree.

**Case 3 -- Two children:** This is the tricky one. You cannot simply remove the node because both subtrees need a parent. The solution: find the node's **in-order successor** (the smallest value in the right subtree), copy its value into the target node, then delete the successor. The successor has at most one child (it cannot have a left child, because then that left child would be smaller and would be the real successor), so deleting it falls into Case 1 or 2.

Alternatively, you can use the **in-order predecessor** (largest value in the left subtree). Both approaches preserve the BST invariant.

```go
func deleteNode(root *Node, key int) *Node {
    if root == nil { return nil }
    if key < root.Val {
        root.Left = deleteNode(root.Left, key)
    } else if key > root.Val {
        root.Right = deleteNode(root.Right, key)
    } else {
        if root.Left == nil { return root.Right }
        if root.Right == nil { return root.Left }
        // Two children: replace with in-order successor
        succ := root.Right
        for succ.Left != nil {
            succ = succ.Left
        }
        root.Val = succ.Val
        root.Right = deleteNode(root.Right, succ.Val)
    }
    return root
}
```

**Time:** O(h) -- finding the node is O(h), finding the successor is O(h), and deleting the successor is O(h). These do not multiply because the successor search starts from the node's right child, not from the root.

## The Balance Problem

All three operations are O(h). On a balanced tree, h = O(log n), so operations are O(log n). On a degenerate tree (inserted in sorted order), h = O(n), and the BST offers no advantage over a linked list.

Self-balancing BSTs solve this by restructuring the tree after insertions and deletions to keep the height at O(log n):

- **AVL trees** enforce a strict balance: for every node, the heights of the left and right subtrees differ by at most 1. Lookups are fast, but insertions and deletions may require multiple rotations.
- **Red-black trees** enforce a looser balance using node coloring rules. They allow heights to differ by up to 2x, which means slightly slower lookups than AVL but fewer rotations on insert/delete. Most language standard libraries use red-black trees (Java's `TreeMap`, C++'s `std::map`).

Both guarantee O(log n) for search, insert, and delete.

### Rotations

Rotations are the mechanism that balancing trees use to restore balance. A rotation changes the parent-child relationship between two nodes while preserving the BST invariant.

A **right rotation** at node X lifts X's left child up and makes X its right child. A **left rotation** does the reverse. AVL trees use single and double rotations; red-black trees use rotations combined with color flips.

You rarely need to implement rotations from scratch in interviews, but you should be able to explain that balanced BSTs use rotations to maintain O(log n) height.

## Validating a BST

A common interview problem: given a binary tree, determine whether it is a valid BST.

The naive approach -- checking that `left.Val < node.Val < right.Val` for each node -- is wrong. It only validates immediate children, not the global invariant. A node deep in the left subtree could be greater than the root.

The correct approach passes down valid bounds:

```go
func isValidBST(root *Node) bool {
    return validate(root, math.MinInt64, math.MaxInt64)
}

func validate(n *Node, min, max int) bool {
    if n == nil { return true }
    if n.Val <= min || n.Val >= max { return false }
    return validate(n.Left, min, n.Val) &&
           validate(n.Right, n.Val, max)
}
```

An alternative: perform an in-order traversal and check that the output is strictly increasing. If it is, the tree is a valid BST.

## When to Use a BST

**Use a BST (or balanced variant) when you need:**
- O(log n) search, insert, and delete on ordered data
- In-order traversal (sorted iteration)
- Range queries ("find all values between 10 and 50")
- Finding the predecessor or successor of a value

**Use a hash map instead when:**
- You only need O(1) average-case lookup by key
- Order does not matter
- You do not need range queries or sorted iteration

**Use a sorted array instead when:**
- Data is static (no insertions or deletions)
- You need O(log n) search via binary search but O(1) indexed access

## Key Takeaways

- The BST invariant is global: all left descendants < node < all right descendants. Validating only immediate children is a common bug.
- Search, insert, and delete are all O(h). The tree's shape determines whether h is O(log n) or O(n).
- Inserting sorted data into a plain BST produces a linked list. Self-balancing trees (AVL, red-black) use rotations to guarantee O(log n) height.
- BST delete with two children uses the in-order successor (smallest in the right subtree) to preserve the invariant.
- Choose a BST over a hash map when you need ordering, range queries, or sorted traversal.
