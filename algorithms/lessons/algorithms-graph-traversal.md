---
title: "Graph Traversal"
summary: "Graph representations (adjacency list vs matrix), BFS with queues, DFS with stacks/recursion, BFS vs DFS trade-offs, and topological sort on DAGs."
reading_time_minutes: 5
order: 4
---

## Why This Matters

Graphs model relationships: social networks, road maps, dependency chains, web links, compiler symbol tables. BFS and DFS are the two fundamental ways to explore a graph, and nearly every graph algorithm builds on one of them. Topological sort is essential for dependency resolution (build systems, task scheduling, course prerequisites).

## Graph Representations

Before traversing a graph, you need to store it. The two standard representations:

### Adjacency List

For each vertex, store a list of its neighbors. Typically implemented as an array of lists (or a hash map of lists for sparse, non-integer vertices).

- **Space:** O(V + E).
- **Check if edge (u, v) exists:** O(degree(u)) -- scan u's neighbor list.
- **Iterate over neighbors of u:** O(degree(u)).

Best for sparse graphs (E much less than V^2), which is most real-world graphs.

### Adjacency Matrix

A V x V boolean matrix where `matrix[u][v]` is true if an edge exists from u to v.

- **Space:** O(V^2).
- **Check if edge (u, v) exists:** O(1) -- direct array lookup.
- **Iterate over neighbors of u:** O(V) -- must scan the entire row.

Best for dense graphs (E close to V^2) or when you need O(1) edge existence checks.

**Default to adjacency list.** Most interview and real-world graphs are sparse.

## Breadth-First Search (BFS)

BFS explores a graph level by level. It visits all vertices at distance d from the start before any vertex at distance d+1.

**Data structure:** Queue (FIFO).

```
queue = [start]
visited = {start}
while queue is not empty:
    v = queue.dequeue()
    for each neighbor u of v:
        if u not in visited:
            visited.add(u)
            queue.enqueue(u)
```

- **Time:** O(V + E). Every vertex is enqueued once, every edge is examined once.
- **Space:** O(V) for the visited set and queue.

### BFS and Shortest Paths

In an **unweighted** graph, BFS finds the shortest path (fewest edges) from the source to every reachable vertex. The distance to each vertex equals the level at which BFS first discovers it.

This does **not** work for weighted graphs. For weighted shortest paths, use Dijkstra's algorithm (non-negative weights) or Bellman-Ford (handles negative weights).

## Depth-First Search (DFS)

DFS explores as deep as possible along each branch before backtracking.

**Data structure:** Stack (explicit) or the call stack (recursion).

```
function dfs(v):
    visited.add(v)
    for each neighbor u of v:
        if u not in visited:
            dfs(u)
```

- **Time:** O(V + E). Same as BFS.
- **Space:** O(V) for the visited set, plus O(V) worst-case stack depth (a path graph).

### DFS Applications

- **Cycle detection:** In a directed graph, a cycle exists if DFS encounters a vertex that is on the current recursion stack (a "back edge"). In an undirected graph, a cycle exists if DFS reaches an already-visited vertex that is not the parent.
- **Connected components:** Run DFS from each unvisited vertex. Each DFS call discovers one component.
- **Topological sort:** Covered below.

## BFS vs DFS

| Property | BFS | DFS |
|---|---|---|
| Data structure | Queue | Stack / recursion |
| Visit order | Level by level | Branch by branch |
| Shortest path (unweighted) | Yes | No |
| Space | O(V) (width of graph) | O(V) (depth of graph) |
| Cycle detection (directed) | No (use DFS) | Yes (back edge) |
| Use when | Shortest path, level-order | Cycle detection, topological sort, backtracking |

**When to choose BFS:** shortest path in unweighted graphs, level-order traversal, finding nodes within k hops.

**When to choose DFS:** cycle detection, topological sorting, exploring all paths (backtracking), and when the solution is likely deep in the graph.

## Topological Sort

A topological sort of a directed acyclic graph (DAG) is a linear ordering of vertices such that for every directed edge (u, v), u appears before v.

**Precondition:** The graph must be a DAG. If there is a cycle, no topological ordering exists.

### DFS-Based Topological Sort

Run DFS. When a vertex finishes (all neighbors explored), push it to a stack. The stack, read top to bottom, gives a valid topological order.

The intuition: a vertex finishes only after all its dependencies have finished, so it appears after them when reading the stack.

### Kahn's Algorithm (BFS-Based)

Start with all vertices that have zero in-degree (no incoming edges). Remove them from the graph, decrement in-degrees of their neighbors, and repeat. Vertices are output in the order they reach zero in-degree.

Kahn's algorithm also detects cycles: if the output contains fewer than V vertices, the graph has a cycle.

Both approaches run in O(V + E).

**Use cases:** build systems (compile dependencies in order), task scheduling, course prerequisite planning.

## Key Takeaways

- Adjacency lists use O(V + E) space and are the default for sparse graphs. Adjacency matrices use O(V^2) and provide O(1) edge lookups.
- BFS uses a queue, visits level by level, and finds shortest paths in unweighted graphs. Time: O(V + E).
- DFS uses a stack or recursion, explores depth-first, and is used for cycle detection and topological sort. Time: O(V + E).
- Topological sort orders a DAG so every edge points forward. DFS-based (finish order) and Kahn's (in-degree reduction) both work in O(V + E).
