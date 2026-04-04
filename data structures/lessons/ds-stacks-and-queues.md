---
title: "Stacks and Queues"
summary: "LIFO vs FIFO semantics, push/pop/enqueue/dequeue in O(1), slice-backed and linked-list implementations, and classic applications like parentheses matching and BFS."
reading_time_minutes: 6
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

A dynamic array (Python `list`) is the standard backing structure. Push is `append`, pop reads and removes the last element. Both are O(1) amortized. A linked list also works (push/pop at the head), but the array version has better cache locality.

```python
# Stack using a Python list
stack = []
stack.append(10)   # push
stack.append(20)   # push
stack.append(30)   # push
top = stack[-1]    # peek -> 30
val = stack.pop()  # pop -> 30
print(stack)       # [10, 20]
```

### Applications

- **Parentheses matching:** Push every opener. On a closer, check that the top matches. If the stack is empty at the end with no mismatches, the string is balanced.

```python
def is_valid_parens(s):
    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    for ch in s:
        if ch in '([{':
            stack.append(ch)
        elif ch in pairs:
            if not stack or stack[-1] != pairs[ch]:
                return False
            stack.pop()
    return len(stack) == 0

print(is_valid_parens("({[]})"))  # True
print(is_valid_parens("([)]"))    # False
```
- **Undo/redo:** Each action pushes onto the undo stack. Undo pops and pushes onto the redo stack.
- **Expression evaluation:** Reverse Polish Notation evaluates with a single stack. Numbers are pushed; operators pop two operands, compute, and push the result.
- **DFS (iterative):** An explicit stack replaces the call stack, visiting the most recently discovered node first.

## Queues: First-In, First-Out (FIFO)

A queue supports:

- **Enqueue:** add an element to the back
- **Dequeue:** remove and return the front element
- **Peek:** read the front element without removing it

Elements are processed in arrival order. Think of a line at a coffee shop -- first person in line is served first.

```python
from collections import deque

queue = deque()
queue.append(10)    # enqueue
queue.append(20)    # enqueue
queue.append(30)    # enqueue
front = queue[0]    # peek -> 10
val = queue.popleft()  # dequeue -> 10
print(queue)        # deque([20, 30])
```

### Implementation

A naive list-backed queue has a subtle problem: `q.pop(0)` shifts all remaining elements, making dequeue O(n). Python's `collections.deque` uses a doubly-linked list of blocks, giving O(1) for both ends.

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

```python
class QueueFromStacks:
    def __init__(self):
        self.in_stack = []
        self.out_stack = []

    def enqueue(self, val):
        self.in_stack.append(val)

    def dequeue(self):
        if not self.out_stack:
            while self.in_stack:
                self.out_stack.append(self.in_stack.pop())
        return self.out_stack.pop()
```

## Deque (Double-Ended Queue)

A deque supports push and pop at both ends in O(1). It generalizes both stacks (use one end) and queues (push at one end, pop at the other).

Python's `collections.deque` is a deque -- it supports `append()`, `appendleft()`, `pop()`, and `popleft()`, all in O(1).

## Key Takeaways

- Stacks are LIFO: push, pop, peek all O(1). Use when the most recent item matters (parsing, backtracking, DFS).
- Queues are FIFO: enqueue, dequeue, peek all O(1). Use when processing order must match arrival order (BFS, scheduling).
- Avoid `list.pop(0)` for queues in Python -- it is O(n). Use `collections.deque` for O(1) operations at both ends.
- A queue can be built from two stacks with O(1) amortized operations.
- A deque generalizes both: O(1) operations at both ends.

## Related Problems

- **Valid Parentheses** -- classic stack problem: push openers, pop on closers
