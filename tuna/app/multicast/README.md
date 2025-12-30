# Multicast - Group Traffic Filtering

## Overview

This example implements multicast filtering functionality on a smart NIC using P4, enabling efficient delivery of group-specific network traffic to hosts. The P4 program processes packets exclusively in the ingress pipeline (network-to-host direction): upon receiving a packet, it identifies multicast traffic via destination MAC address and destination IP prefix matching. If classified as multicast, the `mc` field in the output metadata is set to 1. The packet then undergoes a multicast address table lookup using the destination MAC address—matching entries result in the packet being forwarded to the host, while non-matching entries trigger the `drop` flag in the output metadata (subsequently discarded by downstream NIC modules).

The P4 implementation focuses solely on multicast identification and filtering. In practical deployment, hosts join multicast groups via the IGMP (Internet Group Management Protocol); the host driver communicates these group memberships to the smart NIC, which dynamically configures the multicast address table. This table management process is transparent to the P4 program.

This example demonstrates how P4 enables hardware-accelerated multicast traffic control in smart NICs, ensuring only authorized group traffic reaches the host.

## Learning Objectives

By completing this exercise, you will learn:

* **Multicast Fundamentals**: Identify and process group-specific network traffic
* **Traffic Classification**: Use destination MAC and IP prefix for multicast detection
* **Exact Match Tables**: Implement multicast address filtering with lookup tables
* **Metadata Control**: Manage `mc` (multicast indicator) and `drop` flags
* **Smart NIC Integration**: Coordinate with IGMP-driven table configuration and downstream modules

## What You'll Implement

The P4 program implements multicast filtering that:

1. **Multicast Identification**:
* Detects multicast packets via destination MAC address and destination IP prefix
* Sets `mc = 1` in output metadata for identified multicast traffic
2. **Multicast Address Filtering**:
* Performs exact match lookup using destination MAC address
* Allows forwarding for table-matched packets
* Sets `drop = 1` for non-matched packets
3. **Metadata Propagation**:
* Conveys multicast status and drop decisions to downstream NIC modules
* Maintains minimal processing overhead for line-rate performance

## Multicast Concepts

### What is Multicast?

Multicast is a network communication paradigm that:

* Delivers a single packet stream to multiple interested recipients (groups)
* Reduces network bandwidth consumption compared to unicast (one-to-one)
* Optimizes resource usage for group-specific traffic (e.g., video streaming, IoT data)
* Uses dedicated multicast addresses for group identification

### Multicast Traffic Identification

Multicast packets are distinguished by standard address conventions:

* **IPv4 Multicast IP**: Range `224.0.0.0/4` (224.0.0.0 to 239.255.255.255)
  * Reserved for group communication
  * Prefix-based identification (first 4 bits = 1110)
* **Ethernet Multicast MAC**: Prefix `01-00-5E` (first 24 bits)
  * Maps to IPv4 multicast addresses
  * Ensures Layer 2 multicast frame delivery

### IGMP and Multicast Group Management

Internet Group Management Protocol (IGMP) enables:

* Hosts to join/leave multicast groups
* Routers/switches to learn group memberships
* Dynamic configuration of multicast forwarding tables
* In this implementation: IGMP triggers table updates via host driver (P4-agnostic)

### Multicast Filtering Purpose

Filtering multicast traffic at the NIC level:

* Prevents unwanted group traffic from reaching the host
* Reduces CPU load by discarding unsubscribed traffic early
* Improves security by blocking unauthorized multicast streams
* Optimizes bandwidth usage between NIC and host

## Network Topology

```
      Host 1                           Host 2
   10.0.1.1/24                      10.0.1.2/24
MAC: c2:0c:20:4a:23:65        MAC: 62:9b:0c:db:ac:20
        │                                │
        │                                │
   ┌────┴────┐                      ┌────┴────┐
   │  NIC 1  │──────────────────────│  NIC 2  │
   └─────────┘                      └─────────┘

Multicast P4 Program runs on all NICs (n1, n2)
NIC 1 sends normal and multicase packets
NIC 2 receives packets, identify packet type, match the dst MAC in multicast filter table to transmit or drop packets
```

**Configuration**:

* **Smart NIC**: Runs P4 program for multicast filtering; maintains multicast address table
* **Multicast Source**: Sends traffic to multicast addresses (IPv4 + MAC)
* **Host**: Joins/leaves multicast groups via IGMP; driver configures NIC table
* **Ingress Pipeline**: Identifies multicast traffic and applies filtering rules
* **Downstream NIC Modules**: Enforce drop decisions based on P4 metadata

## P4 Program Details

### MAC And IP Prefix Definition

