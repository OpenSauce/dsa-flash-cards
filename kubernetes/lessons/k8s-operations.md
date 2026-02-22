---
title: "Operations"
summary: "Liveness, readiness, and startup probes, Jobs and CronJobs for batch workloads, taints and tolerations, node failure timeline, and Pod Disruption Budgets."
reading_time_minutes: 5
order: 7
---

## Why This Matters

Getting Kubernetes to run an application is the easy part. Running it reliably in production requires understanding how Kubernetes detects and responds to failures, how to schedule batch workloads safely, how to control Pod placement for mixed workloads, and how Kubernetes handles infrastructure failures. These operational concepts separate a working deployment from a production-grade one.

## Health Probes

Kubernetes uses three types of probes to monitor container health:

**Liveness probe** answers "Is this container alive?" If the liveness probe fails (after the configured failure threshold), Kubernetes **kills and restarts** the container. Use it to detect stuck processes: deadlocks, infinite loops, or processes that are technically running but doing nothing useful.

**Readiness probe** answers "Is this container ready to serve traffic?" If the readiness probe fails, Kubernetes **removes the Pod from Service endpoints** -- it stops routing requests to it, but does not restart it. Use it for slow-starting applications, applications that need time to warm caches, or applications that become temporarily unavailable under load.

**Startup probe** answers "Has this container finished its startup sequence?" Until the startup probe succeeds, liveness and readiness probes are disabled. Use it for applications with variable or long startup times. Without a startup probe, a slow-starting container may be killed by the liveness probe before it finishes initializing.

### Probe Types

| Type | How it works | Success condition |
|---|---|---|
| **HTTP GET** | Sends an HTTP request to a specified path and port | Status code 200-399 |
| **TCP socket** | Attempts a TCP connection to a specified port | Connection succeeds |
| **Exec** | Runs a command inside the container | Exit code 0 |

### Common Probe Mistakes

Avoid pointing liveness probes at external dependencies. If your liveness probe checks a database connection and the database goes temporarily unavailable, Kubernetes restarts all your application Pods -- amplifying the outage. Liveness probes should check only internal container health (memory state, goroutine leaks, internal deadlocks).

## Jobs and CronJobs

**Jobs** and **CronJobs** manage Pods that run to completion -- the opposite of Deployments, which run indefinitely.

**Job** runs one or more Pods **once** and tracks successful completions. When a Pod finishes with exit code 0, the Job records a completion. If the Pod fails, the Job retries it up to `backoffLimit` times (default 6). The Job is considered complete when the required number of successful completions is reached.

Key Job settings:
- `completions` -- number of successful Pod completions required (default 1)
- `parallelism` -- number of Pods running simultaneously
- `backoffLimit` -- max retries before marking the Job as failed
- `activeDeadlineSeconds` -- hard timeout for the entire Job

**CronJob** creates Jobs on a recurring schedule using standard cron syntax. It is a Job factory. At each scheduled time, it creates a new Job object, which creates Pods that run to completion.

```yaml
spec:
  schedule: "0 2 * * *"   # Run at 2am daily
  concurrencyPolicy: Forbid
```

The `concurrencyPolicy` controls what happens if a previous run has not finished when the next one is scheduled:
- `Allow` -- start the new run even if the previous is still running (parallel runs)
- `Forbid` -- skip the new run if the previous is still running
- `Replace` -- kill the current run and start a new one

## Taints and Tolerations

Taints and tolerations control which Pods can be scheduled on which nodes.

A **taint** on a node repels Pods. It has a key, an optional value, and an effect:
- **NoSchedule** -- new Pods without a matching toleration will not be scheduled on this node
- **PreferNoSchedule** -- the scheduler tries to avoid the node, but will use it if no untainted nodes are available
- **NoExecute** -- new Pods without a toleration are not scheduled, and existing Pods without a toleration are **evicted**

A **toleration** on a Pod allows it to be scheduled on (or remain on) a tainted node.

```yaml
# On a GPU node
taints:
  - key: "nvidia.com/gpu"
    effect: "NoSchedule"

# On a Pod that needs a GPU
tolerations:
  - key: "nvidia.com/gpu"
    operator: "Exists"
    effect: "NoSchedule"
```

Common uses:
- **Dedicated GPU nodes:** Taint GPU nodes with `NoSchedule` so only ML workloads land there.
- **Control plane isolation:** Control plane nodes are tainted by default, preventing application Pods from being scheduled on them.
- **Node draining:** `kubectl drain` applies a `NoExecute` taint that evicts all tolerating Pods for maintenance.

## Node Failure Timeline

When a node goes down, Kubernetes does not react immediately -- it waits to confirm the failure is real, not a transient network blip.

1. **Kubelet heartbeat stops.** The kubelet sends heartbeats every 10 seconds. When they stop, the node controller notices.
2. **Node marked NotReady.** After `node-monitor-grace-period` (default 40 seconds) without a heartbeat, the node's condition changes to `NotReady`.
3. **Pod eviction begins.** After `pod-eviction-timeout` (default 5 minutes), the node controller marks Pods on the NotReady node for eviction.
4. **Pods rescheduled.** Pods managed by a Deployment or StatefulSet are recreated on healthy nodes. Bare Pods are not rescheduled.

**Total default time to reschedule: ~5-6 minutes.** The delay is intentional -- it prevents mass Pod eviction during transient network partitions.

## Pod Disruption Budgets (PDB)

A **Pod Disruption Budget** limits how many Pods of a workload can be voluntarily disrupted simultaneously. It protects against availability loss during planned operations: node draining, cluster upgrades, rolling Deployment updates.

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: api
```

This PDB guarantees at least 2 Pods with `app=api` remain available during any voluntary disruption. If a node drain would violate this budget, `kubectl drain` blocks until the constraint can be satisfied.

PDBs only apply to **voluntary** disruptions (drains, evictions by the admin). They do not protect against node failures or OOMKills.

## Key Takeaways

- Liveness probe failure causes the container to be restarted. Readiness probe failure removes the Pod from Service endpoints (no restart). Startup probe disables the others until initialization completes.
- Never point liveness probes at external dependencies -- a dependency outage should not cause mass restarts of your application.
- Jobs run Pods to completion once. CronJobs run Jobs on a recurring schedule. Use `concurrencyPolicy` to control overlapping runs.
- Taints repel Pods (node-side). Tolerations allow Pods onto tainted nodes (Pod-side). `NoExecute` evicts existing Pods.
- The default node failure timeline is ~5-6 minutes before rescheduling begins. Reduce with shorter eviction timeouts or mitigate with anti-affinity rules to spread replicas across nodes.
- PDBs guarantee a minimum number of Pods remain available during voluntary disruptions like node drains.
