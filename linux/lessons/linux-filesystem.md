---
title: "The Linux Filesystem"
summary: "The Filesystem Hierarchy Standard, key directories, inodes, symlinks vs hardlinks, and the everything-is-a-file philosophy."
reading_time_minutes: 4
order: 1
---

## Why This Matters

Linux organizes everything -- programs, configuration, hardware devices, running processes -- as entries in a single directory tree rooted at `/`. Understanding this layout is a prerequisite for everything else: debugging why a service can't find its config, understanding why a disk is full, or reasoning about what happens when you pipe output between commands. Every time you navigate a Linux system, you are traversing this tree.

## The Filesystem Hierarchy Standard

The FHS defines a conventional layout that most Linux distributions follow. The root `/` is the top of the tree. Every file on the system lives somewhere beneath it.

Key directories and their purposes:

| Directory | Purpose |
|---|---|
| `/etc` | System-wide configuration files. Network settings, user accounts, service configs. Edited by admins, read by services. |
| `/home` | User home directories. Each user gets `/home/username/` for personal files and settings. |
| `/var` | Variable runtime data: logs (`/var/log/`), mail spools, package caches, database files. Unlike `/etc` (static config), `/var` grows during normal operation. |
| `/tmp` | Temporary files. Any user can write here. Often mounted as `tmpfs` (RAM-backed) and cleared on reboot. Do not store anything important here. |
| `/usr` | Installed user programs and libraries. `/usr/bin` for commands, `/usr/lib` for libraries. Read-only in normal operation. |
| `/bin`, `/sbin` | Essential system binaries (or symlinks to `/usr/bin`, `/usr/sbin` on modern distros). |
| `/proc` | A virtual filesystem -- not on disk. The kernel exposes process and system information here as readable files. `/proc/1/` contains information about process 1 (systemd). `/proc/cpuinfo` shows CPU details. |
| `/sys` | Another virtual filesystem for kernel and hardware information. Used to read and write hardware parameters. |
| `/dev` | Device files. `/dev/sda` is your first disk. `/dev/null` discards everything written to it. `/dev/random` produces random bytes. |

## Everything Is a File

Linux treats almost everything as a file. Not just text and binary files, but also:

- **Directories** -- special files containing a list of names and their inodes
- **Devices** -- `/dev/sda` lets you read/write a disk block by block; `/dev/null` is the "discard" device
- **Processes** -- `/proc/<pid>/` is a directory where you can read a process's memory maps, open file descriptors, and status
- **Sockets and pipes** -- network connections and IPC mechanisms are represented as file descriptors

The practical consequence: tools that work with files (cat, grep, awk, read/write operations) can work with hardware, processes, and network sockets using the same interface.

## Inodes

Every file and directory on disk is represented by an **inode** -- a data structure containing:

- File size
- Ownership (UID, GID)
- Permission bits
- Timestamps (created, modified, accessed)
- Pointers to the actual data blocks on disk

What an inode does **not** contain: the filename. Filenames live in directory entries, which map a name to an inode number. A single inode can have multiple directory entries pointing to it -- that is what a hardlink is.

## Symlinks vs Hardlinks

Both create additional filesystem entries pointing to existing data, but they work at different levels.

**Hardlink** -- a directory entry that points directly to an existing inode. The original file and the hardlink share the same inode: same data, same permissions, same inode number. Deleting one does not affect the other because the data persists until the last reference is removed.

```
file.txt ──┐
            ├── inode 12345 ── data blocks
hardlink ──┘
```

**Symlink (symbolic link)** -- a separate file with its own inode whose content is a path to the target. It is a pointer to a name, not to data. If the target is deleted or moved, the symlink becomes a dangling reference.

```
symlink (inode 99999) ── "/path/to/file.txt" ── inode 12345 ── data blocks
```

**Key constraints:**

- Hardlinks cannot cross filesystem boundaries (inodes are per-filesystem)
- Hardlinks cannot point to directories (to prevent filesystem cycles)
- Symlinks can point anywhere -- other filesystems, directories, even paths that do not exist yet

**In practice:** symlinks are far more common. They create version aliases (`/usr/bin/python -> python3.12`), reference shared libraries, and switch between configurations.

## Mount Points

Linux supports multiple physical storage devices and filesystems by **mounting** them into the directory tree. A mount point is any directory; when you mount a filesystem there, its contents appear as the subdirectory's contents.

```bash
mount /dev/sdb1 /mnt/data   # make sdb1's contents appear at /mnt/data
```

The single-tree model means you interact with all filesystems -- local disks, network shares, USB drives -- using the same path structure. `/proc` and `/sys` are mounted as virtual filesystems that have no underlying physical storage at all.

## Key Takeaways

- The FHS defines where things live: `/etc` for config, `/var` for runtime data, `/tmp` for throwaway files, `/proc` and `/sys` for kernel/process info.
- Inodes store file metadata (size, ownership, permissions, data pointers) but not the filename.
- A hardlink is a second directory entry pointing to the same inode. A symlink is a file whose content is a path to another file.
- Hardlinks cannot cross filesystems or point to directories. Symlinks have no such restrictions.
- Everything-is-a-file: devices, processes, and sockets are accessible via the same read/write interface as regular files.
