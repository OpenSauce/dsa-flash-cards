---
title: "Message Queues and Async Processing"
summary: "Synchronous vs asynchronous communication, message queue anatomy, pub/sub vs point-to-point, delivery guarantees, dead letter queues, and backpressure."
reading_time_minutes: 5
order: 6
---

## Why This Matters

Synchronous request-response works for simple systems. At scale, it creates tight coupling: if a downstream service is slow or unavailable, the caller blocks or fails. Message queues decouple producers from consumers, enable async processing, and absorb traffic spikes. Almost every large system uses them for background jobs, notifications, event streaming, and inter-service communication.

## Synchronous vs Asynchronous Communication

**Synchronous:** The caller sends a request and waits for a response before proceeding. The call chain is as slow as its slowest step. If a service is unavailable, the caller fails immediately.

**Asynchronous:** The caller sends a message and continues without waiting. The message is processed later, independently, by another service. The caller and the worker are decoupled in both time and reliability.

**When to use async:**
- The caller does not need the result immediately (sending an email, resizing an image, generating a report)
- Processing takes too long to block a user request (video transcoding, batch ML inference)
- You need to absorb traffic spikes without overloading downstream services
- Multiple consumers need to react to the same event (user signs up → send welcome email AND create analytics record AND notify ops)

## Message Queue Anatomy

A message queue has three roles:

**Producer:** Sends messages to the queue. Does not know who will process them or when.

**Broker:** The queue itself. Stores messages and delivers them to consumers. Handles persistence, ordering, and delivery guarantees. Examples: Kafka, RabbitMQ, AWS SQS, Google Pub/Sub.

**Consumer:** Reads messages from the queue and processes them. May be one consumer or a pool of workers.

Messages sit in the queue until a consumer retrieves them. If consumers are slow, messages accumulate. If the queue fills, new messages may be dropped or the producer may block -- this is backpressure (covered below).

## Pub/Sub vs Point-to-Point

Two fundamental messaging patterns.

### Point-to-Point (Queue)

A message goes to exactly one consumer. Multiple consumers compete to process messages from the same queue. Each message is processed once.

**Use when:** You have a task that should be done once by one worker. Order processing, job scheduling, email sending -- each message represents one unit of work.

**Scaling:** Add more consumer instances to increase throughput. The queue distributes work across them automatically.

### Pub/Sub (Topic)

A message is broadcast to all subscribers. Multiple consumers each receive their own copy of the message. One event can trigger N reactions.

**Use when:** Multiple independent systems need to react to the same event. User signup → welcome email service AND analytics service AND fraud detection service all receive the same event simultaneously.

**Decoupling:** The producer does not know who subscribes. Adding a new subscriber requires no change to the producer.

## Delivery Guarantees

Message queues offer different guarantees about whether a message is delivered and processed exactly once. Each guarantee has a trade-off.

### At-Most-Once

The broker sends the message once. If the consumer fails before acknowledging, the message is lost. No retry.

**Use when:** Losing some messages is acceptable. Metrics, log aggregation, analytics events -- missing a few data points does not break the system.

**Advantage:** Lowest overhead. No state tracking required.

### At-Least-Once

The broker retries until it receives an acknowledgment. If the consumer crashes after processing but before acknowledging, the message is redelivered. The consumer may process it multiple times.

**Use when:** You cannot afford to lose messages. The consumer must be **idempotent** -- processing the same message twice must produce the same result as processing it once.

**Idempotency key:** Include a unique message ID. The consumer records processed IDs and skips duplicates.

### Exactly-Once

Each message is processed exactly once, even in the presence of retries and failures.

**Hardest to achieve.** Requires coordination between the broker and consumer -- typically distributed transactions or idempotent consumers with deduplication at the broker level.

**Kafka's exactly-once semantics** (since version 0.11) use transactions scoped to a producer session. It works but adds overhead. Use it only when duplicates genuinely cannot be tolerated (financial debits, inventory decrements).

## Dead Letter Queues

A dead letter queue (DLQ) is a separate queue that receives messages that fail processing after a maximum number of retry attempts.

**Why it matters:** Without a DLQ, a poison message (malformed data, a bug that causes the consumer to crash) can block the queue indefinitely. Retries fill the queue. No other messages get processed.

With a DLQ, poison messages are isolated after N failures. The main queue continues processing healthy messages. A human or automated process inspects the DLQ and decides whether to replay the message, discard it, or fix the bug that caused the failure.

## Backpressure

When consumers are slower than producers, messages accumulate. Backpressure is the mechanism by which a system signals to producers to slow down.

**Without backpressure:** The queue fills up. New messages are dropped or the producer's send operation blocks indefinitely. The system degrades unpredictably.

**Explicit backpressure:** The producer checks queue depth before sending. If depth exceeds a threshold, the producer slows down or buffers locally.

**Implicit backpressure (blocking):** The producer's send call blocks when the queue is full. This naturally throttles the producer to the consumer's rate.

Kafka handles backpressure through consumer-controlled polling: consumers pull from the broker at their own pace. If consumers fall behind, the broker's retention window eventually drops old messages (a form of backpressure by data loss -- acceptable for streams, not for tasks).

## Kafka vs RabbitMQ

Two dominant choices, with different primary use cases.

**Kafka** is a distributed log. Messages are persisted on disk and retained for a configurable period (days or weeks). Consumers track their position (offset) in the log independently. A new consumer can replay historical messages from the beginning.

**Use Kafka for:** Event streaming, audit logs, data pipelines, replaying events for new services. Any scenario where you need a durable, replayable log.

**RabbitMQ** is a traditional message broker. Messages are delivered to consumers and acknowledged. Once acknowledged, messages are deleted. No replay.

**Use RabbitMQ for:** Task queues, work distribution, complex routing (messages to different queues based on content). Traditional producer-consumer patterns where you do not need replay.

## Key Takeaways

- Async processing decouples producers from consumers, absorbs spikes, and enables fanout. Use it when the caller does not need an immediate result.
- Point-to-point queues deliver each message to one consumer. Pub/sub delivers each message to all subscribers.
- At-most-once loses messages. At-least-once may duplicate them (require idempotent consumers). Exactly-once is achievable but expensive.
- Dead letter queues isolate poison messages so they do not block healthy processing.
- Kafka is a durable, replayable log. RabbitMQ is a traditional broker that deletes messages after acknowledgment. Match the tool to the pattern.
