---
title: "Shell, Pipes, and I/O Redirection"
summary: "What a shell is, stdin/stdout/stderr, file descriptors, redirection operators, pipes, environment variables, and PATH."
reading_time_minutes: 4
order: 4
---

## Why This Matters

The shell is the primary interface to a Linux system. Piping and redirection let you compose simple commands into powerful workflows without writing any code. Understanding file descriptors and how stderr is separate from stdout prevents the silent data corruption that happens when you blindly pipe output that includes error messages.

## What Is a Shell?

A **shell** is a command interpreter -- a program that reads commands from you, runs programs, and returns their output. Common shells: `bash` (most ubiquitous), `zsh` (macOS default, feature-rich), `sh` (POSIX-compliant minimal shell), `fish` (interactive-focused).

When you open a terminal, a shell process starts. When you type a command, the shell forks a child process, executes the command there, waits for it to finish, and prints the next prompt. The shell also handles job control, environment variables, and the special syntax for redirection and pipes.

## File Descriptors

Every running process starts with three standard file descriptors (FDs) -- integer handles referencing open "files" (which in Linux can be a real file, a terminal, a socket, or a pipe):

| FD | Name | Default connection |
|---|---|---|
| **0** | stdin | Keyboard input |
| **1** | stdout | Terminal display |
| **2** | stderr | Terminal display |

File descriptor 0 is where the process reads input. FDs 1 and 2 are where it writes output and errors. Programs decide which stream to use -- by convention, normal output goes to stdout and error messages/diagnostics go to stderr.

Why two output streams? So you can pipe a program's normal output to another command while still seeing its errors on the terminal, or redirect output to a file without error messages contaminating the data.

## Redirection

Redirection changes where a file descriptor points before the command runs.

**Output redirection:**
```bash
command > file.txt    # redirect stdout to file (overwrites)
command >> file.txt   # redirect stdout to file (appends)
command 2> errors.txt # redirect stderr to file
command 2>&1          # redirect stderr to wherever stdout currently points
command > file.txt 2>&1  # both stdout and stderr to file
```

The `2>&1` syntax: `2` is stderr's FD number, `>` means "redirect," `&1` means "to the same destination as FD 1." Order matters: `> file.txt 2>&1` redirects stdout to the file first, then points stderr at stdout's (now-file) destination. Writing `2>&1 > file.txt` is wrong -- it points stderr at the terminal, then redirects stdout to the file.

**Input redirection:**
```bash
command < file.txt    # feed file contents to stdin
```

**Special destinations:**
```bash
command > /dev/null      # discard stdout (the "bit bucket")
command > /dev/null 2>&1 # discard all output
```

## Pipes

A **pipe** (`|`) connects stdout of one command to stdin of the next. Commands run concurrently -- the left side writes and the right side reads in parallel, buffered by the kernel.

```bash
ls -la | grep ".log"       # filter ls output
cat access.log | awk '{print $9}' | sort | uniq -c | sort -rn
# extract HTTP status codes, count occurrences, show most common first
```

Pipes only carry stdout. If the left command writes to stderr, those messages bypass the pipe and appear on the terminal. To pipe both:

```bash
command 2>&1 | next-command
```

Pipes are anonymous -- they are created by the shell, live only for the duration of the pipeline, and vanish when the commands exit. Named pipes (`mkfifo`) have a filesystem path and persist.

## Environment Variables

Every process has an **environment** -- a set of key=value pairs inherited from its parent.

```bash
export MY_VAR="hello"  # set a variable and export it to child processes
echo $MY_VAR            # reference a variable
env                     # list all environment variables
```

A variable set without `export` is local to the current shell session. `export` makes it available to child processes (the shell sets the variable in the environment block passed to `exec()`).

Common environment variables:

| Variable | Purpose |
|---|---|
| `PATH` | Colon-separated list of directories to search for commands |
| `HOME` | Current user's home directory |
| `USER` | Current username |
| `SHELL` | Path to the current shell |
| `EDITOR` | Default text editor |

## PATH

When you type `ls`, the shell does not know where `ls` lives. It searches each directory in `PATH` in order until it finds an executable named `ls`.

```bash
echo $PATH
# /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

which ls   # /usr/bin/ls
```

To add a directory to PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"   # prepend (searched first)
```

This is why programs installed to `~/.local/bin` or `/usr/local/bin` work from the command line after you update PATH. It is also why a misconfigured PATH is the first thing to check when `command not found` appears for something you just installed.

## Subshells

Running a command in parentheses creates a **subshell** -- a child shell process that inherits the current environment but cannot modify the parent's state.

```bash
(cd /tmp && ls)   # subshell: cd does not affect the parent shell's cwd
cd /tmp && ls     # no subshell: cd changes the parent shell's cwd
```

Command substitution -- `$(command)` or `` `command` `` -- also runs in a subshell and substitutes its stdout into the enclosing command:

```bash
today=$(date +%Y-%m-%d)    # captures date's output as a variable
echo "Today is $today"
```

## Key Takeaways

- The shell interprets commands, forks processes to run them, and handles redirection/pipes as special syntax.
- Every process starts with FD 0 (stdin), FD 1 (stdout), FD 2 (stderr). Redirection changes where these point.
- `>` overwrites, `>>` appends. `2>&1` redirects stderr to stdout's current destination.
- A pipe (`|`) connects stdout of one process to stdin of the next, running them concurrently.
- `PATH` is a colon-separated list of directories the shell searches for executables.
- `export VAR=value` makes a variable available to child processes; without export, it stays in the current shell only.