```c
const bit<24> MULTICAST_MAC_PREFIX = 0x01005e;
const bit<4> MULTICAST_IP_PREFIX = 0xe;

```

### Actions: transmit or drop

```c
action transmit() {
    // do nothing
}

action drop() {
    ostd.drop = 1;
}
```

### multicast_filter Table

```c
table multicast_filter {
    key = {
        hdr.ethernet.dstAddr: exact;
    }
    actions = {
        transmit;
        drop;
    }
    default_action = drop();
    const entries = {  // filter multicast packet by dst MAC
        0x01005e000102 : transmit();  // MAC: 01:00:5e:00:01:02, IP: X.0.1.2
    }
    size = 1024;
}
```

### Identify Multicast Packets

```c
apply {
    if (hdr.ethernet.dstAddr[47:24] == MULTICAST_MAC_PREFIX &&
        hdr.ipv4.dstAddr[31:28] == MULTICAST_IP_PREFIX) {
        ostd.mc = 1;
        multicast_filter.apply();
    }
}
```

Control applies multicast_filter table to filter unmatched packets during the ingress pipeline

### Pipeline Structure

**Ingress Pipeline**:

* Parser: Extracts Ethernet (destination MAC) and IPv4 (destination IP) headers
* Control:
  * Identifies multicast via MAC prefix + IP prefix check
  * Sets `mc = 1` for multicast packets
  * Performs exact match lookup on destination MAC (multicast address table)
  * Sets `drop = 1` if no match is found
* Deparser: Reassembles and emits headers (with updated metadata)

**Egress Pipeline**:

* No multicast-specific processing (minimal pass-through)

## How to Run

In your shell, run:
```bash
cd tuna/app/multicast
make
```
This will:
1. compile `multicast.p4`
2. start the topo in Mininet and configure all NIC with the appropriate P4 program + table entries, and configure all hosts with the commands listed in [topology.json](./topology.json)
3. You should now see a Mininet command prompt. Try to ping between hosts in the topology:
   ```bash
   mininet> h2 python3 recv.py bmv2 &
   mininet> h1 python3 send.py bmv2 62:9b:0c:db:ac:20 10.0.1.2 2
   mininet> h1 python3 send.py bmv2 01:00:5e:00:01:02 224.0.1.2 2
   mininet> h1 python3 send.py bmv2 01:00:5e:00:02:04 239.0.2.4 2
   ```

   You will get:
   ```bash
   mininet> h2 python3 recv.py bmv2 &
   mininet> h1 python3 send.py bmv2 62:9b:0c:db:ac:20 10.0.1.2 2
   ###[ Ethernet ]### 
     dst       = 62:9b:0c:db:ac:20
     src       = c2:0c:20:4a:23:65
     type      = IPv4
   ###[ IP ]### 
        version   = 4
        ihl       = 5
        tos       = 0x0
        len       = 45
        id        = 1
        flags     = 
        frag      = 0
        ttl       = 64
        proto     = udp
        chksum    = 0x64bd
        src       = 10.0.1.1
        dst       = 10.0.1.2
        \options   \
   ###[ UDP ]### 
           sport     = 1234
           dport     = 4321
           len       = 25
           chksum    = 0xa8d1
   ###[ Raw ]### 
              load      = 'P4 multicast test'
   
   .
   Sent 1 packets.
   .
   Sent 1 packets.
   mininet> h1 python3 send.py bmv2 01:00:5e:00:01:02 224.0.1.2 2
   WARNING: No route found (no default route?)
   WARNING: No route found (no default route?)
   WARNING: more No route found (no default route?)
   ###[ Ethernet ]### 
     dst       = 01:00:5e:00:01:02
     src       = 00:00:00:00:00:00
     type      = IPv4
   ###[ IP ]### 
        version   = 4
        ihl       = 5
        tos       = 0x0
        len       = 45
        id        = 1
        flags     = 
        frag      = 0
        ttl       = 64
        proto     = udp
        chksum    = 0x99bd
        src       = 0.0.0.0
        dst       = 224.0.1.2
        \options   \
   ###[ UDP ]### 
           sport     = 1234
           dport     = 4321
           len       = 25
           chksum    = 0xddd1
   ###[ Raw ]### 
              load      = 'P4 multicast test'
   
   .
   Sent 1 packets.
   .
   Sent 1 packets.
   mininet> h1 python3 send.py bmv2 01:00:5e:00:02:04 239.0.2.4 2
   WARNING: No route found (no default route?)
   WARNING: No route found (no default route?)
   WARNING: more No route found (no default route?)
   ###[ Ethernet ]### 
     dst       = 01:00:5e:00:02:04
     src       = 00:00:00:00:00:00
     type      = IPv4
   ###[ IP ]### 
        version   = 4
        ihl       = 5
        tos       = 0x0
        len       = 45
        id        = 1
        flags     = 
        frag      = 0
        ttl       = 64
        proto     = udp
        chksum    = 0x89bb
        src       = 0.0.0.0
        dst       = 239.0.2.4
        \options   \
   ###[ UDP ]### 
           sport     = 1234
           dport     = 4321
           len       = 25
           chksum    = 0xcdcf
   ###[ Raw ]### 
              load      = 'P4 multicast test'
   
   .
   Sent 1 packets.
   .
   Sent 1 packets.
   mininet>
   ```
