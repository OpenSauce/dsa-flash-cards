---
title: "Storage"
summary: "Ephemeral vs persistent storage, PersistentVolumes, PersistentVolumeClaims, StorageClasses and dynamic provisioning, access modes, and reclaim policies."
reading_time_minutes: 4
order: 6
---

## Why This Matters

Containers are ephemeral by design -- when a container restarts, its local filesystem is gone. This is fine for stateless applications, but databases, file stores, and any workload that needs to survive a restart require persistent storage. Kubernetes' storage model (PV + PVC + StorageClass) is more complex than simply mounting a disk, but the abstraction serves an important purpose: it decouples the infrastructure team (who provisions storage) from the development team (who requests and uses storage).

## Ephemeral Storage

By default, everything a container writes to its filesystem is lost when the container is replaced. An `emptyDir` volume extends this with shared ephemeral storage across containers in the same Pod:

```yaml
volumes:
  - name: scratch
    emptyDir: {}
```

An `emptyDir` is created when the Pod is scheduled and deleted when the Pod is removed from the node. It is useful for sharing temporary data between sidecar containers, but it does not survive Pod termination.

## PersistentVolumes (PV)

A **PersistentVolume** is a piece of storage provisioned in the cluster -- an AWS EBS volume, a GCP Persistent Disk, an NFS share, or any CSI-backed storage system. It represents an actual storage resource with specific properties:

- **Capacity** -- how much storage (e.g., 100Gi)
- **Access mode** -- how many nodes can mount it and in what mode (see below)
- **Reclaim policy** -- what happens to the PV when its claim is released
- **StorageClass** -- which class of storage this PV belongs to

A PV has a lifecycle independent of any Pod. It is a cluster-level resource, not Namespace-scoped.

## PersistentVolumeClaims (PVC)

A **PersistentVolumeClaim** is a request for storage made by a Pod. It specifies what the Pod needs:

- How much capacity
- What access mode
- Optionally, which StorageClass

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-storage
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: gp3
```

Kubernetes matches the PVC to an available PV that satisfies the request. Once bound, the PVC and PV are paired -- no other PVC can use that PV. A Pod references the PVC to mount the storage:

```yaml
volumes:
  - name: db-data
    persistentVolumeClaim:
      claimName: database-storage
```

## Dynamic Provisioning with StorageClasses

Static PV management -- an admin manually creates PVs in advance, and users create PVCs that match them -- does not scale. **StorageClasses** enable dynamic provisioning: when a PVC is created, Kubernetes automatically provisions a new PV from the cloud provider and binds it.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
```

When a PVC requests StorageClass `gp3`, the EBS CSI driver automatically creates a new EBS volume, registers it as a PV, and binds it to the PVC. No manual admin work. In cloud environments, dynamic provisioning via StorageClasses is the standard approach -- you almost never create PVs manually in production.

## Access Modes

Access modes define how many nodes can mount a PV simultaneously and with what permissions:

| Mode | Abbreviation | Meaning |
|---|---|---|
| **ReadWriteOnce** | RWO | One node can mount read-write. This is the most common -- used for block storage (EBS, Persistent Disk). |
| **ReadOnlyMany** | ROX | Many nodes can mount read-only simultaneously. Useful for shared config files. |
| **ReadWriteMany** | RWX | Many nodes can mount read-write simultaneously. Requires network filesystem (NFS, CephFS, AWS EFS). Block storage like EBS does not support RWX. |

The access mode is a claim, not a guarantee of filesystem semantics -- applications are still responsible for handling concurrent writes safely.

## Reclaim Policies

When a PVC is deleted, the reclaim policy determines what happens to the PV:

- **Retain** -- the PV is not deleted. It moves to a `Released` state and its data is preserved, but it cannot be claimed by another PVC until an admin manually recycles it. Use Retain for databases where losing data is catastrophic.
- **Delete** -- the PV and the underlying storage (the EBS volume, the GCP Persistent Disk) are deleted automatically when the PVC is deleted. Convenient but permanent data loss if the PVC is deleted accidentally.

StorageClasses typically default to `Delete`. Override to `Retain` for production databases.

## StatefulSets and Storage

StatefulSets interact with storage differently from Deployments. A StatefulSet's `volumeClaimTemplates` field defines a PVC template that is instantiated separately for each Pod:

```yaml
volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

This creates `data-pod-0`, `data-pod-1`, `data-pod-2` as separate PVCs bound to separate PVs. When `pod-1` is rescheduled, it reattaches to `data-pod-1` -- its own storage, with its own data. This persistent identity is what makes StatefulSets suitable for databases.

## Key Takeaways

- PVs are cluster-level storage resources. PVCs are namespace-level storage requests. Kubernetes binds a PVC to a matching PV.
- StorageClasses enable dynamic provisioning -- PVs are created automatically when PVCs request a StorageClass. This is the standard in cloud environments.
- ReadWriteOnce (one node, R/W) is the most common access mode and works with block storage. ReadWriteMany (multiple nodes, R/W) requires a network filesystem.
- Retain reclaim policy preserves data when a PVC is deleted; Delete removes the PV and underlying storage automatically.
- StatefulSets use volumeClaimTemplates to create per-Pod PVCs, giving each Pod its own stable, persistent storage.
