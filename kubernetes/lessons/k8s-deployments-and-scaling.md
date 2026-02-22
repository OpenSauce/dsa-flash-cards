---
title: "Deployments and Scaling"
summary: "ReplicaSets, Deployments with rolling updates and rollbacks, StatefulSets for stateful workloads, DaemonSets, and Horizontal Pod Autoscaler."
reading_time_minutes: 5
order: 4
---

## Why This Matters

Understanding workload controllers is the difference between knowing that Kubernetes exists and knowing how to run real applications on it. Deployments are the daily workhorse for stateless applications. StatefulSets solve a class of problems (stable identity, per-Pod storage) that Deployments explicitly cannot. HPA is how production systems handle variable traffic automatically. Getting the controller choice wrong creates operational problems that are painful to fix later.

## ReplicaSets

A **ReplicaSet** ensures that a specified number of identical Pod replicas are running at all times. It uses a label selector to identify which Pods it owns and continuously reconciles the actual count against the desired count.

If a Pod crashes, the ReplicaSet controller creates a replacement. If you scale up, it creates additional Pods. If you scale down, it deletes excess Pods.

You almost never create ReplicaSets directly. Deployments create and manage ReplicaSets for you.

## Deployments

A **Deployment** manages ReplicaSets and adds update orchestration on top: rolling updates, rollbacks, and revision history.

When you update a Deployment's Pod template (change the container image, update environment variables, etc.), the Deployment performs a **rolling update**:

1. Creates a **new ReplicaSet** with the updated Pod template
2. Scales up the new ReplicaSet incrementally
3. Scales down the old ReplicaSet at the same rate
4. Continues until the new ReplicaSet is at full desired count and the old is at zero

Two parameters control the update pace:

- **`maxSurge`** -- how many extra Pods can exist above the desired count during the update. Default: 25%. With 4 replicas and 25% surge, up to 5 Pods may be running at once.
- **`maxUnavailable`** -- how many Pods can be below the desired count during the update. Default: 25%. With 4 replicas and 25% unavailable, at least 3 Pods must be running at all times.

Setting `maxUnavailable: 0` forces zero-downtime updates (no Pod is removed before a replacement is ready), at the cost of requiring extra capacity.

**Rollback** is fast. Every Deployment update creates a new ReplicaSet revision. The old ReplicaSet is kept with zero replicas, not deleted. Rolling back (`kubectl rollout undo`) simply scales up the previous ReplicaSet and scales down the current one. No rebuild, no new image push.

## StatefulSets

A **StatefulSet** manages Pods that need stable identities and persistent storage. It is the right choice when Pods are not interchangeable.

What a StatefulSet provides that a Deployment does not:

**Stable network identity.** Each Pod gets a predictable, stable hostname: `pod-0`, `pod-1`, `pod-2`. When `pod-1` is rescheduled to a different node, it keeps the name `pod-1`. A Deployment assigns random suffixes to Pod names.

**Ordered deployment and scaling.** Pods are created in order (0, then 1, then 2) and terminated in reverse (2, then 1, then 0). This matters for databases that require a leader to be healthy before replicas start.

**Persistent storage per Pod.** Each Pod gets its own PersistentVolumeClaim. When `pod-1` is rescheduled, it reattaches to the same PVC with the same data on it. Deployment Pods do not own individual PVCs.

Use a StatefulSet for:
- Databases (PostgreSQL replicas, MySQL cluster members)
- Distributed systems requiring peer identity (Kafka brokers, Zookeeper nodes, etcd members)
- Any workload where Pod identity must survive restarts

Use a Deployment for everything stateless. Most workloads are stateless.

## DaemonSets

A **DaemonSet** ensures exactly one Pod runs on every node in the cluster (or a subset filtered by node selectors). When a new node joins the cluster, the DaemonSet automatically schedules a Pod on it. When a node is removed, the Pod is garbage collected.

Common DaemonSet use cases:
- **Log collection:** Fluentd or Filebeat on every node, collecting container logs and shipping to centralized storage
- **Monitoring agents:** Prometheus node-exporter or Datadog agent on every node, collecting host-level metrics
- **Network plugins:** CNI plugins and kube-proxy run as DaemonSets to configure node networking
- **Storage drivers:** CSI node plugins that mount volumes on each node

A DaemonSet has no `replicas` field -- the number of Pods is always equal to the number of matching nodes.

## Horizontal Pod Autoscaler (HPA)

The **HPA** automatically scales a Deployment or StatefulSet's replica count based on observed metrics.

The scaling formula:
```
desired replicas = ceil(current replicas × (current metric / target metric))
```

Example: 3 replicas, current CPU at 80%, target CPU at 50%. Desired = ceil(3 × (80/50)) = ceil(4.8) = 5 replicas.

Metrics the HPA can use:
- **CPU utilization** -- the most common. Target a percentage of the resource request (e.g., 60%).
- **Memory utilization** -- useful but tricky; many applications do not release memory after load drops.
- **Custom metrics** -- application-specific metrics via the Kubernetes Metrics API. Request rate, queue depth, active connections.
- **External metrics** -- metrics from outside the cluster: SQS queue length, Pub/Sub backlog.

The HPA controller polls metrics every 15 seconds and includes a **stabilization window** (5 minutes for scale-down by default) to prevent flapping during bursty traffic.

The HPA requires the **Metrics Server** to be installed in the cluster. Without it, the HPA has no data source.

## Key Takeaways

- A ReplicaSet maintains N replicas. A Deployment manages ReplicaSets and adds rolling updates and rollbacks.
- Rolling updates create a new ReplicaSet and gradually shift traffic. `maxSurge` and `maxUnavailable` control the pace.
- Rollback is instant -- the old ReplicaSet is kept at zero replicas and scaled back up on `kubectl rollout undo`.
- StatefulSets provide stable Pod names, ordered deployment, and per-Pod PVCs. Use them for stateful workloads; use Deployments for everything stateless.
- DaemonSets run exactly one Pod per node. Use them for per-node agents (logging, monitoring, networking).
- HPA scales Deployment/StatefulSet replica counts automatically based on metrics. Requires Metrics Server.
