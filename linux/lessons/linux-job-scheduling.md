---
title: "Job Control and Scheduling"
summary: "Foreground vs background jobs, fg/bg/jobs, nohup, Ctrl+Z, cron and crontab format, and when to use systemd timers."
reading_time_minutes: 4
order: 6
---

## Why This Matters

Every developer eventually needs to run a long-running process in the background, schedule a recurring task, or figure out why a cron job is silently failing. Job control lets you manage processes from an interactive shell. Cron is the backbone of automated task scheduling on Linux. Understanding both prevents you from blindly running `&` and losing track of processes, and from spending hours debugging cron jobs that fail only in the scheduled environment.

## Foreground vs Background

By default, when you run a command in the shell, it runs in the **foreground** -- the shell waits for it to complete and you cannot type another command. The command is connected to your terminal's stdin, stdout, and stderr.

Running a command with `&` puts it in the **background** -- the shell returns the prompt immediately while the command continues running as a background job.

```bash
sleep 100 &          # start in background; shell prints [1] 12345 (job number, PID)
```

Background jobs still have their stdout and stderr connected to your terminal (unless redirected). Output appears interleaved with your prompt -- redirect it to avoid the mess:

```bash
long-running-command > output.log 2>&1 &
```

## Job Control Commands

The shell tracks background jobs with job numbers (separate from PIDs).

```bash
jobs             # list all background jobs for this shell session
fg               # bring the most recent background job to the foreground
fg %2            # bring job number 2 to the foreground
bg               # resume the most recent stopped job in the background
bg %2            # resume job 2 in the background
kill %2          # kill job 2 by job number (shell expands to its PID)
```

**Ctrl+Z** sends SIGTSTP to the foreground process, suspending it (state T -- stopped). The shell takes back the prompt and shows the job number. From there, use `fg` to resume in the foreground or `bg` to resume in the background.

```
$ python train.py      # starts running
^Z                     # Ctrl+Z -- suspends it
[1]+  Stopped    python train.py
$ bg                   # resume in background
[1]+ python train.py &
```

## nohup: Surviving Terminal Close

Background jobs (`&`) are still children of the shell process. When you close the terminal, the shell sends SIGHUP to all its child processes -- they terminate. `nohup` runs the command with SIGHUP ignored:

```bash
nohup long-running-script.sh > output.log 2>&1 &
```

`nohup` disconnects the command from the terminal (stdin becomes `/dev/null`, stdout/stderr default to `nohup.out` unless redirected). The process survives terminal close because it ignores SIGHUP and has no terminal to lose.

For production use, `systemd` services are a better choice than `nohup` -- they handle restarts, logging, and dependency ordering. Use `nohup` for ad-hoc tasks where you do not want to write a service unit file.

## Cron

Cron is the traditional Unix job scheduler. The **cron daemon** reads **crontab files** and runs commands at their scheduled times.

Edit your crontab:
```bash
crontab -e    # edit your user crontab
crontab -l    # list your current crontab
crontab -r    # remove your crontab (careful -- no confirmation)
```

## Crontab Format

Each line is a job with five time fields followed by the command:

```
minute  hour  day-of-month  month  day-of-week  command
 0-59  0-23      1-31       1-12     0-7 (0=Sun)
```

Special values:
- `*` -- any value (wildcard)
- `*/n` -- every n units (e.g., `*/15` in minute field = every 15 minutes)
- `1,15` -- list (e.g., on the 1st and 15th)
- `1-5` -- range (e.g., Monday through Friday)

**Reading examples:**
```
0 5 * * *        # 5:00 AM every day
*/15 * * * *     # every 15 minutes
0 0 * * 0        # midnight every Sunday (day-of-week 0 = Sunday)
0 9 1 * *        # 9 AM on the first of every month
30 8 * * 1-5     # 8:30 AM Monday through Friday
```

## Cron Gotchas

**Minimal PATH environment.** Cron jobs run with a stripped-down environment. `PATH` is typically `/usr/bin:/bin`. Commands that work in your shell may fail in cron because they are not in the default PATH. Always use absolute paths:

```bash
# Wrong: relies on PATH
0 5 * * *  backup.sh

# Right: absolute path to both the script and any commands inside it
0 5 * * *  /home/alice/scripts/backup.sh
```

**No output handling by default.** Any stdout or stderr from a cron job is emailed to the user (via the local mail spool) if a mail agent is configured. If not, output silently vanishes. Always redirect explicitly:

```bash
0 5 * * *  /home/alice/scripts/backup.sh >> /var/log/backup.log 2>&1
```

**Home directory.** The working directory for a cron job is the user's home directory, not the script's location. Use `cd` in the command or use absolute paths throughout.

**Testing cron jobs.** The simplest debugging approach: run the exact command that cron would run, with the same minimal PATH, in a subshell:

```bash
env -i HOME=/home/alice PATH=/usr/bin:/bin /home/alice/scripts/backup.sh
```

## systemd Timers

Modern Linux systems with systemd also have **timers** -- systemd units that trigger other units on a schedule. They are more powerful than cron but require more setup.

Advantages over cron:
- Logging via journald (no mail, no manual redirect)
- Dependency ordering (run after the network is up, after a database is ready)
- Catch-up on missed runs (if the system was off, run on next boot)
- Monitoring via `systemctl status`

```bash
systemctl list-timers    # show all active timers and when they'll next run
```

**When to use which:**
- **Cron:** Simple recurring commands, user-level tasks, quick scripts that do not need restart logic or dependency management.
- **systemd timers:** Service-level tasks, tasks that need logging, tasks with dependencies, tasks on servers where you already manage services via systemd.

## Key Takeaways

- `&` runs a command in the background; `Ctrl+Z` suspends a foreground command. `fg` and `bg` move jobs between states.
- Background jobs (`&`) die when the terminal closes (SIGHUP). `nohup` makes a command survive terminal close.
- Crontab format: minute, hour, day-of-month, month, day-of-week, then command. `*` is any value, `*/n` is every n units.
- Cron runs with a minimal PATH -- use absolute paths. Redirect stdout/stderr or output silently vanishes.
- systemd timers are better than cron for service-level tasks because they integrate with journald logging and systemd dependency ordering.
