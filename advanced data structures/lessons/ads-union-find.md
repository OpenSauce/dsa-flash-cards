---
title: "Union-Find (Disjoint Sets)"
summary: "Disjoint set concept, path compression, union by rank, inverse Ackermann complexity, and applications in graph algorithms."
reading_time_minutes: 4
order: 3
---

## Why This Matters

Connectivity questions appear constantly in graph problems: are two nodes in the same connected component? Does adding this edge create a cycle? Are these equivalence classes the same? Union-find is the purpose-built structure for all of these. It is simpler than BFS/DFS for connectivity, and it is a core component of Kruskal's minimum spanning tree algorithm.

## The Disjoint Set Concept

A disjoint-set (union-find) structure maintains a collection of non-overlapping sets. Elements start in their own singleton sets. Two operations are supported:

- **find(x):** Return the representative (root) of the set containing x. Two elements are in the same set if and only if their roots are equal.
- **union(a, b):** Merge the sets containing a and b into one.

The naive implementation uses an array where `parent[i]` is the parent of element i. Initially, `parent[i] = i` (each element is its own root). Find walks up the chain of parents until it reaches an element that is its own parent.

```
find(x):
    while parent[x] != x:
        x = parent[x]
    return x

union(a, b):
    rootA = find(a)
    rootB = find(b)
    if rootA != rootB:
        parent[rootA] = rootB
```

Without optimization, find can take O(n) time if the chain is tall (e.g., elements linked into a chain by repeated unions).

## Path Compression

Path compression makes find fast by flattening the tree as a side effect of each lookup. After finding the root, it goes back and sets every visited node's parent directly to the root.

```
find(x):
    if parent[x] != x:
        parent[x] = find(parent[x])  // compress on the way back up
    return parent[x]
```

After path compression, subsequent find operations on the same elements reach the root in one step. The tree never needs to be tall again.

## Union by Rank

Without guidance, union might always attach the root of one tree as a child of the other, creating tall chains. Union by rank prevents this by always attaching the shorter tree under the taller one.

Each root maintains a `rank` (an upper bound on the height of its subtree). When unioning:

```
union(a, b):
    rootA = find(a)
    rootB = find(b)
    if rootA == rootB:
        return
    if rank[rootA] < rank[rootB]:
        parent[rootA] = rootB
    else if rank[rootA] > rank[rootB]:
        parent[rootB] = rootA
    else:
        parent[rootB] = rootA
        rank[rootA] += 1  // only increase rank when two equal-rank trees merge
```

Union by rank alone keeps tree height at O(log n). Combined with path compression, the amortized cost per operation drops dramatically.

## Inverse Ackermann Complexity

With both path compression and union by rank, the amortized cost per operation is O(α(n)), where α is the inverse Ackermann function. For all practical values of n (even n = 10^80), α(n) ≤ 4. It is effectively constant — so close to O(1) that the distinction is academic.

This is one of the most remarkable results in data structures: a structure with near-constant amortized time that requires proof via potential function analysis to establish.

## Applications

**Connected components:** Find the number of distinct connected components in a graph by calling union on each edge. Each distinct root is a component.

**Cycle detection:** Add edges to a union-find. If `find(a) == find(b)` before calling `union(a, b)`, adding edge (a, b) would create a cycle — the two endpoints are already connected.

**Kruskal's MST:** Sort edges by weight. Add each edge if it connects two different components (no cycle). The "no cycle" check is exactly `find(a) != find(b)`.

**Equivalence classes:** Any time you need to group elements by equivalence (accounts that share a phone number, users who share a login session), union-find maintains the grouping efficiently.

## The One Limitation

Union-find cannot undo a union. Once two sets are merged, they cannot be split apart. If your problem requires "un-union" (e.g., offline connectivity with deletions), you need a different approach (link-cut trees, or offline reversal techniques).

Enumerating all members of a set also requires iterating every element — there is no direct "list all members of set X" operation in the basic structure.

## Key Takeaways

- find returns the root representative of a set; two elements are in the same set iff their roots match.
- Path compression flattens the tree on every find, making future finds faster.
- Union by rank prevents tall chains by always attaching the shorter tree under the taller one.
- Both optimizations together give O(α(n)) amortized time per operation — practically O(1).
- Union-find cannot split sets. For connectivity with deletions, use a different structure.
- Core application: Kruskal's MST, cycle detection, connected components in undirected graphs.