4. Type `exit` to leave each xterm and the Mininet command line.
   Then, to stop mininet:
   ```bash
   make stop
   ```
   And to delete all pcaps, build files, and logs:
   ```bash
   make clean
   ```

## Expected Results

- You will find that the messages "`tuna_ingress_output_metadata.mc: 1`" is printed four times in the ./logs/n2.log.
- You will find that the messages "`tuna_ingress_output_metadata.mc: 0`" is printed two times in the ./logs/n2.log.
- You will find that the messages "`tuna_ingress_output_metadata.drop: 1`" is printed two times in the ./logs/n2.log.
- You will find that the messages "`tuna_ingress_output_metadata.drop: 0`" is printed four times in the ./logs/n2.log.

## Understanding the Multicast Logic

### Packet Processing Flow (Network → Host)

1. **Packet arrives from network** at smart NIC ingress
2. **Parser extracts headers**: Extracts destination MAC (Layer 2) and destination IP (Layer 3)
3. **Multicast identification**:
* Checks if destination MAC starts with `01-00-5E` (Ethernet multicast prefix)
* Checks if destination IP is in `224.0.0.0/4` (IPv4 multicast prefix)
* If both conditions met: Sets `meta.mc`` = 1` (mark as multicast)
4. **Multicast address table lookup**:
* Uses destination MAC as key for exact match table
* Table entries populated via host driver (IGMP-triggered)
5. **Filter decision**:
* **Match found**: Packet proceeds (no drop flag set)
* **No match**: Sets `meta.drop = 1` (mark for discard)
6. **Downstream processing**:
* NIC modules check `drop` flag: Discards packet if set
* Forwarded to host only if table-matched and not dropped

### Key Metadata Fields

* `mc`: Multicast indicator (1 = multicast packet, 0 = unicast/broadcast)
* `drop`: Discard flag (1 = drop packet, 0 = forward)
* **Multicast Address Table**: Exact match table with authorized destination MAC addresses

## Key Concepts

### Early Multicast Filtering

Processing multicast in the ingress pipeline provides:

* **Bandwidth efficiency**: Blocks unwanted traffic before it consumes host/NIC resources
* **Low latency**: Filtering decisions made at line rate (hardware-accelerated)
* **CPU offload**: Reduces host processing of unsubscribed multicast streams

### Decoupled Table Management

The design separates P4 logic from table configuration:

* **P4 Program**: Focuses on high-speed filtering (no IGMP awareness)
* **Host Driver/IGMP**: Manages group memberships and table updates
* **Flexibility**: Supports dynamic group joins/leaves without P4 code changes

### Layer 2 + Layer 3 Identification

Combining MAC and IP checks ensures accurate multicast detection:

* **Layer 2 (MAC)**: Fast prefix match for initial classification
* **Layer 3 (IP)**: Validates multicast intent (prevents MAC spoofing)
* **Robustness**: Reduces false positives from non-multicast traffic

## Production Considerations

A production multicast implementation would typically include:

1. **IPv6 Support**: Extend to IPv6 multicast addresses (`FF00::/8`)
2. **Table Scalability**: Support large numbers of multicast groups (thousands of entries)
3. **Dynamic Updates**: Atomic table updates to avoid traffic disruption
4. **Traffic Policing**: Rate limiting for multicast streams to prevent DoS
5. **Group-Specific QoS**: Prioritize critical multicast traffic (e.g., video conferencing)
6. **Logging**: Track dropped multicast packets for troubleshooting
7. **Security**: Validate multicast IP-MAC mapping to prevent spoofing
8. **IGMP Snooping**: Optional P4-based snooping for enhanced group management

## What's Next?

After understanding basic multicast filtering:

* Extend to support IPv6 multicast addresses and mapping
* Implement multicast traffic shaping in the P4 pipeline
* Add group-specific rate limiting for bandwidth control
* Explore multicast replication (one-to-many forwarding) in P4
