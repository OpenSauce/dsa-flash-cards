---
title: "Storage and S3"
order: 5
summary: "S3 as object storage, buckets and keys, storage classes (Standard through Deep Archive), lifecycle policies, strong consistency model, versioning. EBS and EFS for block and file storage."
---

## Why This Matters

S3 is one of the most widely used AWS services -- and one of the most misunderstood. It is not a filesystem or a database. Understanding what S3 actually is (an object store with a flat namespace), how its storage classes trade cost for retrieval speed, and where EBS and EFS fit in the storage landscape helps you make the right storage choice for any AWS workload.

## What Is Amazon S3?

S3 (Simple Storage Service) is an **object store**: a flat namespace where you store binary objects (files, images, backups, logs, datasets) identified by a key. There is no directory structure -- keys like `images/2025/photo.jpg` look like paths but are just strings. S3 doesn't have folders; it has prefixes.

Each object is stored in a **bucket**, which has a globally unique name. An object is retrieved by `bucket + key`. Objects can range from 0 bytes to 5 TB.

S3 is designed for durability (11 nines = 99.999999999% annual object durability) and availability. It replicates data across multiple Availability Zones within a region automatically.

**When to use S3**: Static website assets, user-uploaded files, data lake storage, backup and archive, ML training datasets, log storage. Anywhere you need durable, cheap, scalable storage for files that are read and written as whole objects.

**When not to use S3**: For database-style access patterns (random reads/writes within a file), use EBS. For shared filesystems across multiple servers, use EFS.

## S3 Storage Classes

All objects default to S3 Standard, but you can reduce storage costs by choosing a class matched to your access frequency:

| Storage Class | Access Pattern | Retrieval | Retrieval Fee |
|---|---|---|---|
| S3 Standard | Frequently accessed | Milliseconds | None |
| S3 Standard-IA | Infrequently accessed | Milliseconds | Per GB |
| S3 One Zone-IA | Infrequent, can tolerate one-AZ loss | Milliseconds | Per GB |
| S3 Glacier Instant Retrieval | Rare, but must restore immediately | Milliseconds | Per GB |
| S3 Glacier Flexible Retrieval | Archive, restore in minutes to hours | Minutes–hours | Per GB |
| S3 Glacier Deep Archive | Long-term archive | 12–48 hours | Per GB |

The trade-off is consistent across all tiers: lower storage cost in exchange for a per-retrieval fee. If you retrieve data infrequently, IA and Glacier classes save money. If you retrieve data constantly, the retrieval fees can make Standard IA more expensive than Standard.

S3 Intelligent-Tiering is an automated option: AWS monitors access patterns and moves objects between Standard and IA automatically. Adds a small monitoring fee per object, but eliminates the need to manually classify access patterns.

## Lifecycle Policies

A **lifecycle policy** automates transitions between storage classes and object expiration. Without lifecycle policies, objects stay in their original class forever, accruing storage costs.

Example lifecycle rule:
- Move to S3 Standard-IA after 30 days
- Move to S3 Glacier Flexible Retrieval after 90 days
- Expire (delete) after 365 days

Lifecycle policies can apply to all objects in a bucket or just those matching a prefix. This is the standard cost optimization pattern for log storage: new logs in Standard for hot analysis, older logs in Glacier for compliance retention.

## Consistency Model

S3 provides **strong read-after-write consistency** for all operations -- PUTs, DELETEs, and list operations. After a successful write, any subsequent read returns the latest version. There is no window where you might read stale data.

This has been the case since December 2020. Before that, S3 had eventual consistency for overwrites and deletes -- a significant gotcha that affected many architectures. Knowing that S3 is now strongly consistent (and knowing it wasn't always) is the mark of someone who has worked with S3 seriously.

## Versioning

When **versioning** is enabled on a bucket, S3 retains every version of every object. Overwriting an object creates a new version; deleting adds a delete marker but preserves previous versions.

Versioning protects against:
- Accidental overwrites: restore any previous version
- Accidental deletes: remove the delete marker to restore the object
- Application bugs that corrupt data: roll back to a known-good version

Trade-off: versioning increases storage costs because every version is stored. Use lifecycle policies to expire old versions.

## EBS: Block Storage for EC2

**EBS (Elastic Block Store)** provides persistent block storage volumes attached to EC2 instances. Think of it as a hard drive you attach to a VM.

Key properties:
- Attached to a single EC2 instance at a time (io2 Block Express supports multi-attach, but that's a special case)
- Data persists after the instance stops or terminates (if configured)
- Backed up via snapshots stored in S3
- Supports volume types: gp3 (general purpose SSD), io2 (high IOPS SSD), st1 (throughput-optimized HDD), sc1 (cold HDD)

**When to use EBS**: Database storage, application state that requires block-level access, boot volumes.

## EFS: Shared File Storage

**EFS (Elastic File System)** is a managed NFS filesystem that can be mounted by multiple EC2 instances simultaneously. It scales storage automatically and charges per GB stored.

**When to use EFS**: Shared content directories accessed by multiple application servers (e.g., user-uploaded files in a PHP app), CI/CD build caches shared across multiple build agents, machine learning training data accessible to a fleet of training instances.

## Key Takeaways

- S3 is object storage with a flat key namespace. Designed for whole-object reads/writes, not random byte access.
- Storage classes trade storage cost for retrieval speed and fees. Standard (no retrieval fee) → IA → Glacier Instant → Glacier Flexible → Deep Archive (cheapest, 12–48 hour retrieval).
- Lifecycle policies automate transitions between storage classes and object expiration.
- S3 has strong read-after-write consistency for all operations since December 2020.
- Versioning retains every version of every object, protecting against accidental deletes and overwrites.
- EBS is block storage for a single EC2 instance. EFS is shared NFS storage for multiple instances.
