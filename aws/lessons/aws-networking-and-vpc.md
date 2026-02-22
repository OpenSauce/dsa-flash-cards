---
title: "Networking and VPC"
order: 3
summary: "VPC as an isolated network, subnets (public and private), route tables, internet gateway, NAT gateway, security groups vs NACLs, and the standard 3-tier architecture pattern."
---

## Why This Matters

Every resource you launch on AWS lives inside a VPC. Understanding the VPC networking model is the foundation for secure, well-architected AWS applications. If you can't sketch a VPC with public and private subnets, explain how traffic flows, and articulate why databases live in private subnets, you won't pass an AWS architecture review or system design interview.

## What Is a VPC?

A **VPC (Virtual Private Cloud)** is an isolated virtual network in your AWS account. It defines an IP address range (CIDR block), and all resources you launch into it get IP addresses from that range.

By default, every AWS account has a default VPC. For production workloads, you create custom VPCs with deliberately planned network topology.

VPCs are regional: a VPC spans all Availability Zones in a region, but you connect resources to specific AZs via subnets.

## Subnets

A **subnet** is a subdivision of a VPC tied to a single Availability Zone. You divide your VPC's IP range across subnets and place resources in the subnet that matches their exposure requirements.

**Public subnet**: Has a route to an internet gateway. Resources can be assigned public IP addresses and receive traffic from the internet. Use for load balancers, bastion hosts, and NAT gateways.

**Private subnet**: No route to an internet gateway. Resources are only reachable from within the VPC or via VPN/Direct Connect. For outbound internet access (software updates, API calls to external services), traffic routes through a NAT gateway in a public subnet. Use for application servers and databases.

The public/private distinction comes entirely from the route table -- not from whether a resource has a public IP address.

## Route Tables

A **route table** is a set of rules that control where network traffic is sent. Each subnet is associated with a route table.

A typical route table for a public subnet:
```
Destination     Target
10.0.0.0/16     local           (traffic within the VPC)
0.0.0.0/0       igw-xxxxxxxx    (everything else → internet gateway)
```

A typical route table for a private subnet:
```
Destination     Target
10.0.0.0/16     local
0.0.0.0/0       nat-xxxxxxxx    (everything else → NAT gateway)
```

The absence of the `0.0.0.0/0 → igw` route is what makes a subnet private.

## Internet Gateway and NAT Gateway

**Internet Gateway (IGW)**: Connects the VPC to the public internet. Bidirectional: public subnet resources can send traffic out, and the internet can initiate connections to resources with public IPs.

**NAT Gateway**: Sits in a public subnet and provides outbound-only internet access for private subnet resources. Private instances can download packages or call external APIs; the internet cannot initiate connections to them. NAT gateways are managed by AWS (no maintenance required) and charged per hour plus per GB of data processed.

Key distinction: an IGW allows bidirectional internet access; a NAT gateway allows outbound-only.

## Security Groups

A **security group** is a stateful firewall attached to individual resources (EC2 instances, RDS databases, Lambda functions, etc.).

**Stateful** means: if you allow inbound traffic from a source, the return traffic is automatically allowed without an explicit outbound rule. You don't need separate rules for request and response.

Security group rules are **allow-only**. You add rules to allow specific traffic; everything not explicitly allowed is denied. You cannot write explicit deny rules in a security group.

**Default behavior**: all inbound traffic denied, all outbound traffic allowed.

Example: an RDS security group might allow inbound TCP port 5432 only from the security group attached to your application servers. This restricts database access to the app tier without allowing anything else.

## Network ACLs

A **Network ACL (NACL)** is a stateless firewall at the subnet boundary. It evaluates all traffic entering or leaving the subnet, independent of any resource-level security groups.

**Stateless** means: inbound and outbound rules are evaluated independently. If you allow inbound HTTP on port 80, you must also explicitly allow the return traffic (ephemeral ports 1024–65535 outbound) or the response never reaches the client.

NACLs support both **allow and deny** rules, evaluated in order by rule number (lowest first). This lets you explicitly block specific IP ranges -- something security groups cannot do.

**Default NACL**: allows all inbound and outbound traffic.

In practice: security groups handle most access control. NACLs are a defense-in-depth layer configured once and rarely changed. The critical conceptual difference is **stateful (security group) vs stateless (NACL)**.

## The Standard 3-Tier Architecture

Almost every well-architected AWS application follows a 3-tier pattern:

```
Internet
    |
[Public Subnets]
    Load Balancer (ALB)
    |
[Private Subnets - App Tier]
    EC2 / ECS / Lambda
    |
[Private Subnets - Data Tier]
    RDS / DynamoDB / ElastiCache
```

**Why this structure:**
- The load balancer in the public subnet is the only point of internet exposure.
- Application servers in private subnets are unreachable from the internet. They receive traffic only from the load balancer's security group.
- Databases in private subnets are unreachable from both the internet and the load balancer. They accept connections only from the application servers' security group.

Each layer's security group references the layer above: the database security group only allows the app server security group. This is least-privilege networking.

## Key Takeaways

- A VPC is an isolated virtual network. Subnets subdivide it by AZ and exposure level.
- A public subnet has a route to an internet gateway. A private subnet does not.
- Internet Gateway: bidirectional internet access for public subnets. NAT Gateway: outbound-only internet access for private subnets.
- Security groups are stateful (return traffic automatic) and allow-only. Applied to individual resources.
- NACLs are stateless (must allow both directions explicitly) and support allow and deny rules. Applied to subnets.
- The standard 3-tier pattern: load balancer in public subnet, app servers and databases in private subnets.
