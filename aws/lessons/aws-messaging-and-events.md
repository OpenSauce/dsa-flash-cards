---
title: "Messaging, Events, and Global Distribution"
order: 7
summary: "SQS (queues, Standard vs FIFO, DLQs), SNS (pub/sub fan-out), EventBridge (event bus, content-based routing). SNS+SQS fan-out pattern. CloudFront CDN and Route 53 DNS for global delivery."
---

## Why This Matters

Synchronous request-response works until services get slow, unreliable, or overloaded. Messaging systems decouple producers from consumers, absorb traffic spikes, and enable event-driven architectures where downstream services react to changes without the upstream service knowing (or caring) who they are. CloudFront and Route 53 apply the same "decoupling via indirection" principle at the global network level.

## Amazon SQS: Message Queues

**SQS (Simple Queue Service)** is a durable message queue. Producers send messages to the queue; consumers poll the queue and process messages. Each message is processed by exactly one consumer.

SQS decouples producers and consumers: the producer doesn't need to know who processes the message, and the consumer doesn't need to be running when the message is sent. Messages are retained for up to 14 days.

### Standard vs FIFO

**SQS Standard:**
- Near-unlimited throughput (thousands of messages per second)
- At-least-once delivery: messages may be delivered more than once (consumers must be idempotent)
- Best-effort ordering: messages may arrive out of order

**SQS FIFO:**
- Guaranteed ordering: messages are delivered in exactly the order they were sent
- Exactly-once processing: deduplication within a 5-minute window prevents duplicate delivery
- Throughput limit: 300 messages/second (3,000/second with batching) per message group
- Queue name must end in `.fifo`

Choose Standard unless ordering guarantees or exactly-once processing are required. Most systems should be designed to tolerate duplicates and out-of-order messages -- it's simpler and scales better. FIFO queues are for financial transactions, sequential workflow steps, or command processing where order changes the outcome.

### Dead-Letter Queues

A **dead-letter queue (DLQ)** is a separate SQS queue that receives messages that have failed processing repeatedly.

You configure a `maxReceiveCount` on the source queue (e.g., 5). If a message is received 5 times without being deleted (the consumer failed to process it each time), SQS automatically moves it to the DLQ.

DLQs provide:
- **Isolation of failures**: poison messages (malformed data, missing dependencies) don't block the main queue
- **Visibility**: set a CloudWatch alarm on DLQ depth to alert when processing is systematically broken
- **Reprocessing**: after fixing the bug, redrive messages from the DLQ back to the source queue

Every production SQS queue should have a DLQ configured.

## Amazon SNS: Pub/Sub Fan-Out

**SNS (Simple Notification Service)** is a pub/sub messaging service. One publisher sends a message to an SNS topic, and all subscribers receive a copy simultaneously. This is push-based fan-out.

Subscribers can be: SQS queues, Lambda functions, HTTP/HTTPS endpoints, email addresses, SMS numbers.

SNS does not provide queue-like message retention. Messages are pushed to subscribers with retries, but if all subscribers are down, messages are lost. For durability, subscribe SQS queues to SNS topics.

### SNS + SQS Fan-Out Pattern

The standard pattern for event-driven architectures: an SNS topic fans out to multiple SQS queues. Each queue is consumed independently by a different service.

```
                    ┌─────────────────┐
                    │  Order Placed   │
                    │   (SNS Topic)   │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        [SQS Queue]    [SQS Queue]    [SQS Queue]
        Inventory       Email         Analytics
        Service         Service       Service
```

This combines SNS's fan-out with SQS's durability and retry semantics. Each downstream service gets its own queue, can consume at its own pace, and has independent DLQ configuration. Adding a new downstream service is a one-time SNS subscription -- the producer never changes.

## Amazon EventBridge: Event Bus

**EventBridge** is a serverless event bus for routing events between AWS services, SaaS applications, and your own services.

**Content-based filtering**: EventBridge routes events by matching fields in the event payload. For example: "route events where `source=orders` and `detail.status=failed` to the fraud detection Lambda." SNS can filter by message attributes but not by payload content.

**Native integrations**: 90+ AWS services can publish events to EventBridge natively -- CloudTrail API calls, EC2 state changes, S3 events, DynamoDB streams -- without any custom code.

**Event archive and replay**: EventBridge can archive all events and replay them. Useful for debugging, populating new downstream consumers with historical data, or recovering from processing failures.

**Schema registry**: EventBridge discovers and stores event schemas, enabling auto-generated code bindings for consumers.

### EventBridge vs SNS

Use SNS for straightforward fan-out to multiple endpoints where filtering is simple. Use EventBridge when you need content-based routing on payload fields, complex event patterns, schema registry, or replay capability.

## Amazon CloudFront: Global CDN

**CloudFront** is AWS's Content Delivery Network with 400+ edge locations worldwide. It caches and serves content from the location closest to the requesting user.

When a user requests content, their request hits the nearest CloudFront edge location. If the edge has a cached copy (cache hit), it returns immediately without contacting your origin. On a cache miss, the edge fetches from your origin, caches the response, and returns it.

**Benefits**: Reduced latency for global users (Tokyo users hit a Tokyo edge, not a Virginia origin), reduced origin load (most requests served from cache), built-in DDoS protection (AWS Shield Standard is included).

**Origins**: CloudFront can front S3 buckets, Application Load Balancers, EC2 instances, or any HTTP endpoint. Use it for static assets (JS, CSS, images), video streaming, and API acceleration.

**Origin Shield**: An optional additional caching layer between CloudFront's regional edge caches and your origin. Without Origin Shield, each regional edge independently fetches from your origin on a cache miss. With Origin Shield, all regional edges fetch through a single centralized cache layer, collapsing multiple origin fetches into one. Use it when origin load is a bottleneck.

## Amazon Route 53: DNS and Traffic Routing

**Route 53** is AWS's DNS service (named after DNS port 53). It resolves domain names to IP addresses and can route traffic intelligently based on health, geography, and latency.

**Routing policies:**
- **Simple**: One record, one resource. Basic DNS.
- **Weighted**: Distribute traffic by percentage. Use for canary deployments (5% to new version, 95% to old).
- **Latency-based**: Route users to the AWS region with the lowest measured latency. Essential for multi-region deployments.
- **Failover**: Active-passive. Route to primary; automatically switch to standby if primary fails health checks.
- **Geolocation**: Route based on user's geographic location. Use for data residency requirements (EU users → EU region) or localized content.
- **Multi-value answer**: Return up to 8 healthy IP addresses. Lightweight failover without a load balancer.

**Health checks**: Route 53 monitors endpoints and removes unhealthy targets from DNS responses. This enables DNS-level failover without application-layer logic.

## Key Takeaways

- SQS is a durable message queue. Standard offers high throughput; FIFO guarantees ordering and deduplication but has lower throughput limits.
- Dead-letter queues capture messages that repeatedly fail processing. Every production queue should have one.
- SNS is push-based pub/sub fan-out. One message to one topic, delivered to all subscribers simultaneously.
- SNS + SQS fan-out pattern: fan out events to multiple SQS queues, each consumed independently with full queue semantics.
- EventBridge is an event bus with content-based filtering, 90+ native AWS integrations, and archive/replay. Use it when SNS's simpler filtering isn't enough.
- CloudFront caches content at edge locations close to users. Origin Shield adds a centralized caching layer to reduce origin load.
- Route 53 provides DNS with intelligent routing: latency-based routing and failover policies are the standard multi-region answer.
