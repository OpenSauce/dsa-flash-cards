---
title: "Configuration and Secrets"
summary: "ConfigMaps for non-sensitive config, Secrets and their security limitations, consumption methods, and resource requests vs limits."
reading_time_minutes: 4
order: 5
---

## Why This Matters

Hardcoding configuration into container images is an antipattern -- it makes images environment-specific and forces rebuilds for configuration changes. Kubernetes provides ConfigMaps and Secrets to inject configuration at runtime, separating code from config. Understanding resource requests and limits is equally essential: misconfigured resource settings cause mysterious OOMKills and poor cluster utilization, two of the most common production problems in Kubernetes.

## ConfigMaps

A **ConfigMap** stores non-sensitive configuration as key-value pairs. Use it for anything a twelve-factor app would put in an environment variable: database hostnames, feature flags, log levels, config file contents.

ConfigMaps are stored as plaintext in etcd. They are not suitable for sensitive data.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DATABASE_HOST: "postgres.default.svc.cluster.local"
  LOG_LEVEL: "info"
  config.yaml: |
    max_connections: 100
    timeout: 30s
```

## Secrets

A **Secret** stores sensitive data: passwords, API keys, TLS certificates, SSH keys. The intended purpose is to keep sensitive values out of container images and Pod manifests.

Secrets are stored as **base64-encoded** values in etcd. This is not encryption.

Base64 is reversible encoding -- it protects against accidental display in logs and makes binary data safe for YAML. Anyone with RBAC access to the Secret, or direct access to etcd, can decode it instantly with `base64 -d`. Treating base64 as security theater is a common and dangerous misconception.

For production security:
- **Enable encryption at rest** in etcd (not on by default in most clusters)
- **Use an external secret manager** -- HashiCorp Vault, AWS Secrets Manager, or the Kubernetes External Secrets Operator pulls secrets from an external system and injects them as Kubernetes Secrets at runtime
- **Restrict RBAC** so only the workload that needs a Secret can read it

## Consuming ConfigMaps and Secrets

Both ConfigMaps and Secrets can be consumed by Pods in two ways:

**Environment variables** inject individual keys as environment variables in the container:

```yaml
env:
  - name: DATABASE_HOST
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: DATABASE_HOST
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: password
```

**Volume mounts** mount the entire ConfigMap or Secret as files in a directory. Each key becomes a file, and the file contents are the value:

```yaml
volumeMounts:
  - name: config-volume
    mountPath: /etc/config
volumes:
  - name: config-volume
    configMap:
      name: app-config
```

The application then reads `/etc/config/DATABASE_HOST` as a regular file. Volume mounts have an advantage: when a ConfigMap is updated, the files in the mounted volume are eventually updated automatically (with a short propagation delay). Environment variables are set at container start and do not update without a restart.

## Resource Requests and Limits

Every container should declare resource requests and limits. Without them, the scheduler cannot make informed placement decisions, and workloads compete unpredictably for node resources.

```yaml
resources:
  requests:
    cpu: "250m"      # 0.25 CPU cores
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

**Requests** are the guaranteed minimum. The scheduler uses requests to decide which node has sufficient capacity for the Pod. A Pod requesting 256Mi of memory will only be placed on a node with at least 256Mi available. The container will always have at least this much available.

**Limits** are the hard ceiling. The container cannot exceed this amount:

- **Memory limit exceeded:** The kernel sends an OOMKill signal to the container. Kubernetes restarts it according to the Pod's `restartPolicy`. The process has no chance to clean up -- it is killed abruptly.
- **CPU limit exceeded:** The container is **throttled** -- it does not get killed, but the kernel restricts its CPU time slices. The process runs slower but continues.

The asymmetry matters: memory violations are fatal (OOMKill), CPU violations are graceful (throttling). This is because unused memory cannot easily be reclaimed from a process, but CPU time-slices can always be redistributed.

**Setting requests equal to limits** (Guaranteed QoS class) reserves capacity exclusively for the container. The node cannot overcommit that capacity. This is safe but wastes cluster resources -- other workloads cannot use the reserved-but-idle capacity. The trade-off: predictable performance vs resource efficiency.

## Key Takeaways

- ConfigMaps store non-sensitive config as key-value pairs in etcd (plaintext). Secrets store sensitive data in etcd as base64-encoded values -- base64 is not encryption.
- Both are consumed as environment variables (set at container start) or volume mounts (updated automatically when the ConfigMap changes).
- Enabling etcd encryption at rest and using external secret managers (Vault, AWS Secrets Manager) are required for production Secret security.
- Resource requests tell the scheduler what the Pod needs; limits are hard ceilings enforced at runtime.
- Exceeding memory limits causes OOMKill (fatal, process killed). Exceeding CPU limits causes throttling (graceful, process slows). The asymmetry is intentional.
