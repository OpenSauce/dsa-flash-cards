---
title: "Compute Fundamentals"
order: 1
summary: "EC2 instances, instance types and families, AMIs, auto scaling groups, and Elastic Load Balancing -- the building blocks for running workloads on AWS."
---

## Why This Matters

Every AWS application needs somewhere to run. EC2 is the foundational compute service: virtual machines you control, configure, and scale. Before diving into containers and serverless, you need the EC2 mental model -- because containers and Lambda are built on top of the same underlying concepts of instance types, AMIs, and auto scaling.

## EC2: Virtual Machines in the Cloud

An EC2 instance is a virtual machine running on AWS hardware. You choose the OS (via an AMI), the instance type (CPU, memory, storage, networking), and the network configuration (which VPC and subnet). AWS provisions the hardware; you manage everything from the OS upward.

EC2 gives you maximum flexibility: long-running processes, persistent local storage, full control over the software stack, and the ability to SSH in for debugging. That flexibility comes with operational burden -- you are responsible for OS patching, capacity planning, and high availability.

## Instance Types and Families

An instance type defines the hardware profile: how many vCPUs, how much memory, what network bandwidth, and what storage options. AWS groups instance types into families optimized for different workload characteristics:

| Family | Prefix | Optimized For | Example Use Cases |
|--------|--------|---------------|-------------------|
| General Purpose | t, m | Balanced CPU and memory | Web servers, small databases, dev environments |
| Compute Optimized | c | High CPU-to-memory ratio | Batch processing, scientific modeling, video encoding |
| Memory Optimized | r, x | High memory-to-CPU ratio | In-memory caches, real-time analytics, large databases |
| Storage Optimized | i, d | High disk I/O to local storage | Data warehousing, distributed file systems |
| GPU | p, g | Graphics or ML compute | Machine learning training, graphics rendering |

The `t` family is burstable: instances earn CPU credits when idle and spend them during spikes. This makes `t3` or `t4g` ideal for workloads with variable, spiky traffic. When credits run out, CPU is throttled.

The naming convention encodes generation and size: `m6i.2xlarge` = general purpose (`m`), sixth generation (`6`), Intel processor (`i`), double extra large.

## Amazon Machine Images (AMIs)

An AMI (Amazon Machine Image) is a snapshot of a root volume plus launch metadata. It defines:
- The operating system and its configuration
- Pre-installed software and dependencies
- The block device mapping (which EBS volumes to attach)

When you launch an EC2 instance, you pick an AMI as the starting point. AWS provides AMIs for Amazon Linux, Ubuntu, Windows Server, and others. You can also create custom AMIs from a running instance -- this is the standard way to bake your application and dependencies into a reusable image, avoiding bootstrapping scripts on every launch.

## Auto Scaling Groups

Running a fixed number of EC2 instances breaks at scale: not enough instances under load, too many during quiet periods. An **Auto Scaling Group (ASG)** solves this by automatically adjusting instance count.

An ASG has three components:

1. **Launch template** -- defines what to scale: which AMI, instance type, security groups, and user data script.
2. **Capacity settings** -- minimum, maximum, and desired instance count.
3. **Scaling policies** -- when and how to scale.

Three scaling policy types:
- **Target tracking**: Maintain a target metric. "Keep average CPU at 60%." ASG adds or removes instances automatically to hit the target.
- **Step scaling**: Add N instances when metric crosses threshold X, add M more when it crosses threshold Y.
- **Scheduled scaling**: Pre-scale before a known traffic spike (every Monday morning, before a marketing event).

**Cooldown period**: After a scaling action, the ASG waits (default 300 seconds) before acting again. This prevents thrashing -- repeated add/remove cycles driven by a metric that fluctuates around the threshold.

**Scale-in protection**: Individual instances can be marked protected from scale-in. Useful for instances processing long jobs you don't want interrupted.

## Elastic Load Balancing

Auto Scaling only helps if traffic is distributed across instances. An **Elastic Load Balancer (ELB)** sits in front of your ASG and routes incoming requests.

Three ELB types:
- **Application Load Balancer (ALB)**: HTTP/HTTPS at Layer 7. Supports path-based and host-based routing, WebSockets, and request-level metrics. The standard choice for web applications and APIs.
- **Network Load Balancer (NLB)**: TCP/UDP at Layer 4. Extremely high throughput, ultra-low latency. Use for gaming servers, financial trading systems, or anything where network performance matters more than routing features.
- **Gateway Load Balancer (GWLB)**: Routes traffic to third-party virtual appliances (firewalls, IDS/IPS). Usually managed by security teams.

An ALB integrates directly with an ASG: as new instances launch, they register with the ALB and start receiving traffic. As instances terminate, the ALB drains their connections (waits for in-flight requests to complete) before deregistering them.

## Key Takeaways

- An EC2 instance is a virtual machine. You control the OS and everything above it.
- Instance families match the bottleneck: CPU-bound → `c`, memory-bound → `r`, general → `m` or `t`.
- An AMI is a reusable snapshot for launching identical instances. Bake your dependencies in; don't bootstrap at launch time.
- An Auto Scaling Group adjusts instance count automatically using a launch template, capacity bounds, and scaling policies.
- An Application Load Balancer distributes HTTP traffic across ASG instances and handles connection draining during scale-in.
