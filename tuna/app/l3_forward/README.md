# L3 Forwarding - IPv4 Layer 3 Routing

## Overview

This example implements IPv4 layer 3 forwarding, enabling communication between hosts in different network segments. The P4 program performs routing by modifying the destination MAC address based on the IPv4 destination address, demonstrating how to implement basic router functionality in the data plane.

Building on the [Ping example](../ping), this exercise introduces table lookups and packet header modification.

## Learning Objectives

By completing this exercise, you will learn:

- **IPv4 Routing**: Implement longest prefix match (LPM) routing tables
- **MAC Address Rewriting**: Modify packet headers based on routing decisions
- **Table Operations**: Use P4 tables with const entries for static routing
- **Gateway Configuration**: Configure routing tables and ARP entries on hosts
- **Cross-Subnet Communication**: Enable hosts in different subnets to communicate

## What You'll Implement

The P4 program implements:

1. **Packet Parsing**: Parse Ethernet and IPv4 headers in both ingress and egress
2. **LPM Routing Table**: Match on IPv4 destination address using longest prefix match
3. **MAC Address Update**: Rewrite destination MAC address based on routing table
4. **Egress Processing**: Apply routing logic in the egress pipeline

## Network Topology

```
Host 1 (192.168.1.3/24)          Host 2 (10.0.1.2/24)
        │                                │
        │                                │
   ┌────┴────┐                      ┌────┴────┐
   │  NIC 1  │──────────────────────│  NIC 2  │
   └─────────┘                      └─────────┘
   Gateway: 192.168.1.10            Gateway: 10.0.1.10
```

**Configuration Details:**

- **Host 1**:
  - IP: 192.168.1.3/24
  - Gateway: 192.168.1.10 (virtual gateway handled by NIC)
  - Gateway MAC: c2:0c:20:4a:23:65

- **Host 2**:
  - IP: 10.0.1.2/24
  - Gateway: 10.0.1.10 (virtual gateway handled by NIC)
  - Gateway MAC: 62:9b:0c:db:ac:20

The NICs act as virtual routers, forwarding packets between the two subnets.

## P4 Program Details

### Key Components

**Action: ipv4_forward**
```c
action ipv4_forward(macAddr_t dstAddr) {
    hdr.ethernet.dstAddr = dstAddr;  // Update destination MAC
}
```

**Table: ipv4_lpm**
```c
table ipv4_lpm {
    key = {
        hdr.ipv4.dstAddr: lpm;  // Longest prefix match on destination IP
    }
    actions = {
        ipv4_forward;
    }
    const entries = {
        (0x0a000102 &&& 0xFFFFFF00) : ipv4_forward(0x629b0cdbac20);  // 10.0.1.0/24
        (0xc0a80103 &&& 0xFFFFFF00) : ipv4_forward(0xc20c204a2365);  // 192.168.1.0/24
    }
    size = 512;
}
```

### Pipeline Structure

**Ingress Pipeline:**
- Parser: Extracts Ethernet and IPv4 headers
- Control: Empty (no processing in ingress)
- Deparser: Emits Ethernet and IPv4 headers

**Egress Pipeline:**
- Parser: Extracts Ethernet and IPv4 headers
- Control: Applies ipv4_lpm table to rewrite destination MAC
- Deparser: Emits modified Ethernet and IPv4 headers

The routing decision is made in the egress pipeline, which is typical for NIC-based P4 programs.

## How to Run

In your shell, run:
```bash
cd tuna/app/l3_forward
make
```
This will:
1. compile `l3_forward.p4`
2. start the topo in Mininet and configure all NIC with the appropriate P4 program + table entries, and configure all hosts with the commands listed in [topology.json](./topology.json)
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
   64 bytes from 10.0.1.2: icmp_seq=1 ttl=64 time=2.31 ms
   64 bytes from 10.0.1.2: icmp_seq=2 ttl=64 time=2.50 ms
   64 bytes from 10.0.1.2: icmp_seq=3 ttl=64 time=1.57 ms

   --- 10.0.1.2 ping statistics ---
   3 packets transmitted, 3 received, 0% packet loss, time 2004ms
   rtt min/avg/max/mdev = 1.570/2.124/2.499/0.400 ms
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

## Understanding the Routing Logic

### Packet Flow from Host 1 to Host 2

1. **Host 1 generates packet**:
   - Src IP: 192.168.1.3, Dst IP: 10.0.1.2
   - Src MAC: Host 2's MAC, Dst MAC: Gateway MAC (c2:0c:20:4a:23:65)

2. **NIC 1 receives packet** (Ingress):
   - Parses headers but no processing

3. **NIC 1 processes packet** (Egress):
   - Looks up 10.0.1.2 in ipv4_lpm table
   - Matches: 10.0.1.0/24 network
   - Action: Updates Dst MAC to 62:9b:0c:db:ac:20

4. **Packet forwarded to NIC 2**

5. **NIC 2 forwards to Host 2**:
   - Host 2 receives packet with correct destination MAC

## Key Concepts

### Longest Prefix Match (LPM)

The routing table uses LPM to match IP addresses:
```c
(0x0a000102 &&& 0xFFFFFF00)  // Matches 10.0.1.0/24 (any IP in 10.0.1.0-10.0.1.255)
(0xc0a80103 &&& 0xFFFFFF00)  // Matches 192.168.1.0/24 (any IP in 192.168.1.0-192.168.1.255)
```

The `&&&` operator specifies the mask for prefix matching.

### Why Custom Routing Tables?

The custom routing tables and policy routing (`ip rule`) ensure traffic destined for the remote subnet goes through the specific network interface with the P4 program, rather than the system's default route.

## What's Next?

After mastering L3 forwarding, explore:

- **[Calculator](../calculator)**: Define custom protocols and perform in-network computations
- **[GRE Tunnel](../tunnel)**: Learn packet encapsulation and tunneling
- **[Firewall](../firewall)**: Add stateless packet filtering
