---
title: "Essential Commands"
summary: "File operations, text processing with grep/sed/awk, system inspection with ps/top/df/du, and networking basics with curl and ss."
reading_time_minutes: 5
order: 5
---

## Why This Matters

Linux commands are the building blocks of everything from deployment scripts to debugging sessions. Knowing which tool to reach for -- and how to compose them -- is the difference between spending 30 seconds or 30 minutes on a problem. These are the commands that come up in every sysadmin interview and every production incident.

## File Operations

**`ls`** -- List directory contents.
```bash
ls -la /etc     # -l: long format (permissions, owner, size), -a: include hidden files
ls -lh          # -h: human-readable sizes (KB, MB, GB)
ls -lt          # -t: sort by modification time (newest first)
```

**`find`** -- Search the filesystem by file name, type, size, or modification time.
```bash
find /var/log -name "*.log" -mtime -7     # logs modified in last 7 days
find . -type f -name "*.py"               # Python files in current tree
find /tmp -size +100M                     # files larger than 100MB
```

`find` traverses directories recursively. It is for locating files by filesystem metadata (name, size, date) -- not for searching file contents. Use `grep` for content.

**`cp`, `mv`, `rm`** -- Copy, move, and remove files.
```bash
cp -r src/ dest/          # recursive copy
mv old.txt new.txt        # rename (or move to another directory)
rm -rf /tmp/build/        # recursive delete, no confirmation -- be careful
```

`rm` has no undo. On production systems, prefer moving files to a temp location before deleting.

## Text Processing: grep, sed, awk

These three compose naturally via pipes. They operate on text streams line by line.

**`grep`** -- Filter lines matching a pattern.
```bash
grep "ERROR" app.log                 # lines containing ERROR
grep -r "TODO" src/                  # recursive search across files
grep -i "warning" app.log            # case-insensitive
grep -v "DEBUG" app.log              # invert: lines NOT matching
grep -c "ERROR" app.log              # count matching lines
```

Use `grep` when you need: "does this pattern appear?" or "show me lines containing X."

**`sed`** -- Stream editor. Transform text line by line.
```bash
sed 's/old/new/g' file.txt           # replace all occurrences per line
sed -i 's/localhost/prod.db/g' config.yaml   # in-place edit
sed '5d' file.txt                    # delete line 5
sed -n '10,20p' file.txt             # print only lines 10-20
```

Use `sed` when you need: substitutions, deletions, or extracting line ranges.

**`awk`** -- Field-based processing. Splits each line into fields and operates on them.
```bash
awk '{print $1, $3}' data.txt        # print columns 1 and 3 (space-delimited)
awk -F: '{print $1}' /etc/passwd     # print usernames (: as delimiter)
awk '$3 > 100 {print $1}' data.txt   # conditional: print col 1 where col 3 > 100
awk '{sum += $1} END {print sum}'    # accumulate and print total
```

Use `awk` when you need: column extraction, filtering rows by field value, or computing summaries.

**Mental model: grep filters rows. sed transforms content. awk selects columns and computes.** They compose:

```bash
grep "200" access.log | awk '{print $7}' | sort | uniq -c | sort -rn | head -10
# filter 200 responses → extract URL column → sort → count unique → show top 10 URLs
```

## System Inspection

**`ps`** -- Snapshot of current processes.
```bash
ps aux                     # all processes, BSD-style output
ps -ef                     # all processes, UNIX-style output
ps aux | grep nginx         # find nginx processes
```

Columns to know: PID, %CPU, %MEM, STAT (process state), COMMAND.

**`top`** / **`htop`** -- Live process monitor. `top` is always available. `htop` is more readable but not always installed. Press `q` to quit, `k` to kill a process by PID, `M` to sort by memory.

**`df`** -- Disk filesystem usage. Shows used and available space per mounted filesystem.
```bash
df -h       # human-readable sizes
df -h /     # just the root filesystem
```

**`du`** -- Disk usage of directories and files. Use when you need to find what's consuming space.
```bash
du -sh /var/log/           # total size of /var/log/
du -sh /var/log/*          # size of each item inside /var/log/
du -sh /* | sort -rh       # sort all top-level dirs by size, largest first
```

**`free`** -- Memory usage.
```bash
free -h    # show RAM and swap in human-readable units
```

## Networking Basics

**`curl`** -- Transfer data to/from URLs. The Swiss army knife for HTTP debugging.
```bash
curl https://api.example.com/health           # GET request
curl -X POST -H "Content-Type: application/json" \
     -d '{"key": "value"}' https://api.example.com/data
curl -I https://example.com                   # headers only
curl -o file.tar.gz https://example.com/file  # download to file
curl -v https://example.com                   # verbose: show request and response headers
```

**`wget`** -- Download files. Simpler than curl for downloading, supports resuming interrupted downloads.
```bash
wget https://example.com/archive.tar.gz          # download file
wget -c https://example.com/large.tar.gz         # resume interrupted download
```

When to use which: use `curl` for API testing and scripting (more control, better for pipes). Use `wget` for downloading files, especially large ones you might need to resume.

**`ss`** (or `netstat`)  -- Show network socket state.
```bash
ss -tlnp    # TCP (-t), listening (-l), show port numbers (-n), show process (-p)
ss -anp     # all sockets, numeric, with processes
```

**`dig`** -- DNS lookup tool.
```bash
dig example.com           # A record lookup
dig MX example.com        # mail exchange records
dig @8.8.8.8 example.com  # query specific DNS server
```

## Composing Commands

The real power comes from composition. A few patterns that come up constantly:

```bash
# Find the 10 largest files in /var
find /var -type f -printf '%s %p\n' | sort -rn | head -10

# Count unique IP addresses in an access log
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -20

# Watch a log file and highlight errors
tail -f /var/log/app.log | grep --color "ERROR"

# Check if a service is listening
ss -tlnp | grep :8080
```

## Key Takeaways

- `find` searches by filesystem metadata (name, size, date). `grep` searches file contents. Different tools for different problems.
- `grep` filters rows, `sed` transforms content line by line, `awk` processes fields. Compose them with pipes.
- `df` shows filesystem-level disk usage (is your disk full?). `du` shows directory-level usage (what is using the space?).
- `ps aux` / `top` for process inspection. `free -h` for memory. `ss -tlnp` for open ports.
- `curl` for API testing and scripted HTTP. `wget` for file downloads with resume support.
