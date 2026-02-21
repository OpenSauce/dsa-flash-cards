---
title: "TCP vs UDP"
order: 1
summary: "TCP's connection-oriented reliability model, UDP's connectionless speed, the three-way handshake, and how to choose between them for different workloads."
---

## Why This Matters

TCP and UDP are the two transport-layer protocols that carry virtually all internet traffic. Every HTTP request, every DNS query, every video stream, every online game uses one or the other. When an interviewer asks "how does data get from point A to point B," your answer starts here. When a system design question involves latency trade-offs, the TCP-vs-UDP decision is often the first one that matters.

## TCP: Reliable, Ordered, Connection-Oriented

TCP (Transmission Control Protocol) treats communication as a reliable byte stream. The sender pushes bytes in, and the receiver gets them out in the same order, with no gaps and no duplicates. TCP achieves this through a set of mechanisms that trade latency for correctness.

### The Three-Way Handshake

Before any data is sent, TCP establishes a connection using a three-step process:

```
Client                    Server
  |                         |
  |--- SYN (seq=x) ------->|   1. Client picks random sequence number x
  |                         |
  |<-- SYN-ACK (seq=y, ----|   2. Server picks its own sequence number y,
  |        ack=x+1)        |      acknowledges client's by setting ack=x+1
  |                         |
  |--- ACK (ack=y+1) ----->|   3. Client acknowledges server's sequence number
  |                         |
  [   Connection open       ]
```

**Why three steps and not two?** Both sides must agree on initial sequence numbers so they can track which bytes have been sent and received. Two messages would leave the server's sequence number unacknowledged -- the client would not know if the server received its SYN. The third step confirms both sides are synchronized.

**Why random sequence numbers?** Predictable sequence numbers allow attackers to forge packets and hijack connections (TCP sequence prediction attacks). Random initialization prevents this and also avoids confusion with delayed packets from previous connections on the same port.

### Reliability Mechanisms

Once the connection is established, TCP guarantees delivery through several mechanisms:

**Acknowledgments and retransmission.** The receiver acknowledges every segment. If the sender does not receive an ACK within a timeout window, it retransmits the segment. This handles packet loss.

**Ordering.** Each byte in the stream has a sequence number. The receiver reassembles segments in order, even if they arrive out of order on the network.

**Flow control.** The receiver advertises a "window size" -- how much data it can buffer. The sender never sends more than this amount without receiving acknowledgments. This prevents a fast sender from overwhelming a slow receiver.

**Congestion control.** TCP monitors the network for signs of congestion (packet loss, increased latency) and reduces its sending rate accordingly. Algorithms like slow start, congestion avoidance, and fast retransmit balance throughput against network capacity.

### Connection Teardown

Closing a TCP connection takes four steps (FIN, ACK, FIN, ACK) because each direction is closed independently. One side can finish sending (half-close) while the other still has data to transmit.

## UDP: Fast, Unordered, Connectionless

UDP (User Datagram Protocol) is the opposite of TCP in almost every way. There is no handshake, no connection state, no acknowledgments, no ordering guarantees, and no congestion control. A UDP "datagram" is a single, independent packet.

### What UDP Provides

The UDP header is 8 bytes total -- just four fields:

- Source port
- Destination port
- Length
- Checksum (optional in IPv4, mandatory in IPv6)

That is it. No sequence numbers, no window sizes, no state. The sender fires a datagram at an address and moves on. If the packet is lost, duplicated, or arrives out of order, UDP does not care. The application must handle these scenarios if they matter.

### Why Use Something So Unreliable?

Because reliability has a cost. TCP's handshake adds a round-trip before any data flows. Acknowledgments and retransmissions add latency when packets are lost. Congestion control throttles throughput. Head-of-line blocking means a single lost segment stalls the entire byte stream until it is retransmitted.

For some workloads, this cost is unacceptable:

**Video and audio streaming.** A dropped frame from 200 milliseconds ago is worthless. Retransmitting it delays all subsequent frames. It is better to skip it and keep playing.

**Online gaming.** Player position updates happen 30-60 times per second. If one update is lost, the next one renders it obsolete anyway. Waiting 200ms for a retransmit makes the game unplayable.

**DNS lookups.** A DNS query is a single small request/response. Establishing a full TCP connection for one question/answer exchange is wasteful. (DNS does fall back to TCP for large responses that exceed the UDP datagram size limit.)

**QUIC / HTTP/3.** The QUIC protocol, which underlies HTTP/3, is built on top of UDP. QUIC implements its own reliability and ordering at the application layer, but it avoids TCP's head-of-line blocking by multiplexing independent streams -- a lost packet in one stream does not stall the others.

## Head-of-Line Blocking

This is one of the most important concepts for understanding why UDP-based protocols exist.

In TCP, the byte stream is ordered. If segment 5 out of 10 is lost, segments 6-10 are held in the receiver's buffer until segment 5 is retransmitted and arrives. Even though segments 6-10 are perfectly fine, the application cannot read them. One lost packet blocks everything behind it.

HTTP/2 multiplexes many requests over a single TCP connection. If any packet is lost, all multiplexed streams stall -- not just the stream that lost the packet. This is TCP-level head-of-line blocking, and it is the specific problem HTTP/3 (over QUIC/UDP) was designed to solve.

## Choosing Between TCP and UDP

| Factor | TCP | UDP |
|--------|-----|-----|
| Reliability | Guaranteed delivery, ordering | No guarantees |
| Latency | Higher (handshake, retransmits) | Lower (no setup, no waiting) |
| Overhead | 20+ byte header, connection state | 8-byte header, no state |
| Flow control | Built-in | Application must implement |
| Use cases | HTTP, file transfer, email, DB connections | Streaming, gaming, DNS, VoIP |

**Rule of thumb:** If losing a packet means corrupted data or broken functionality (file transfer, database queries, API calls), use TCP. If losing a packet just means slightly degraded quality for a fraction of a second (video, audio, game state), use UDP.

In practice, most applications use TCP via HTTP. UDP is chosen deliberately for specific latency-sensitive or real-time workloads.

## TCP and UDP in the Network Stack

Both protocols sit at the **transport layer** (Layer 4) of the TCP/IP model. They run on top of IP (Internet Protocol), which handles addressing and routing, and below the application layer, where protocols like HTTP, DNS, and gRPC operate.

```
Application  │  HTTP, DNS, gRPC, QUIC
─────────────┼─────────────────────────
Transport    │  TCP or UDP
─────────────┼─────────────────────────
Internet     │  IP (addressing, routing)
─────────────┼─────────────────────────
Link         │  Ethernet, Wi-Fi
```

A port number (0-65535) identifies a specific process on a host. The combination of IP address + port + protocol (TCP or UDP) uniquely identifies a network endpoint.

## Key Takeaways

- TCP guarantees delivery, ordering, and flow control through acknowledgments and retransmissions. This reliability comes at the cost of latency (handshake, retransmit delays, head-of-line blocking).
- UDP sends independent datagrams with no connection setup, no ordering, and no delivery guarantees. It is faster but pushes reliability concerns to the application.
- The TCP three-way handshake (SYN, SYN-ACK, ACK) synchronizes sequence numbers between client and server. Random initial sequence numbers prevent hijacking and stale-packet confusion.
- Head-of-line blocking in TCP is why HTTP/3 moved to QUIC (UDP-based): a lost packet in one stream should not stall unrelated streams.
- Default to TCP. Choose UDP only when latency is critical and occasional data loss is acceptable.
