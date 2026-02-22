---
title: "Docker Fundamentals"
summary: "What containers are, how they differ from VMs, and how Docker images, containers, Dockerfiles, and registries fit together."
reading_time_minutes: 4
order: 1
---

## Why This Matters

Docker is the standard tool for packaging and running software in isolated environments. If you deploy anything to the cloud, run a CI pipeline, or work on a team where "it works on my machine" has ever been a problem, you need to understand containers. Interview questions about Docker and containerization are common in backend and DevOps roles.

## What Is a Container?

A container is an isolated process (or group of processes) running on a host operating system. It has its own filesystem, its own network interfaces, and its own process tree -- but it shares the host's kernel.

The isolation comes from two Linux kernel features:

- **Namespaces** control what a container can *see*. Each container gets its own view of process IDs, network interfaces, mount points, and hostnames. A process inside the container cannot see processes in other containers or on the host.
- **Cgroups** (control groups) control what a container can *use*. They set limits on CPU, memory, disk I/O, and network bandwidth. A runaway process inside one container cannot starve others.

A container is not a lightweight VM. A VM runs a full guest operating system with its own kernel on top of a hypervisor. A container runs directly on the host kernel with isolation enforced by the kernel itself.

## Containers vs Virtual Machines

| | Container | VM |
|---|---|---|
| **Kernel** | Shares host kernel | Runs its own kernel |
| **Startup** | Milliseconds (just a process) | Seconds to minutes (boots an OS) |
| **Size** | Tens of MB | Gigabytes (includes full OS) |
| **Isolation** | Process-level (namespaces + cgroups) | Hardware-level (hypervisor) |
| **Density** | Hundreds per host | Dozens per host |

**When containers win:** Microservices, CI/CD, rapid scaling, dev/prod parity.

**When VMs win:** Running different OS kernels, strong tenant isolation, legacy apps that need a full OS.

The trade-off is isolation strength vs resource efficiency.

## Images, Containers, and Dockerfiles

These three concepts form Docker's core mental model.

**A Docker image** is a read-only template containing everything needed to run an application: code, runtime, libraries, environment variables, and configuration. Think of it as a snapshot of a filesystem plus metadata about how to run it.

**A container** is a running instance of an image. You can run many containers from the same image, just like you can run many processes from the same binary. Each container gets its own writable layer on top of the image's read-only layers.

**A Dockerfile** is a text file with instructions for building an image. Each instruction (`FROM`, `RUN`, `COPY`, etc.) adds a layer to the image. Docker reads the Dockerfile top to bottom and executes each instruction in sequence.

```dockerfile
FROM python:3.12-slim
COPY . /app
RUN pip install -r /app/requirements.txt
CMD ["python", "/app/main.py"]
```

This Dockerfile says: start from a Python base image, copy the application code in, install dependencies, and define the default command.

## Registries

A **registry** is a server that stores and distributes Docker images. When you `docker pull nginx`, Docker downloads the image from a registry. When you `docker push myapp:v1`, you upload your image to one.

**Docker Hub** is the default public registry. Most official images (nginx, postgres, python, node) live there. Organizations typically also use a private registry (AWS ECR, Google Artifact Registry, GitHub Container Registry) for their own images.

The workflow: build an image locally from a Dockerfile, push it to a registry, pull it on the target server, and run it.

## The Docker Workflow

```
Dockerfile  --docker build-->  Image  --docker run-->  Container
                                 |
                          docker push / pull
                                 |
                             Registry
```

1. **Write** a Dockerfile describing your application's environment
2. **Build** an image from the Dockerfile (`docker build -t myapp .`)
3. **Push** the image to a registry (`docker push myapp:v1`)
4. **Pull** the image on the target machine (`docker pull myapp:v1`)
5. **Run** a container from the image (`docker run myapp:v1`)

The image is the portable artifact. Build once, run anywhere that has Docker installed.

## Key Takeaways

- A container is an isolated process using Linux namespaces (what it sees) and cgroups (what it uses), not a lightweight VM.
- An image is a read-only filesystem template. A container is a running instance of an image with a writable layer on top.
- A Dockerfile is a recipe for building an image, executed instruction by instruction.
- Registries store and distribute images. Build locally, push to a registry, pull and run anywhere.
