---
title: "Processes and Signals"
summary: "What a process is, PIDs, parent-child relationships, fork/exec, process states, signals, and the process-vs-thread distinction."
reading_time_minutes: 5
order: 3
---

## Why This Matters

When a web server stops responding, a cron job fails silently, or a program hangs, you need to understand processes to diagnose it. `ps`, `kill`, and knowledge of process states are everyday tools. Signals are how the OS communicates asynchronously with running programs -- understanding them lets you control processes correctly instead of reaching for `kill -9` as a first resort.

## What Is a Process?

A **process** is a running instance of a program. The OS gives each process:

- Its own virtual address space (memory the process believes it owns exclusively)
- A set of open file descriptors
- A set of signal handlers
- A **PID** (process ID) -- a unique integer assigned by the kernel
- A **PPID** (parent process ID) -- the PID of the process that created it

Every process on a Linux system is part of a tree rooted at PID 1 (systemd on modern distros, init on older ones). You can see the tree with `pstree`.

## fork and exec

New processes are created through two system calls:

**`fork()`** -- Creates an exact copy of the calling process. The new process (child) gets a new PID but inherits the parent's memory, file descriptors, and signal handlers. The memory is not immediately copied -- Linux uses copy-on-write, so pages are only duplicated when either process writes to them.

**`exec()`** -- Replaces the current process's memory image with a new program. The PID stays the same; the code, data, and stack are replaced.

The typical sequence: shell calls `fork()` to create a child, then the child calls `exec()` to load the program you typed. The shell waits with `wait()` for the child to finish.

```
shell process
   |-- fork() --> child process (same PID as parent for a moment)
                     |-- exec("ls") --> ls replaces child's memory
                                          |-- exits
shell receives exit status via wait()
```

## Process States

A process is not always running. The kernel scheduler moves processes between states:

| State | Meaning |
|---|---|
| **Running (R)** | Currently executing on a CPU |
| **Sleeping (S)** | Waiting for an event (I/O, timer, signal) -- interruptible, can be killed |
| **Disk sleep (D)** | Waiting for I/O, cannot be interrupted or killed -- "unkillable" in this state |
| **Stopped (T)** | Paused, e.g., by `Ctrl+Z` or SIGSTOP |
| **Zombie (Z)** | Exited, but parent hasn't called `wait()` yet. The process entry is preserved until the parent acknowledges the exit. Not consuming CPU or memory (other than the table entry). |

You can see process states in the `STAT` column of `ps aux`.

## Zombie and Orphan Processes

**Zombie:** A process that has exited but whose parent has not yet called `wait()` to collect its exit status. The kernel keeps the process entry alive (consuming a table slot) until the parent acknowledges. A few zombies are normal. Many zombies indicate a parent that is not properly reaping children.

**Orphan:** A process whose parent has exited before it. The kernel re-parents the orphan to PID 1 (systemd/init), which calls `wait()` on any children it inherits. This is why background processes started from a shell continue running after you log out -- they become children of init.

## Signals

A signal is an asynchronous notification sent to a process by the kernel, by another process, or by the user (keyboard shortcuts send signals). The process can:

- **Handle** the signal -- run a custom handler function
- **Ignore** the signal
- **Accept the default action** (which varies by signal; usually terminate)

The signals you will use most:

| Signal | Number | Default | Can ignore/catch? | When sent |
|---|---|---|---|---|
| **SIGTERM** | 15 | Terminate | Yes | `kill <pid>` (default) |
| **SIGKILL** | 9 | Terminate | No | `kill -9 <pid>` |
| **SIGINT** | 2 | Terminate | Yes | Ctrl+C |
| **SIGHUP** | 1 | Terminate | Yes | Terminal closed; by convention, reload config |
| **SIGTSTP** | 20 | Stop | Yes | Ctrl+Z (suspends process) |
| **SIGSTOP** | 19 | Stop | No | `kill -STOP <pid>` |

**SIGTERM vs SIGKILL:** Always try SIGTERM first. A well-written process catches SIGTERM to flush buffers, close connections, and deregister from service discovery before exiting. SIGKILL bypasses all handlers -- the kernel terminates the process immediately with no cleanup. Open files are not flushed, database connections are not closed, and temporary files are not removed. SIGKILL is for unresponsive processes only.

**SIGHUP convention:** Originally sent when a terminal connection was lost. Daemons (which have no terminal) repurposed the signal to mean "reload your configuration file." This is why `nginx -s reload` works by sending SIGHUP to the nginx master process.

## Processes vs Threads

A **thread** is an execution unit within a process. Threads share the process's address space, file descriptors, and signal handlers. Creating a thread is cheaper than forking a process because no memory copying is needed.

| | Process | Thread |
|---|---|---|
| Memory | Isolated address space | Shared with other threads in the process |
| Creation cost | Higher (fork copies page tables) | Lower (shares existing address space) |
| Failure isolation | A crash does not affect other processes | A crash can corrupt shared memory and kill the whole process |
| Communication | IPC (pipes, sockets, shared memory) | Direct (shared memory, but requires synchronization) |

Linux does not distinguish processes and threads at the kernel level. Both are `task_struct` entries in the scheduler. The `clone()` syscall creates both -- flags like `CLONE_VM` (share memory) and `CLONE_FILES` (share file descriptors) determine how much is shared.

## The /proc Filesystem

`/proc` is a virtual filesystem where the kernel exposes process and system information as readable files.

```
/proc/<pid>/
    cmdline    -- command line arguments (null-separated)
    status     -- human-readable process status (state, memory, PID, PPID)
    fd/        -- symlinks to every open file descriptor
    maps       -- memory map (which libraries are loaded, at what addresses)
    environ    -- environment variables at process start
```

This is how `ps`, `top`, `lsof`, and strace work -- they read from `/proc`. You can inspect any process directly:

```bash
cat /proc/1/status          # systemd's status
ls -la /proc/$$/fd          # your shell's open file descriptors
```

## Key Takeaways

- Every process has a PID and PPID, forming a tree rooted at PID 1.
- `fork()` creates a copy of the current process. `exec()` replaces the current process with a new program. Shell commands use fork+exec.
- A zombie process has exited but the parent hasn't called `wait()` yet. An orphan is re-parented to init.
- SIGTERM (15) is the polite termination request -- the process can clean up. SIGKILL (9) cannot be caught or ignored -- the kernel terminates immediately.
- Threads share the process's address space; processes have isolated address spaces. A thread crash can take down the whole process.
- `/proc/<pid>/` exposes process internals (open FDs, memory maps, status) as regular files.
