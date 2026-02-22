---
title: "Stacks and Queues"
summary: "LIFO vs FIFO semantics, push/pop/enqueue/dequeue in O(1), slice-backed and linked-list implementations, and classic applications like parentheses matching and BFS."
reading_time_minutes: 4
order: 3
---

## Why This Matters

Stacks and queues are the simplest abstract data types, but they appear everywhere: function call stacks, undo/redo, expression parsing, BFS, task scheduling. Interviewers use them to test whether you can match a problem's access pattern to the right data structure.

## Stacks: Last-In, First-Out (LIFO)

A stack supports three operations, all O(1):

- **Push:** add an element to the top
- **Pop:** remove and return the top element
- **Peek:** read the top element without removing it

The most recently added element is always the first to leave. Think of a stack of plates -- you add and remove from the top.

### Implementation

A dynamic array (slice) is the standard backing structure. Push is `append`, pop reads and shrinks the last element. Both are O(1) amortized. A linked list also works (push/pop at the head), but the array version has better cache locality.

### Applications

- **Parentheses matching:** Push every opener. On a closer, check that the top matches. If the stack is empty at the end with no mismatches, the string is balanced.
- **Undo/redo:** Each action pushes onto the undo stack. Undo pops and pushes onto the redo stack.
- **Expression evaluation:** Reverse Polish Notation evaluates with a single stack. Numbers are pushed; operators pop two operands, compute, and push the result.
- **DFS (iterative):** An explicit stack replaces the call stack, visiting the most recently discovered node first.

## Queues: First-In, First-Out (FIFO)

A queue supports:

- **Enqueue:** add an element to the back
- **Dequeue:** remove and return the front element
- **Peek:** read the front element without removing it

Elements are processed in arrival order.

### Implementation

A naive slice-backed queue has a subtle problem: `q = q[1:]` advances the slice header but never frees the underlying array. Over many dequeues, the backing array is never reclaimed -- a **memory leak**.

Better options:
- **Ring buffer (circular array):** Reuses array slots by wrapping indices with modulo. Both enqueue and dequeue are O(1) with no memory leak.
- **Linked list:** Enqueue at tail, dequeue at head, both O(1). No wasted memory, but worse cache locality.

### Applications

- **BFS:** The queue's FIFO order guarantees level-by-level exploration. Replacing the queue with a stack turns BFS into DFS.
- **Task scheduling:** OS process schedulers, print queues, and message brokers all process tasks in arrival order.
- **Sliding window:** A deque (double-ended queue) efficiently tracks the max/min in a sliding window.

## Queue from Two Stacks

A classic interview question: implement a FIFO queue using only two LIFO stacks.

Push all elements onto an `in` stack. When a dequeue is needed and the `out` stack is empty, pour all elements from `in` to `out` (reversing order). Pop from `out`.

Each element moves from `in` to `out` at most once, so the **amortized cost per operation is O(1)**, even though a single dequeue can be O(n) when the transfer happens.

Reversing a stack reverses LIFO into FIFO. Two reversals cancel out.

## Deque (Double-Ended Queue)

A deque supports push and pop at both ends in O(1). It generalizes both stacks (use one end) and queues (push at one end, pop at the other).

Go's standard library does not have a built-in deque, but `container/list` (doubly linked list) provides the same functionality.

## Key Takeaways

- Stacks are LIFO: push, pop, peek all O(1). Use when the most recent item matters (parsing, backtracking, DFS).
- Queues are FIFO: enqueue, dequeue, peek all O(1). Use when processing order must match arrival order (BFS, scheduling).
- Slice-backed queues in Go leak memory on dequeue. Use a ring buffer or linked list.
- A queue can be built from two stacks with O(1) amortized operations.
- A deque generalizes both: O(1) operations at both ends.
