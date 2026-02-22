---
title: "Network Models: OSI and TCP/IP"
order: 1
reading_time_minutes: 4
summary: "The 7-layer OSI model, the 4-layer TCP/IP model, what each layer does, encapsulation, and why layered models matter for reasoning about protocols."
---

## Why This Matters

When engineers talk about "Layer 4 load balancing" or "a Layer 7 firewall," they are speaking the language of network models. The OSI and TCP/IP models give you a shared vocabulary for describing where in the stack a protocol or device operates. Every subsequent networking topic -- TCP, DNS, HTTP, TLS -- maps onto these layers. Without this foundation, protocol discussions become a soup of acronyms with no organizing structure.

## The TCP/IP Model: Four Layers

The TCP/IP model is what the internet actually runs on. It has four layers, each responsible for a distinct concern:

```
┌─────────────────────────────────────────────────────┐
│  Application Layer                                   │
│  HTTP, DNS, SMTP, SSH, gRPC, WebSocket               │
├─────────────────────────────────────────────────────┤
│  Transport Layer                                     │
│  TCP, UDP  (end-to-end delivery between processes)   │
├─────────────────────────────────────────────────────┤
│  Internet Layer                                      │
│  IP  (addressing, routing across networks)           │
├─────────────────────────────────────────────────────┤
│  Link Layer (Network Access)                         │
│  Ethernet, Wi-Fi, fiber  (physical transmission)     │
└─────────────────────────────────────────────────────┘
```

**Application layer:** Where user-facing protocols live. HTTP, DNS, SMTP, and SSH are all application-layer protocols. This layer defines how applications format and interpret data -- the meaning of a message, not how it travels.

**Transport layer:** Handles end-to-end communication between processes on different hosts. TCP provides ordered, reliable delivery. UDP provides fast, connectionless delivery. A port number identifies which process on a host should receive a given packet.

**Internet layer:** Routes packets across networks. IP (Internet Protocol) assigns logical addresses to hosts and makes routing decisions at each hop. IP does not guarantee delivery or ordering -- that is TCP's job.

**Link layer:** Handles physical transmission of bits over a medium -- Ethernet frames, Wi-Fi radio signals, fiber optic pulses. Deals with MAC addresses (physical hardware addresses) and error detection at the local network level.

## The OSI Model: Seven Layers

The OSI (Open Systems Interconnection) model was developed as a universal reference framework before TCP/IP dominated the industry. It splits the TCP/IP layers into finer pieces:

```
OSI Layer          TCP/IP Equivalent
─────────────────────────────────────────
7  Application  ─┐
6  Presentation  ├─  Application layer
5  Session      ─┘
─────────────────────────────────────────
4  Transport    ──   Transport layer
─────────────────────────────────────────
3  Network      ──   Internet layer
─────────────────────────────────────────
2  Data Link    ─┐
1  Physical     ─┘   Link layer
─────────────────────────────────────────
```

The extra OSI layers capture concepts that TCP/IP lumps together:

- **Presentation (Layer 6):** Data format translation, encryption, compression. In practice, TLS handles this but lives at the application layer in TCP/IP.
- **Session (Layer 5):** Managing sessions between applications (setup, teardown, resumption). Modern protocols handle this internally.
- **Physical (Layer 1):** The actual electrical signals, light pulses, or radio waves. Data Link (Layer 2) handles framing and MAC addressing.

For interviews and system design, **TCP/IP layer numbers (1-4) are used less often than OSI layer numbers (1-7)**. When someone says "Layer 3 routing" they mean IP. "Layer 4 load balancing" means TCP/UDP. "Layer 7 proxy" means something that reads HTTP headers.

## Encapsulation: How Data Travels Down the Stack

When you send an HTTP request, each layer wraps the data from the layer above in its own header. This is encapsulation:

```
Application:  [HTTP request data]
Transport:    [TCP header | HTTP request data]
Internet:     [IP header | TCP header | HTTP request data]
Link:         [Ethernet header | IP header | TCP header | HTTP request | Ethernet trailer]
```

At each hop, the router strips the outer headers relevant to its layer, makes a decision, and re-wraps the data for the next segment of the journey. The receiver's stack unwraps in reverse order.

**Why this matters:** Encapsulation is why a VPN can "tunnel" TCP inside UDP -- the inner packet is just data from the outer packet's perspective. It is also why packet captures show nested protocol headers.

## Why Layered Models Exist

Layering enforces separation of concerns. HTTP does not need to know whether it is running over a wired or wireless connection. IP does not need to know whether the application is doing DNS or SMTP. Each layer has a well-defined interface and can be replaced independently.

This modularity enabled the internet's growth: new physical media (fiber, LTE, 5G) were added at Layer 1-2 without touching HTTP. New application protocols were built on top of TCP without touching IP routing. The layered model is what makes protocol evolution tractable.

## Key Takeaways

- The TCP/IP model has four layers: Application, Transport, Internet, and Link. These map roughly to OSI layers 5-7, 4, 3, and 1-2 respectively.
- TCP/IP is what the internet runs on. OSI is a reference model -- useful for its 7-layer vocabulary in conversations, not as a protocol spec.
- Each layer adds a header as data moves down the stack (encapsulation) and strips headers as data moves up (decapsulation).
- Layer numbers in system design conversations usually refer to OSI: Layer 3 = IP routing, Layer 4 = TCP/UDP, Layer 7 = HTTP/application.
- Layering enforces separation of concerns: each layer has a defined interface and can evolve independently.
