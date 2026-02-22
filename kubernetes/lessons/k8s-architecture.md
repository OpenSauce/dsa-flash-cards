---
title: "Kubernetes Architecture"
summary: "The control plane components, worker node components, and the declarative reconciliation model that makes Kubernetes work."
reading_time_minutes: 5
order: 1
---

## Why This Matters

Kubernetes is the dominant platform for running containerized applications at scale. Every backend engineering role touching production infrastructure requires at least a working mental model of how Kubernetes orchestrates workloads. The architecture is not just trivia -- understanding the reconciliation model fundamentally changes how you think about deploying and operating software.

## The Declarative Model

Kubernetes is built on a single idea: **you declare what you want, and Kubernetes figures out how to make it happen.**

You write a YAML manifest that says "I want 3 replicas of this container running." Kubernetes stores that declaration and continuously compares it to the actual state of the cluster. If there are only 2 replicas running (one crashed), Kubernetes starts a third. If a new replica was incorrectly created and now there are 4, Kubernetes terminates one. This comparison-and-correction cycle is called the **reconciliation loop**.

This declarative approach is the opposite of imperative scripting ("start this container on that server"). The cluster converges toward the desired state automatically, even after failures.

## The Control Plane

The control plane is the brain of the cluster. It makes all scheduling and management decisions. In production, control plane components run on dedicated nodes (typically 3 for high availability), separate from the nodes that run application workloads.

**API server (kube-apiserver)** is the front door to the cluster. Every interaction with Kubernetes -- `kubectl` commands, kubelet heartbeats, controller reconciliation -- flows through the API server. It validates requests, handles authentication and authorization, and persists state. Critically, it is the **only** component that communicates with etcd directly.

**etcd** is a distributed key-value store that holds all cluster state: every Pod, Service, ConfigMap, Secret, and node definition. It uses the Raft consensus algorithm to ensure consistency across replicas. If etcd is lost without a backup, the cluster state is gone. Etcd backups are non-negotiable in production.

**Scheduler (kube-scheduler)** watches for newly created Pods that have no assigned node and selects the best node for each one. The decision considers resource requests (does the node have enough CPU and memory?), affinity and anti-affinity rules, taints, and topology constraints.

**Controller manager (kube-controller-manager)** runs the reconciliation loops. It hosts dozens of controllers -- the ReplicaSet controller, Deployment controller, Node controller, Job controller -- each running a tight loop: observe actual state, compare to desired state, take corrective action. The controller manager is why Kubernetes "heals" itself.

**Cloud controller manager** handles cloud-specific operations: provisioning load balancers for LoadBalancer Services, managing cloud routes, attaching cloud storage. It is only present in cloud-hosted clusters (EKS, GKE, AKS) and abstracts away cloud-provider specifics.

## Worker Nodes

Worker nodes are where application Pods actually run. Each node runs three essential components.

**Kubelet** is the node agent. It registers the node with the API server, watches for Pod assignments to this node, and ensures the assigned containers are running and healthy. The kubelet pulls container images, starts and stops containers via the container runtime, executes liveness/readiness probes, mounts volumes, and injects ConfigMaps and Secrets. It also sends heartbeats to the API server every 10 seconds -- when heartbeats stop, the node is eventually marked NotReady.

**Kube-proxy** manages networking rules on each node. It maintains iptables or IPVS rules that route traffic from Service virtual IPs to the actual Pod IPs behind them. When a Pod sends traffic to a Service's ClusterIP, kube-proxy's rules transparently redirect it to a healthy backend Pod.

**Container runtime** is the software that actually runs containers. Kubernetes communicates with it via the Container Runtime Interface (CRI). The default in most distributions is **containerd** -- lightweight and purpose-built for Kubernetes. CRI-O is common in OpenShift. Docker was removed as a direct Kubernetes runtime in v1.24 (though Docker-built images still run fine, since they follow the same OCI image format).

## The Reconciliation Loop in Practice

```
You: kubectl apply -f deployment.yaml
  → API server validates and stores the desired state in etcd

Deployment controller (in controller manager):
  → Observes: desired=3 replicas, actual=0
  → Creates a ReplicaSet

ReplicaSet controller:
  → Observes: desired=3 Pods, actual=0
  → Creates 3 Pod objects in etcd (status: Pending)

Scheduler:
  → Observes: 3 Pending Pods with no node assigned
  → Assigns each Pod to a node, writes node name to etcd

Kubelet (on each assigned node):
  → Observes: Pod assigned to this node
  → Pulls image, starts container, updates Pod status to Running
```

Each step is a controller observing and acting. No single component coordinates them -- the reconciliation loops coordinate themselves through the shared state in etcd.

## Key Takeaways

- Kubernetes uses a declarative model: you declare desired state, controllers continuously reconcile actual state to match.
- The API server is the only component that talks to etcd; all other components go through it.
- The controller manager runs reconciliation loops. Each loop independently drives actual state toward desired state.
- The kubelet on each worker node is the component that actually starts containers -- the control plane only decides what should run where.
- Etcd is the source of truth for all cluster state; lose it without a backup and the cluster state is gone.
