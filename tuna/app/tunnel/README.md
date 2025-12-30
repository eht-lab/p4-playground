# GRE Tunnel - Packet Encapsulation and Tunneling

## Overview

This example implements Generic Routing Encapsulation (GRE) tunneling, demonstrating how to encapsulate and decapsulate packets to enable communication between private networks over a public network infrastructure. The P4 program performs both GRE encapsulation (in egress) and decapsulation (in ingress).

GRE tunneling is widely used for VPNs, network virtualization, and connecting geographically distributed networks.

## Learning Objectives

By completing this exercise, you will learn:

- **Packet Encapsulation**: Add outer headers to existing packets
- **Packet Decapsulation**: Remove outer headers to extract original packets
- **Multi-Layer Parsing**: Parse nested protocol headers
- **Header Validity**: Use `setValid()` and `setInvalid()` operations
- **Complex Header Manipulation**: Copy and modify multiple header fields
- **Tunneling Protocols**: Understand GRE protocol structure and usage

## What You'll Implement

The P4 program implements bidirectional GRE tunneling:

1. **GRE Encapsulation** (Egress):
   - Match on private IP destination addresses
   - Add GRE header and outer IPv4 header
   - Use public IP addresses for tunnel endpoints

2. **GRE Decapsulation** (Ingress):
   - Match on public IP destination addresses
   - Remove GRE header and outer IPv4 header
   - Forward original packet with private IPs

## GRE Protocol Overview

### GRE Header Structure

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|C|R|K|S|s|Recur|  Flags  | Ver |         Protocol Type         |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

**Field Descriptions:**
- **C, R, K, S**: Flag bits (all 0 in this implementation)
- **Version**: GRE version (0)
- **Protocol Type**: Type of encapsulated protocol (0x0800 for IPv4)

### Packet Structure

**Original Packet:**
```
[Ethernet Header][IPv4 Header - Private IPs][Payload]
```

**After GRE Encapsulation:**
```
[Ethernet Header][IPv4 Header - Public IPs][GRE Header][IPv4 Header - Private IPs][Payload]
```

## Network Topology

```
Private Network 1                           Private Network 2
192.168.1.0/24                              192.168.1.0/24

  Host 1                                      Host 2
192.168.1.3                                 192.168.1.2
    │                                           │
    │                                           │
┌───┴────┐        Public Network            ┌───┴────┐
│ NIC 1  │         10.0.1.0/24              │ NIC 2  │
│10.0.1.3│◄────────────────────────────────►│10.0.1.2│
└────────┘                                  └────────┘
  Tunnel                                      Tunnel
  Endpoint 1                                  Endpoint 2

GRE Encap/Decap                             GRE Encap/Decap
```

**Configuration:**
- **Host 1**: Private IP 192.168.1.3
- **NIC 1**: Tunnel endpoint with public IP 10.0.1.3
- **NIC 2**: Tunnel endpoint with public IP 10.0.1.2
- **Host 2**: Private IP 192.168.1.2

## P4 Program Details

### Headers Definition

```c
struct headers_t {
    ethernet_t   ethernet;      // Ethernet header
    ipv4_t       ipv4;          // Outer IPv4 (for tunneling)
    gre_t        gre;           // GRE header
    ipv4_t       innerIpv4;     // Inner IPv4 (original)
}
```

### GRE Encapsulation (Egress)

**Action: gre_encapsulation**
```c
action gre_encapsulation(ip4Addr_t srcAddr, ip4Addr_t dstAddr) {
    // Create and populate GRE header
    hdr.gre.setValid();
    hdr.gre.protocolType = TYPE_IPV4;

    // Save original IPv4 as inner IPv4
    hdr.innerIpv4.setValid();
    hdr.innerIpv4 = hdr.ipv4;

    // Create new outer IPv4 header with public IPs
    hdr.ipv4.srcAddr = srcAddr;      // Tunnel source (public IP)
    hdr.ipv4.dstAddr = dstAddr;      // Tunnel destination (public IP)
    hdr.ipv4.protocol = PROTOCOL_GRE; // Protocol 47
    hdr.ipv4.totalLen = hdr.innerIpv4.totalLen + 24; // +20B IPv4 +4B GRE
}
```

**Encapsulation Table:**
```c
table gre_encap {
    key = {
        hdr.ipv4.dstAddr: exact;  // Match on private destination IP
    }
    actions = {
        gre_encapsulation;
    }
    const entries = {
        0xc0a80102 : gre_encapsulation(0x0a000103, 0x0a000102);
        //  ^^^--- Private IP (192.168.1.2)
        //                                 ^^^--- Public src (10.0.1.3)
        //                                           ^^^--- Public dst (10.0.1.2)
    }
}
```

### GRE Decapsulation (Ingress)

**Action: gre_decapsulation**
```c
action gre_decapsulation() {
    hdr.ipv4.setInvalid();    // Remove outer IPv4
    hdr.gre.setInvalid();     // Remove GRE header
    // Inner IPv4 becomes the main IPv4 header
}
```

**Decapsulation Table:**
```c
table gre_decap {
    key = {
        hdr.ipv4.dstAddr: exact;  // Match on public destination IP
    }
    actions = {
        gre_decapsulation;
    }
    const entries = {
        0x0a000102 : gre_decapsulation();  // Public IP (10.0.1.2)
        0x0a000103 : gre_decapsulation();  // Public IP (10.0.1.3)
    }
}
```

