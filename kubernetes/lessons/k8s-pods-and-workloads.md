---
title: "Pods and Workloads"
summary: "What Pods are, how they differ from containers, the sidecar pattern, Pod lifecycle, and why bare Pods are an antipattern."
reading_time_minutes: 4
order: 2
---

## Why This Matters

The Pod is the fundamental unit of execution in Kubernetes. Before you can understand Deployments, StatefulSets, or any other workload type, you need to understand what a Pod is and why it exists as an abstraction over containers. Several common Kubernetes misconceptions -- including why bare Pods are an antipattern and why Namespaces are not security boundaries -- come directly from misunderstanding Pods.

## What Is a Pod?

A Pod is a group of one or more containers that are always scheduled and run together on the same node. Pods are the smallest unit Kubernetes can schedule, not individual containers.

The containers in a Pod share:
- **Network namespace** -- they all have the same IP address and port space. Two containers in the same Pod talk to each other via `localhost`.
- **Storage volumes** -- volumes mounted in a Pod are accessible to all containers in that Pod.

The containers in a Pod do **not** share:
- Filesystem (by default) -- each container has its own filesystem unless a volume is explicitly mounted
- Process namespace (by default) -- processes in one container cannot see processes in another unless `shareProcessNamespace: true` is set

Why not just schedule individual containers? Tightly coupled processes that must share network state or a filesystem need to run together on the same node. The Pod abstraction makes this relationship explicit and schedulable as a unit.

## Single-Container vs Multi-Container Pods

Most Pods contain a single container. A single-container Pod is simply a container with Kubernetes lifecycle management: health checks, resource limits, restart policies, and scheduling.

Multi-container Pods are used when containers have a genuine operational dependency. The canonical use case is the **sidecar pattern**.

## The Sidecar Pattern

A sidecar is a second container in a Pod that handles a cross-cutting concern for the main container, using their shared network namespace or volumes.

Common sidecars:
- **Log shipper:** The main container writes logs to a shared volume; the sidecar reads from that volume and ships logs to a centralized system (Elasticsearch, CloudWatch). The main container stays unaware of the logging infrastructure.
- **Proxy/service mesh agent:** Envoy or Linkerd inject a proxy sidecar that intercepts all network traffic for the Pod. The main container makes requests as normal; the sidecar handles mTLS, retries, and circuit breaking transparently.
- **Secret injector:** A sidecar (like Vault Agent) fetches secrets from an external vault and writes them to a shared volume. The main container reads secrets as files, with no vault client code in the application.

The sidecar pattern is powerful precisely because the main container requires no changes -- it just uses `localhost` for network communication or reads files from a shared volume.

## Pod Lifecycle

A Pod progresses through a sequence of phases:

| Phase | Meaning |
|---|---|
| **Pending** | The Pod has been accepted by the cluster, but one or more containers have not started yet. The scheduler may not have assigned a node, or images are still being pulled. |
| **Running** | The Pod has been bound to a node and at least one container is running. |
| **Succeeded** | All containers terminated with exit code 0. This is the terminal state for batch Jobs. |
| **Failed** | At least one container terminated with a non-zero exit code. |
| **Unknown** | The Pod status cannot be obtained (usually a node communication failure). |

Containers within a running Pod also have their own states: `Waiting`, `Running`, and `Terminated`. When a container terminates unexpectedly, the kubelet restarts it according to the Pod's `restartPolicy` (Always, OnFailure, or Never).

## Why You Should Never Create Bare Pods

A bare Pod is one you create directly with `kubectl run` or a Pod manifest, without a controller managing it. Bare Pods are dangerous for one reason: **if a bare Pod dies, it is not rescheduled**.

If the node running your bare Pod fails, the Pod is gone permanently. If the container crashes repeatedly and hits the restart backoff limit, the Pod goes into CrashLoopBackOff and stays there. No controller is watching it to recreate it elsewhere.

Always use a controller:
- **Deployment** for stateless applications (web servers, APIs)
- **StatefulSet** for stateful applications (databases)
- **Job** for batch workloads that run to completion
- **DaemonSet** for per-node agents

The controller maintains the desired number of replicas and reschedules Pods when nodes fail.

## Namespaces

A Namespace is a virtual partition within a cluster. Resources in one Namespace are separate from resources in another: Pods, Services, ConfigMaps, and Secrets all live within a Namespace.

Default Namespaces in every cluster:
- `default` -- where resources land if you do not specify a Namespace
- `kube-system` -- Kubernetes system components (DNS, kube-proxy, metrics server)
- `kube-public` -- cluster-wide configuration readable by all users

Namespaces provide **logical isolation and access control**, not network isolation. By default, a Pod in the `frontend` Namespace can freely send traffic to a Pod in the `backend` Namespace. Network isolation requires NetworkPolicies (covered in the next lesson).

## Key Takeaways

- A Pod is a group of containers sharing a network namespace (same IP) and optionally storage volumes. It is the smallest schedulable unit -- not a container.
- Containers in a Pod communicate over `localhost`; containers in different Pods communicate by IP.
- The sidecar pattern uses a second container to handle cross-cutting concerns (logging, proxying, secret injection) without modifying the main container.
- Bare Pods are not rescheduled after failure. Always use a controller (Deployment, StatefulSet, Job, DaemonSet).
- Namespaces partition resources logically but do not provide network isolation by default.
