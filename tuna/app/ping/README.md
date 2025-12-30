# Ping - Basic Packet Forwarding

## Overview

This is the most basic P4 example for TUNA architecture, demonstrating fundamental packet reception, processing, and transmission capabilities. The program implements a simple pass-through packet forwarder that enables hosts in the same network segment to communicate via ping.

This example serves as your first hands-on experience with TUNA P4 programming and helps you understand the basic structure of a P4 program.

## Learning Objectives

By completing this exercise, you will learn:

- **TUNA Architecture Basics**: Understand the ingress and egress pipeline structure
- **Packet Parsing**: How to parse Ethernet and IPv4 headers
- **Packet Deparsing**: How to reconstruct packets after processing
- **Minimal P4 Program**: The minimum components required for a working P4 program
- **Simulator Testing**: How to test P4 programs using topology files in simulation environment

## What You'll Implement

This example provides a complete skeleton P4 program that:

1. **Parses packets**: Extracts Ethernet headers in ingress, Ethernet and IPv4 headers in egress
2. **No processing**: Implements empty control blocks (packets pass through unchanged)
3. **Deparses packets**: Reconstructs packets with parsed headers
4. **Basic forwarding**: Packets are forwarded through the NIC without modification

## P4 Program Details

### Headers

The program defines standard Ethernet and IPv4 headers:

```c
header ethernet_t {
    macAddr_t dstAddr;   // Destination MAC address
    macAddr_t srcAddr;   // Source MAC address
    bit<16>   etherType; // Ethernet type
}

header ipv4_t {
    // Standard IPv4 header fields
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    // ... other fields
}
```

### Pipeline Structure

**Ingress Pipeline:**
- Parser: Extracts Ethernet header only
- Control: Empty (no processing)
- Deparser: Emits Ethernet header

**Egress Pipeline:**
- Parser: Extracts Ethernet and IPv4 headers based on EtherType
- Control: Empty (no processing)
- Deparser: Emits Ethernet and IPv4 headers

This asymmetric parsing demonstrates TUNA's flexibility in handling packets differently in ingress and egress stages.

## Network Topology

This example supports three different topology configurations for testing:

### Topology 1: Two NICs Direct Connection (topology1.json)

```
Host1 ─── NIC1 ─── NIC2 ─── Host2
```

The simplest setup with two hosts directly connected through two NICs.

### Topology 2: Three NICs with Bridge (topology2.json)

```
Host1 ─── NIC1 ───
                  │
Host2 ─── NIC2 ─────── Linux Bridge
                  │
Host3 ─── NIC3 ───
```

Three hosts connected through a Linux bridge, demonstrating multi-host communication.

### Topology 3: Four NICs with Two Bridges (topology3.json)

```
Host1 ─── NIC1 ───                          ─── Host3 ─── NIC3
                  │── Bridge1 ── Bridge2 ──│
Host2 ─── NIC2 ───                          ─── Host4 ─── NIC4
```

More complex setup with four hosts and two interconnected bridges.

## How to Run

In your shell, run:
```bash
cd tuna/app/ping
make
```
This will:
1. compile `ping.p4`
2. start the topo in Mininet and configure all NIC with the appropriate P4 program + table entries, and configure all hosts with the commands listed in [topology1.json](./topology1.json)
3. You should now see a Mininet command prompt. Try to ping between hosts in the topology:
   ```bash
   mininet> pingall
   mininet> h1 ping h2 -c 3
   ```

   You will get:
   ```bash
   mininet> pingall
   *** Ping: testing ping reachability
   h1 -> h2
   h2 -> h1
   *** Results: 0% dropped (2/2 received)
   mininet> h1 ping h2 -c 3
   PING 10.0.1.2 (10.0.1.2) 56(84) bytes of data.
   64 bytes from 10.0.1.2: icmp_seq=1 ttl=64 time=1.86 ms
   64 bytes from 10.0.1.2: icmp_seq=2 ttl=64 time=1.65 ms
   64 bytes from 10.0.1.2: icmp_seq=3 ttl=64 time=1.70 ms

   --- 10.0.1.2 ping statistics ---
   3 packets transmitted, 3 received, 0% packet loss, time 2003ms
   rtt min/avg/max/mdev = 1.647/1.734/1.857/0.089 ms
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

**Run with Specific Topology**

Choose one of the topologies and run:

```bash
# For topology 1 (2 NICs), this is the default topology
make TOPO=topology1.json

# For topology 2 (3 NICs with bridge)
make TOPO=topology2.json

# For topology 3 (4 NICs with 2 bridges)
make TOPO=topology3.json
```

## What's Next?

After mastering this basic example, progress to:

- **[L3 Forwarding](../l3_forward)**: Add routing logic to forward packets between different subnets
- **[Calculator](../calculator)**: Learn to define custom protocols and perform computations
- **[GRE Tunnel](../tunnel)**: Implement packet encapsulation and tunneling
