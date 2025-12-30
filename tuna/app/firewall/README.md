# Firewall - Stateless Packet Filtering

## Overview

This example implements a basic stateless firewall using P4, demonstrating packet filtering based on source MAC addresses. The firewall maintains a blacklist table and drops packets from blocked sources, while allowing all other traffic to pass through.

This example introduces security concepts in P4 programming and shows how to implement access control in the data plane.

## Learning Objectives

By completing this exercise, you will learn:

- **Packet Filtering**: Drop or allow packets based on matching criteria
- **Blacklist Implementation**: Maintain a list of blocked entities
- **Drop Action**: Use the drop metadata to discard packets
- **Security in Data Plane**: Implement firewall logic at line rate
- **Exact Match Tables**: Use exact match for MAC address filtering

## What You'll Implement

The P4 program implements a simple firewall that:

1. **Matches source MAC addresses**: Uses exact match on Ethernet source address
2. **Drops blacklisted traffic**: Sets drop flag for blocked sources
3. **Allows other traffic**: Passes through packets not in blacklist
4. **Operates in ingress**: Filters packets as early as possible

## Firewall Concepts

### Stateful vs Stateless Firewall

This is a **stateless firewall** that:
- Makes decisions based on individual packets
- Does not track connection state
- Simple and fast, suitable for basic filtering

A **stateful firewall** would:
- Track TCP connection states
- Allow return traffic for established connections
- Require more complex logic and memory

### Blacklist vs Whitelist

This implementation uses a **blacklist** approach:
- Block specific sources explicitly listed
- Allow everything else by default

A **whitelist** approach would:
- Allow only specific sources explicitly listed
- Block everything else by default
- Generally more secure but requires careful configuration

## Network Topology

```
    Host 1                   Host 2                    Host 3
10.0.1.1/24              10.0.1.2/24               10.0.1.3/24
MAC: c2:0c:20:4a:23:65   MAC: 62:9b:0c:db:ac:20   MAC: 08:00:00:00:01:03
      │                        │                        │
      │ p1                     │ p1                     │ p1
  ┌───┴────┐               ┌───┴────┐               ┌───┴────┐
  │ NIC 1  │               │ NIC 2  │               │ NIC 3  │
  │Blocked H2              │        │               │Blocked H2
  └───┬────┘               └───┬────┘               └───┬────┘
      │ p0                     │ p0                     │ p0
      │                     p1 │                        │
      │          p0┌───────────┴──────────┐p2           │
      └────────────│        Bridge        │─────────────┘
                   └──────────────────────┘

Firewall P4 Program runs on all NICs (n1, n2, n3)
```

**Configuration:**
- **Host 1, Host 2**: Normal hosts, can communicate freely
- **Host 3**: MAC address 62:9b:0c:db:ac:20 is blacklisted
- **Bridge**: Connects all NICs together
- **All NICs**: Run the firewall P4 program

## P4 Program Details

### Drop Action

```c
action drop() {
    ostd.drop = 1;  // Set drop flag in output metadata
}
```

The drop action sets a flag in the output metadata, telling the TUNA architecture to discard the packet instead of forwarding it.

### Blacklist Table

```c
table blacklist {
    key = {
        hdr.ethernet.srcAddr: exact;  // Exact match on source MAC
    }
    actions = {
        drop;
    }
    const entries = {
        0x629b0cdbac20 : drop();  // Block this specific MAC address
    }
    size = 1024;  // Can hold up to 1024 blacklist entries
}
```

**Key Points:**
- Uses **exact match** for precise MAC address filtering
- **Const entries** define static blacklist at compile time
- **Size 1024** allows for a large blacklist
- Only packets matching blacklist entries are dropped

### Pipeline Structure

**Ingress Pipeline:**
- Parser: Extracts Ethernet and IPv4 headers
- Control: Applies blacklist table, sets drop flag if matched
- Deparser: Emits headers (even if packet will be dropped)

**Egress Pipeline:**
- Parser: Extracts Ethernet and IPv4 headers
- Control: Empty (no processing)
- Deparser: Emits headers

Filtering in ingress is efficient as it prevents blocked packets from consuming resources in later pipeline stages.

## How to Run

