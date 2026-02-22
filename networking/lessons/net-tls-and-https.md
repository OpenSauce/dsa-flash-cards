---
title: "TLS and HTTPS"
order: 5
reading_time_minutes: 4
summary: "Symmetric vs asymmetric encryption, the TLS 1.3 handshake, the three guarantees HTTPS provides, certificates and Certificate Authorities, and 0-RTT resumption."
---

## Why This Matters

HTTPS is the lock icon in your browser -- but most engineers cannot explain what it actually does. Understanding TLS (Transport Layer Security) tells you what "secure" means in practice: what an attacker on the same network can and cannot see, why TLS 1.3 is faster than 1.2, and what certificate validation actually proves. This knowledge is essential for designing secure services, debugging TLS errors, and answering "how does HTTPS work?" in system design interviews.

## Two Kinds of Encryption

To understand TLS, you first need to understand the two fundamental approaches to encryption:

**Symmetric encryption** (AES, ChaCha20): One shared key encrypts and decrypts data. Both sides must have the same key. Extremely fast -- gigabytes per second on modern hardware. The problem: how do two parties agree on a shared key over an insecure network without an attacker learning it?

**Asymmetric encryption** (RSA, ECC): A mathematically linked key pair. Data encrypted with the public key can only be decrypted with the private key. The public key can be distributed freely. Also used to create digital signatures -- sign with the private key, verify with the public key. Computationally expensive: roughly 100-1000x slower than symmetric encryption for bulk data.

**The hybrid approach:** TLS uses asymmetric cryptography to establish a shared secret between two parties, then switches to symmetric encryption for all subsequent data. You get the key distribution benefits of asymmetric crypto and the performance of symmetric crypto.

## The TLS 1.3 Handshake

TLS 1.3 reduced the connection setup to a single round trip (down from two in TLS 1.2):

```
Client                              Server
  |                                   |
  |-- ClientHello ------------------>|
  |   (supported ciphers,             |
  |    key share)                     |
  |                                   |
  |<-- ServerHello ------------------|
  |    (chosen cipher, key share,     |
  |     certificate, Finished)        |
  |                                   |
  |-- Finished --------------------->|
  |                                   |
  [  Encrypted data flows both ways  ]
```

**Step 1 -- ClientHello:** The client advertises which cipher suites it supports and sends its half of a key exchange (a public key for ECDHE -- Elliptic Curve Diffie-Hellman Ephemeral).

**Step 2 -- ServerHello:** The server picks a cipher suite, sends its own key exchange half, its certificate (containing its public key and identity), and a "Finished" message authenticating the whole handshake -- all in one response.

**Step 3 -- Client Finished:** The client verifies the server's certificate against trusted Certificate Authorities, uses both key shares to compute the shared symmetric key (the math of ECDHE allows this without ever sending the key over the wire), and sends its own "Finished" message.

Both sides now independently derived the same symmetric session key. All subsequent traffic is encrypted with AES or ChaCha20.

**Why one round trip?** In TLS 1.2, the server's key share was sent in a separate message after choosing parameters. TLS 1.3 allows the client to guess the cipher suite and send a key share immediately, eliminating a round trip in the common case.

## What HTTPS Provides

HTTPS is HTTP over TLS. It provides three guarantees that plain HTTP lacks:

1. **Confidentiality:** Traffic is encrypted. An attacker monitoring the network sees ciphertext -- not passwords, API keys, or response bodies.

2. **Integrity:** Data cannot be tampered with in transit. TLS includes a Message Authentication Code (MAC) with every record. Any modification by an attacker invalidates the MAC and the connection is aborted.

3. **Authentication:** The server proves its identity via a certificate signed by a trusted Certificate Authority. This prevents man-in-the-middle attacks where an attacker impersonates the server.

**What HTTPS does NOT hide:**

The domain name you are connecting to is sent in plaintext during the TLS handshake in the SNI (Server Name Indication) extension. An attacker monitoring the network can see which domain you are connecting to, just not what you send or receive.

ECH (Encrypted Client Hello) is an emerging extension that encrypts the SNI, but it is not yet widely deployed.

## Certificate Authorities

How does your browser decide whether to trust a server's certificate? Certificates are signed by Certificate Authorities (CAs) -- trusted third parties that verify the certificate owner controls the domain.

The trust chain works like this:

```
Root CA (built into OS/browser)
  └── Intermediate CA (signed by root)
        └── Server certificate (signed by intermediate)
```

Your browser ships with ~130 trusted root CA certificates. When a server presents its certificate, the browser walks the chain from the server cert up to a trusted root, verifying each signature.

**Domain Validated (DV) certificates** (Let's Encrypt, etc.) only prove you control the domain -- DNS or file-based verification. No identity information is included. Free and automated.

**Extended Validation (EV) certificates** require legal identity verification of the organization. The CA confirms the company behind the domain. More expensive, slower to obtain.

## 0-RTT Resumption

TLS 1.3 introduced 0-RTT (zero round-trip time) resumption for clients reconnecting to a server they have connected to before. On a fresh visit, you save the session ticket. On a return visit, you can include encrypted data in your very first message -- before the handshake completes.

**The trade-off:** 0-RTT data is vulnerable to replay attacks. An attacker who captures the 0-RTT data can replay it to the server. This is why 0-RTT should only be used for safe, idempotent requests (like GET) -- never for operations that have side effects.

## Key Takeaways

- Symmetric encryption (AES) is fast but requires a shared key. Asymmetric encryption (ECDHE) solves key distribution but is slow. TLS uses asymmetric crypto to establish a shared key, then switches to symmetric for data.
- The TLS 1.3 handshake takes one round trip. The client sends its key share immediately; the server responds with its key share, certificate, and Finished -- all in one message.
- HTTPS provides confidentiality (encrypted), integrity (tamper-evident), and authentication (server identity verified). It does not hide which domain you are connecting to (SNI is plaintext).
- Certificate Authorities sign server certificates to prove domain ownership. Browsers trust a built-in set of root CAs and walk the chain to verify.
- 0-RTT resumption eliminates connection setup latency for returning clients but is replay-susceptible -- limit it to idempotent requests.
