---
title: "Users, Groups, and Permissions"
summary: "The Linux ownership model, read/write/execute bits, octal notation, chmod, chown, the directory execute bit, and umask."
reading_time_minutes: 4
order: 2
---

## Why This Matters

Permissions are why `sudo` exists, why scripts fail with "Permission denied," and why production servers don't let web processes write to `/etc`. Understanding the ownership model is essential for debugging access errors, hardening systems, and correctly setting up services that run as non-root users.

## Users and Groups

Every Linux user has a **UID** (user ID) -- a number. The kernel uses UIDs internally; usernames are just human-readable aliases stored in `/etc/passwd`. Root always has UID 0.

**Groups** let you grant shared access. Every user has a primary group (stored in `/etc/passwd`) and can belong to additional supplementary groups (stored in `/etc/group`). Groups have a **GID** (group ID).

When a process runs, it has an effective UID and GID that determine what files it can access.

## The Ownership Model

Every file has exactly one **owner** (a UID) and one **group** (a GID). Permissions are split into three classes:

- **User (u):** The file's owner
- **Group (g):** Members of the file's assigned group
- **Other (o):** Everyone else

Each class gets three permission bits:

| Bit | Value | For files | For directories |
|---|---|---|---|
| **Read (r)** | 4 | Can read file contents | Can list directory contents (`ls`) |
| **Write (w)** | 2 | Can modify file contents | Can create, delete, rename files inside |
| **Execute (x)** | 1 | Can run as a program | Can traverse (enter the directory, access files by path) |

The kernel checks permissions in order: if you are the owner, apply user bits. If you are in the group, apply group bits. Otherwise, apply other bits. Only one class applies -- the most specific one.

## Octal Notation

Each class's three bits (r, w, x) map to a single octal digit. Add the values of the bits that are set:

```
r=4, w=2, x=1
```

**Example: 755 = rwxr-xr-x**
- User: 7 = 4+2+1 = rwx (full access)
- Group: 5 = 4+0+1 = r-x (read and traverse)
- Other: 5 = 4+0+1 = r-x (read and traverse)

**Example: 644 = rw-r--r--**
- User: 6 = 4+2+0 = rw- (read and write)
- Group: 4 = 4+0+0 = r-- (read only)
- Other: 4 = 4+0+0 = r-- (read only)

**Common defaults:**
- `755` -- executables and directories (world-readable, owner-writable)
- `644` -- regular files (world-readable, owner-writable, not executable)
- `700` -- private directories or scripts (owner only)
- `600` -- private files like SSH keys (owner read/write only)

## The Directory Execute Bit

The execute bit on a directory means "permission to traverse" -- to enter the directory and access files inside it by path. Without the execute bit, you cannot `cd` into the directory or open files inside it, even if you can list the directory name.

```bash
chmod 644 /data      # r--r--r-- : can ls /data but cannot cd /data or open /data/file
chmod 755 /data      # rwxr-xr-x : can ls, cd, and access files inside
```

This is why directory permissions are almost always odd numbers (5, 7) -- the execute bit is almost always needed.

## chmod and chown

**`chmod`** changes permission bits. It accepts octal notation or symbolic notation:

```bash
chmod 755 script.sh        # set exactly rwxr-xr-x
chmod u+x script.sh        # add execute for owner only
chmod go-w file.txt        # remove write from group and other
chmod -R 755 /var/www/     # recursive: apply to directory and all contents
```

**`chown`** changes the file's owner and/or group:

```bash
chown alice file.txt            # change owner to alice
chown alice:developers file.txt # change owner and group
chown -R www-data:www-data /var/www/  # recursive
```

Only root can change file ownership. Regular users can change permissions on files they own.

**`chgrp`** changes only the group. In practice, `chown user:group` does both in one command, so `chgrp` is rarely used.

## umask

When a process creates a new file, the default permissions are determined by the **umask** -- a set of bits to *remove* from the default (666 for files, 777 for directories).

```bash
umask       # show current umask, e.g. 022
umask 022   # set umask: removes write from group and other
```

With umask 022:
- New file: 666 - 022 = 644 (rw-r--r--)
- New directory: 777 - 022 = 755 (rwxr-xr-x)

The umask is inherited by child processes. Login shells pick it up from `/etc/profile` or `~/.bashrc`. Web servers often set their own umask so uploaded files have controlled permissions.

## Key Takeaways

- Every file has an owner (UID) and a group (GID). Permissions apply to three classes: user, group, other.
- Read (4), write (2), execute (1) -- add these values to get an octal digit per class. 755 = rwxr-xr-x.
- The execute bit on a **directory** means "permission to traverse," not run. Without it, you cannot `cd` into the directory.
- `chmod` changes permission bits; `chown` changes ownership. Both accept `-R` for recursive operation.
- `umask` is a bit mask that removes permissions from newly created files. umask 022 produces 644 files and 755 directories.