In your shell, run:
```bash
cd tuna/app/firewall
make
```
This will:
1. compile `firewall.p4`
2. start the topo in Mininet and configure all NIC with the appropriate P4 program + table entries, and configure all hosts with the commands listed in [topology.json](./topology.json)
3. You should now see a Mininet command prompt. Try to ping between hosts in the topology:
   ```bash
   mininet> h1 ping h2 -c 3
   mininet> h1 ping h3 -c 3
   mininet> h2 ping h3 -c 3
   mininet> pingall
   ```

   You will get:
   ```bash
   mininet> h1 ping h2 -c 3
   PING 10.0.1.2 (10.0.1.2) 56(84) bytes of data.

   --- 10.0.1.2 ping statistics ---
   3 packets transmitted, 0 received, 100% packet loss, time 1999ms

   mininet> h1 ping h3 -c 3
   PING 10.0.1.3 (10.0.1.3) 56(84) bytes of data.
   64 bytes from 10.0.1.3: icmp_seq=1 ttl=64 time=1.91 ms
   64 bytes from 10.0.1.3: icmp_seq=2 ttl=64 time=1.82 ms
   64 bytes from 10.0.1.3: icmp_seq=3 ttl=64 time=1.69 ms

   --- 10.0.1.3 ping statistics ---
   3 packets transmitted, 3 received, 0% packet loss, time 2003ms
   rtt min/avg/max/mdev = 1.685/1.803/1.905/0.090 ms
   mininet> h2 ping h3 -c 3
   PING 10.0.1.3 (10.0.1.3) 56(84) bytes of data.

   --- 10.0.1.3 ping statistics ---
   3 packets transmitted, 0 received, 100% packet loss, time 2000ms

   mininet> pingall
   *** Ping: testing ping reachability
   h1 -> X h3 
   h2 -> X X 
   h3 -> h1 X 
   *** Results: 66% dropped (2/6 received)
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

### Successful Cases

**Host 1 ↔ Host 3:**
```
# From Host 1
PING 10.0.1.3 (10.0.1.3) 56(84) bytes of data.
64 bytes from 10.0.1.3: icmp_seq=1 ttl=64 time=1.91 ms
64 bytes from 10.0.1.3: icmp_seq=2 ttl=64 time=1.82 ms
64 bytes from 10.0.1.3: icmp_seq=3 ttl=64 time=1.69 ms

--- 10.0.1.3 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
```

### Blocked Cases

**Host 2 → Any Host:**
```
# From Host 2 (blocked)
PING 10.0.1.2 (10.0.1.2) 56(84) bytes of data.

--- 10.0.1.2 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 1999ms
```

Packets from Host 2 are silently dropped by the firewall.

## Understanding the Filtering Logic

### Packet Processing Flow

1. **Packet arrives at NIC ingress**
2. **Parser extracts headers** (Ethernet, IPv4)
3. **Blacklist table lookup**:
   - Key: Source MAC address
   - If match: Execute `drop()` action → `ostd.drop = 1`
   - If no match: No action (packet continues)
4. **Deparser emits headers**
5. **TUNA architecture checks drop flag**:
   - If `drop = 1`: Discard packet
   - If `drop = 0`: Forward packet

### Why Drop in Ingress?

Dropping packets in ingress is efficient because:
- **Early filtering**: Blocked packets don't consume downstream resources
- **Bandwidth saving**: No need to forward blocked packets to egress
- **Security**: Prevents malicious packets from reaching sensitive stages

## Key Concepts

### MAC Address Filtering

This firewall filters by MAC address (Layer 2):
- **Pros**: Simple, fast lookup
- **Cons**:
  - MAC addresses can be spoofed
  - Only works within same broadcast domain
  - Not suitable for routed networks

### Production Firewall Considerations

A production firewall would typically include:

1. **IP-based filtering**: Filter by source/destination IP addresses
2. **Port-based filtering**: Block specific TCP/UDP ports
3. **Protocol filtering**: Allow only specific protocols (TCP, UDP, ICMP)
4. **Stateful tracking**: Track connection states (NEW, ESTABLISHED, RELATED)
5. **Rate limiting**: Prevent DoS attacks
6. **Logging**: Record dropped packets for security analysis
7. **Dynamic updates**: Control plane for runtime rule updates

## Extending the Firewall

### Add IP-based Filtering

```c
table ip_blacklist {
    key = {
        hdr.ipv4.srcAddr: exact;
    }
    actions = {
        drop;
    }
}
```

### Add Port-based Filtering

```c
// Requires TCP/UDP header parsing
table port_filter {
    key = {
        hdr.tcp.dstPort: exact;
    }
    actions = {
        drop;
    }
}
```

### Add Stateful Connection Tracking

```c
// Requires registers to store connection state
register<bit<1>>(1024) connection_state;

// Check if connection is established before allowing
```

### Add Logging

```c
// Use digests to send dropped packet info to control plane
action drop_and_log() {
    ostd.drop = 1;
    // Send digest with packet info
}
```

## What's Next?

After understanding basic firewall implementation:

- **[ECN](../ecn)**: Allow end-to-end notification of network congestion without dropping packets
- Try adding IP-based filtering rules
- Implement a whitelist instead of blacklist
- Add TCP/UDP header parsing and port filtering
- Explore stateful connection tracking with registers
- Review the [Ping](../ping) example to understand basic forwarding
- Compare with [L3 Forwarding](../l3_forward) which modifies packets instead of dropping them

## Security Considerations

### Limitations of This Implementation

1. **MAC spoofing**: Attackers can change their MAC address
2. **No encryption**: Packets are not encrypted
3. **No authentication**: No verification of packet authenticity
4. **Static rules**: Cannot adapt to new threats
5. **Limited logging**: No audit trail

### Best Practices

1. **Defense in depth**: Combine with other security measures
2. **Least privilege**: Start with deny-all, allow only necessary traffic
3. **Regular updates**: Keep blacklist current
4. **Monitor traffic**: Log and analyze dropped packets
5. **Test thoroughly**: Verify firewall doesn't block legitimate traffic
