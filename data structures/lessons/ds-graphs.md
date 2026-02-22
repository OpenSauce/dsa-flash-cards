---
title: "Graphs"
summary: "Vertices and edges, directed vs undirected, weighted vs unweighted, adjacency list vs adjacency matrix, BFS and DFS on graphs, and connected components."
reading_time_minutes: 5
order: 8
---

## Why This Matters

Graphs model relationships: social networks, road maps, dependency chains, web links, circuit boards. Many interview problems are graph problems in disguise -- "find if a path exists," "detect a cycle," "find the shortest route." Knowing the two representations and two traversals lets you solve most of them.

## What Is a Graph?

A graph is a set of **vertices** (nodes) connected by **edges** (links). Unlike trees, graphs have no root, can contain cycles, and a vertex can have any number of connections.

### Directed vs Undirected

- **Undirected:** edges have no direction. If A connects to B, then B connects to A. Example: Facebook friendships.
- **Directed:** edges have direction. A -> B does not imply B -> A. Example: Twitter follows, web links, prerequisites.

### Weighted vs Unweighted

- **Unweighted:** all edges are equal. BFS finds shortest paths.
- **Weighted:** edges have costs (distance, time, bandwidth). Dijkstra's or Bellman-Ford finds shortest paths.

## Representations

### Adjacency List

Each vertex stores a list of its neighbors.

```go
graph := map[int][]int{
    0: {1, 2},
    1: {0, 3},
    2: {0},
    3: {1},
}
```

- **Space:** O(V + E). Efficient for sparse graphs.
- **Check if edge exists:** O(degree(v)) -- walk the neighbor list.
- **Iterate neighbors:** O(degree(v)) -- direct access.
- **Add edge:** O(1) -- append to list.

### Adjacency Matrix

A V x V matrix where `matrix[i][j] = 1` (or the weight) if an edge exists from i to j.

```
    0  1  2  3
0 [ 0  1  1  0 ]
1 [ 1  0  0  1 ]
2 [ 1  0  0  0 ]
3 [ 0  1  0  0 ]
```

- **Space:** O(V^2). Wasteful for sparse graphs, fine for dense ones.
- **Check if edge exists:** O(1) -- direct array lookup.
- **Iterate neighbors:** O(V) -- must scan the entire row.
- **Add edge:** O(1) -- set matrix entry.

### Which to Use?

| | Adjacency List | Adjacency Matrix |
|---|---|---|
| Space | O(V + E) | O(V^2) |
| Edge lookup | O(degree) | O(1) |
| Neighbor iteration | O(degree) | O(V) |
| Best for | Sparse graphs (E << V^2) | Dense graphs (E near V^2) |

Most interview and real-world graphs are sparse, so **adjacency lists are the default choice**.

## Graph Traversals

### BFS (Breadth-First Search)

Uses a queue. Explores all vertices at distance d before distance d+1. Guarantees **shortest path in unweighted graphs**.

```
Algorithm:
1. Enqueue start, mark visited
2. While queue not empty:
   a. Dequeue vertex v
   b. For each unvisited neighbor u:
      - Mark u visited, enqueue u
```

**Time:** O(V + E) -- each vertex is enqueued once, each edge is examined once.
**Space:** O(V) for the visited set and queue.

Mark vertices visited **before** enqueuing, not after dequeuing. Otherwise you may enqueue the same vertex multiple times.

### DFS (Depth-First Search)

Uses a stack (or recursion). Explores one branch as deeply as possible before backtracking.

```
Algorithm:
1. Push start, mark visited
2. While stack not empty:
   a. Pop vertex v
   b. For each unvisited neighbor u:
      - Mark u visited, push u
```

**Time:** O(V + E) -- same as BFS.
**Space:** O(V) for the visited set and stack/recursion depth.

DFS is used for: cycle detection, topological sorting, finding connected components, and maze solving.

## Connected Components

An undirected graph may consist of multiple disconnected subgraphs. Each maximal connected subgraph is a **connected component**.

To find all components: iterate through every vertex. If it hasn't been visited, run BFS or DFS from it -- all vertices reached form one component. Repeat until all vertices are visited.

Time: O(V + E) total across all BFS/DFS runs.

## Cycle Detection

**Undirected graph:** During BFS/DFS, if you encounter an already-visited vertex that is not the parent of the current vertex, a cycle exists.

**Directed graph:** During DFS, maintain a "currently in stack" set. If you visit a vertex that is already in the current DFS path (not just visited globally), a cycle exists. This is a **back edge**.

## Key Takeaways

- Graphs have vertices and edges. Edges can be directed or undirected, weighted or unweighted.
- Adjacency lists use O(V + E) space and are best for sparse graphs. Adjacency matrices use O(V^2) and give O(1) edge lookup.
- BFS uses a queue, explores level by level, and finds shortest paths in unweighted graphs.
- DFS uses a stack/recursion, explores depth-first, and is used for cycle detection and topological sort.
- Both traversals run in O(V + E) time.
