---
title: "Services and Networking"
summary: "The flat Pod network model, CNI plugins, Service types (ClusterIP, NodePort, LoadBalancer), Ingress for L7 routing, and NetworkPolicies."
reading_time_minutes: 5
order: 3
---

## Why This Matters

Kubernetes networking is one of the most common sources of confusion for engineers new to the platform. Understanding how Pods communicate, why Services exist, and how to expose workloads to external traffic is essential for designing any production application on Kubernetes. Networking is also a frequent interview topic because it requires understanding multiple layers of abstraction at once.

## The Flat Network Model

Kubernetes imposes three fundamental rules that every cluster network implementation must satisfy:

1. **Every Pod gets its own IP address** -- no two Pods share an IP on the same cluster.
2. **All Pods can communicate with all other Pods directly, without NAT**, regardless of which node they are on.
3. **Agents on a node (kubelet, kube-proxy) can communicate with all Pods on that node.**

This creates a **flat network**: from any Pod's perspective, every other Pod is reachable by its IP address. There is no port mapping, no NAT translation, no manual routing configuration.

Kubernetes does not implement networking itself. It delegates to **CNI (Container Network Interface) plugins**. The CNI plugin is responsible for assigning IP addresses to Pods and ensuring the three rules above are satisfied. Common plugins:

- **Calico** -- uses BGP routing or iptables for network policy enforcement
- **Cilium** -- uses eBPF for high-performance networking and policy enforcement
- **Flannel** -- simple overlay network, does not support NetworkPolicies
- **AWS VPC CNI** -- assigns native VPC IP addresses to Pods (used in EKS)

The choice of CNI plugin determines what features (like NetworkPolicies) are available.

## Why Services Exist

Pods are ephemeral. When a Pod restarts, it gets a new IP address. If you hard-code Pod IPs in your application, you will have broken connections after every restart, deployment, or node failure.

A **Service** provides a stable network endpoint for a set of Pods. It has:
- A **stable DNS name** (e.g., `my-service.my-namespace.svc.cluster.local`)
- A **stable virtual IP** (ClusterIP) that never changes, even as backend Pods come and go

The Service uses **label selectors** to find its backend Pods and load-balances traffic across them. When Pods are added or removed (by a Deployment rolling update, autoscaling, or failure), the Service's endpoint list updates automatically via the Endpoints object.

## Service Types

**ClusterIP** (default) creates a virtual IP accessible only within the cluster. Use it for service-to-service communication: the backend Service that only the frontend needs to reach, the database that only the backend talks to. DNS resolution within the cluster maps the Service name to the ClusterIP.

**NodePort** exposes the Service on a static port on every node's IP address. Traffic reaching `<any-node-IP>:<NodePort>` is forwarded to the Service. Accessible from outside the cluster without a cloud load balancer. Useful for local development or on-premises clusters without cloud integration. Not ideal for production -- it requires external clients to know node IPs, and provides no automatic failover if a node goes down.

**LoadBalancer** provisions an external cloud load balancer that routes traffic to the Service. In AWS this creates an ELB or NLB; in GCP it creates a Cloud Load Balancer. The load balancer gets a stable external IP that clients use. This is the standard way to expose a single HTTP or TCP service to the internet in a cloud environment.

## Ingress: L7 Routing

A Service provides L4 load balancing -- it routes TCP/UDP traffic based on IP and port. An **Ingress** provides L7 routing -- it routes HTTP/HTTPS traffic based on hostnames, URL paths, and headers.

What Ingress enables:
- **Host-based routing:** `api.example.com` routes to the API Service; `app.example.com` routes to the frontend Service
- **Path-based routing:** `/api/*` routes to the backend; all other paths route to the frontend
- **TLS termination:** The Ingress handles HTTPS certificates so backend Services can communicate over plain HTTP internally
- **Single entry point:** One external load balancer serves all HTTP services, instead of one LoadBalancer Service per application

An Ingress resource is just a routing configuration object. It requires an **Ingress controller** -- separate software that reads Ingress resources and programs a reverse proxy or load balancer to implement the rules. Popular controllers:
- **NGINX Ingress Controller** -- runs NGINX inside the cluster
- **Traefik** -- cloud-native reverse proxy with automatic certificate management
- **AWS ALB Ingress Controller** -- provisions AWS Application Load Balancers per Ingress

Without an Ingress controller installed, Ingress resources have no effect.

## NetworkPolicies: Pod-to-Pod Firewalling

By default, Kubernetes allows all Pods to communicate with all other Pods. **NetworkPolicies** restrict this open default.

A NetworkPolicy selects Pods using label selectors and defines what traffic is allowed:
- **ingress rules** -- which sources can send traffic to the selected Pods, on which ports
- **egress rules** -- which destinations the selected Pods can send traffic to

Once a NetworkPolicy selects a Pod, **all traffic not explicitly allowed by any policy is denied**. Pods with no NetworkPolicy applied remain fully open.

```yaml
# Allow only the backend Pod to reach the database on port 5432
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: backend
      ports:
        - port: 5432
```

A common pattern is to apply a default-deny policy to a Namespace and then add explicit allow policies for each legitimate communication path. This implements least-privilege networking.

NetworkPolicies are enforced by the CNI plugin. Flannel does not support them. Calico and Cilium do. Choosing the wrong CNI plugin means your NetworkPolicies are silently ignored.

## Key Takeaways

- Every Pod gets a unique IP. Pods communicate directly without NAT (the flat network model). CNI plugins implement this.
- Services provide a stable DNS name and virtual IP for a set of Pods, decoupling consumers from ephemeral Pod IPs.
- ClusterIP for internal traffic, NodePort for external traffic without a cloud load balancer, LoadBalancer for production external exposure.
- Ingress adds L7 routing (host/path-based, TLS termination) in front of multiple Services, reducing the number of external load balancers needed.
- By default all Pods can talk to all other Pods. NetworkPolicies restrict this -- but only if the CNI plugin supports enforcement.
