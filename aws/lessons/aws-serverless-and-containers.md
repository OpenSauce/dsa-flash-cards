---
title: "Serverless and Containers"
order: 2
summary: "Lambda (event-driven execution, cold starts, provisioned concurrency), ECS and Fargate (container orchestration), and the decision framework for choosing between EC2, containers, and serverless."
---

## Why This Matters

EC2 is the foundation, but most modern AWS workloads don't run directly on EC2. They run in containers or as serverless functions. Understanding Lambda and ECS -- what they abstract, what they cost, and when to use each -- is essential for AWS architecture interviews and real-world design decisions.

## AWS Lambda: Event-Driven Functions

Lambda lets you run code without managing servers. You upload a function (a single handler), configure a trigger, and AWS handles execution: allocating compute, scaling, and cleanup.

**Key properties:**
- **Event-driven**: Lambda executes in response to an event (HTTP request via API Gateway, an S3 object upload, an SQS message, a CloudWatch schedule, etc.)
- **Maximum execution time**: 15 minutes per invocation. Not suitable for long-running processes.
- **Pay per invocation**: Billed on invocation count and duration (in milliseconds). No charges when idle.
- **Auto-scales to zero**: No traffic, no cost, no running instances.
- **Concurrency-based scaling**: Lambda scales by running more concurrent function instances, not by making one instance faster.

Lambda is the right choice for short-lived, stateless, event-triggered tasks: image resizing on S3 upload, webhook handlers, scheduled cleanup jobs, data transformation pipelines.

## Cold Starts

Lambda runs your function inside an **execution environment** -- a container-like sandbox that includes the runtime, your code, and any initialization. The first time a function is invoked (or when Lambda needs to scale to a new concurrent instance), it must create this environment from scratch:

1. Download the deployment package
2. Start the runtime (Node.js, Python, Java, etc.)
3. Run initialization code (outside your handler)

This is a **cold start**. It adds latency before your handler runs.

**Typical cold start durations:**
- Python, Node.js: 100–500ms
- Java, .NET: 1–10 seconds (JVM/CLR startup is expensive)

After the cold start, the execution environment is kept warm and reused for subsequent invocations. A warm invocation has no startup overhead.

**Mitigations:**
- **Provisioned Concurrency**: Pre-warm a set number of execution environments. They are always ready. Cold starts are eliminated for that capacity -- but you pay for provisioned environments even when idle.
- **Smaller deployment packages**: Less code to download → faster init. Avoid bundling unused dependencies.
- **Choose a faster runtime**: Python and Node.js cold start significantly faster than Java.
- **Move initialization outside the handler**: SDK clients, database connections, and config loading at module level runs once per environment (not per invocation).

**Trade-off**: Provisioned Concurrency costs money for idle capacity, undermining Lambda's pay-per-use advantage. It is worth it for latency-sensitive user-facing paths; overkill for background processing where a 500ms cold start is invisible.

## Amazon ECS: Container Orchestration

ECS (Elastic Container Service) runs Docker containers on AWS. You provide a task definition (which image, CPU, memory, environment variables, port mappings), and ECS handles scheduling and running containers.

ECS has two **launch types** that determine where containers run:

### ECS on EC2

Containers run on EC2 instances you provision and manage. You control the instance type, AMI, and autoscaling of the host fleet. ECS handles placement of containers onto available capacity.

**Advantage**: Maximum control over host resources and cost (especially with Spot instances).
**Disadvantage**: You still manage EC2 instances -- patching, scaling, cluster capacity.

### AWS Fargate

Fargate is **serverless containers**. You define the container (CPU, memory, image) and Fargate runs it without you managing any EC2 instances. No host fleet to maintain.

**Advantage**: No infrastructure management. Pay per task CPU and memory by the second.
**Disadvantage**: Higher per-unit cost than EC2 instances; less control over the host environment.

Fargate is the default choice for most container workloads unless you have specific host requirements or need to optimize cost with Spot instances at scale.

## The Compute Decision Framework

Choosing between EC2, ECS/Fargate, and Lambda comes down to three questions:

| Question | Points toward... |
|----------|-----------------|
| Does the workload run longer than 15 minutes? | EC2 or ECS |
| Do you need OS-level control or persistent local state? | EC2 |
| Is the workload containerized with stable, long-running processes? | ECS/Fargate |
| Is the workload event-triggered, short-lived, and stateless? | Lambda |
| Does the workload have extremely spiky or unpredictable traffic that may drop to zero? | Lambda |
| Is minimizing operational overhead more important than minimizing cost? | Lambda or Fargate |

In practice, architectures often combine all three: EC2 for stateful databases, ECS/Fargate for API services, and Lambda for event-driven processing.

## Key Takeaways

- Lambda is for short-lived (≤15 min), stateless, event-triggered functions. It scales automatically and costs nothing when idle.
- Cold starts occur when Lambda creates a new execution environment. Python/Node cold starts are 100–500ms; Java can be several seconds.
- Provisioned Concurrency eliminates cold starts but charges for idle capacity.
- ECS manages container scheduling. Fargate runs containers without managing EC2 hosts.
- ECS on EC2 gives cost control; Fargate gives operational simplicity.
- Choose based on workload: long-running or stateful → EC2/ECS; event-triggered, stateless, spiky → Lambda.