## Packet Flow Example

### Host 1 to Host 2

**1. Host 1 sends packet:**
```
Ethernet: [Src: Host1_MAC, Dst: NIC1_MAC]
IPv4:     [Src: 192.168.1.3, Dst: 192.168.1.2]
ICMP:     [Echo Request]
```

**2. NIC 1 egress (encapsulation):**
```
Ethernet: [Src: Host1_MAC, Dst: NIC1_MAC]
IPv4:     [Src: 10.0.1.3, Dst: 10.0.1.2]          ← Outer (Public)
GRE:      [Protocol: 0x0800]
IPv4:     [Src: 192.168.1.3, Dst: 192.168.1.2]    ← Inner (Private)
ICMP:     [Echo Request]
```

**3. NIC 2 ingress (decapsulation):**
```
Ethernet: [Src: Host1_MAC, Dst: NIC2_MAC]
IPv4:     [Src: 192.168.1.3, Dst: 192.168.1.2]    ← Original packet restored
ICMP:     [Echo Request]
```

**4. Host 2 receives original packet**

In your shell, run:
```bash
cd tuna/app/tunnel
make
```
This will:
1. compile `tunnel.p4`
2. start the topo in Mininet and configure all NIC with the appropriate P4 program + table entries, and configure all hosts with the commands listed in [topology.json](./topology.json)
3. You should now see a Mininet command prompt. Try to ping between hosts in the topology:
   ```bash
   mininet> h1 ping h2 -c 3
   ```

   You will get:
   ```bash
   mininet> h1 ping h2 -c 3
   PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data.
   64 bytes from 192.168.1.2: icmp_seq=1 ttl=64 time=11.5 ms
   64 bytes from 192.168.1.2: icmp_seq=2 ttl=64 time=1.95 ms
   64 bytes from 192.168.1.2: icmp_seq=3 ttl=64 time=2.10 ms

   --- 192.168.1.2 ping statistics ---
   3 packets transmitted, 3 received, 0% packet loss, time 2002ms
   rtt min/avg/max/mdev = 1.948/5.197/11.545/4.488 ms
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

**Success Criteria:**
- Hosts with private IPs can ping each other through the GRE tunnel
- Encapsulation adds GRE and outer IPv4 headers correctly
- Decapsulation removes tunnel headers and restores original packets
- Bidirectional communication works seamlessly

**Example Output:**
```
# From Host 1
PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data.
64 bytes from 192.168.1.2: icmp_seq=1 ttl=64 time=11.5 ms
64 bytes from 192.168.1.2: icmp_seq=2 ttl=64 time=1.95 ms
64 bytes from 192.168.1.2: icmp_seq=3 ttl=64 time=2.10 ms

--- 192.168.1.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
```

**Packet Capture Analysis:**
  - Host 1 send packet to NIC 1
  ![Alt text](image-1.png)
  - packet processing in NIC 1 egress(GRE encap)
  ![Alt text](image-2.png)![Alt text](image-3.png)
  - NIC 1 send packet to NIC 2
  ![Alt text](image-4.png)
  - packet processing in NIC 2 ingress(GRE decap)
  ![Alt text](image-5.png)![Alt text](image-6.png)
  - NIC 2 send packet to Host 2
  ![Alt text](image-7.png)

## Understanding the Implementation

### Why Encapsulate in Egress?

Encapsulation happens in the egress pipeline because:
- The packet is leaving the source network
- We need to add outer headers before transmission
- The egress pipeline is the last point to modify packets

### Why Decapsulate in Ingress?

Decapsulation happens in the ingress pipeline because:
- The packet just arrived from the tunnel
- We need to remove outer headers before routing
- The ingress pipeline is the first point to process received packets

### Header Length Calculation

When encapsulating, the outer IPv4 total length must be updated:
```c
hdr.ipv4.totalLen = hdr.innerIpv4.totalLen + 24;
//                  ^^^^^^^^^^^^^^^^^^^^^^^^   ^^
//                  Original packet length     IPv4(20B) + GRE(4B)
```

## Key Concepts

### Tunneling Use Cases

1. **VPN**: Connect remote sites securely over the Internet
2. **Network Virtualization**: Overlay virtual networks on physical infrastructure
3. **Protocol Translation**: Carry non-IP protocols over IP networks
4. **Traffic Engineering**: Route traffic through specific paths

### GRE vs Other Tunneling Protocols

- **GRE**: Simple, no encryption, protocol-agnostic
- **IPsec**: Encrypted, more complex, security-focused
- **VXLAN**: Layer 2 over Layer 3, network virtualization
- **GUE**: Generic UDP Encapsulation, UDP-based

## Advanced Topics

### Extending the Implementation

Consider adding:
- **Dynamic tunnel configuration**: Use control plane instead of const entries
- **Checksum calculation**: Compute IPv4 checksums for outer headers
- **TTL handling**: Decrement TTL in inner headers
- **MTU considerations**: Handle fragmentation for oversized packets
- **GRE key support**: Add key fields for multi-tenant scenarios

## What's Next?

After mastering GRE tunneling, explore:

- **[Firewall](../firewall)**: Add security with stateless packet filtering
- Try implementing other tunneling protocols (VXLAN, IPinIP)
- Add encryption to the tunnel (requires external libraries)
