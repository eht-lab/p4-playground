# RSS - Receive Side Scaling

## Overview

This example implements the Receive Side Scaling (RSS) feature on a smart NIC using P4, focusing on efficient traffic distribution across multiple CPU cores. The P4 program processes IPv4 packets in the ingress pipeline: it checks the protocol field, performs four-tuple hash calculation for UDP packets, and two-tuple hash calculation for other packet types. The resulting hash value is mapped to an output queue ID, which is stored in the `dst_qid` field of the output metadata. Subsequent mapping from this logical queue ID to a global queue ID for CPU cores is handled by other NIC modules, demonstrating how P4 enables hardware-accelerated traffic distribution in smart NICs.

This example introduces load balancing concepts in data plane programming and shows how to implement efficient packet distribution at line rate.

## Learning Objectives

By completing this exercise, you will learn:

* **RSS Fundamentals**: Understand Receive Side Scaling for multi-core processing
* **Hash Calculation**: Implement four-tuple and two-tuple hash computations
* **Traffic Distribution**: Map hash values to logical queue IDs
* **Metadata Usage**: Pass queue information through output metadata
* **Smart NIC Workflow**: Integrate P4 logic with NIC hardware modules

## What You'll Implement

The P4 program implements RSS functionality that:

1. **Processes IPv4 packets**: Focuses on IPv4 traffic in the ingress pipeline
2. **Protocol-aware hashing**:
* Uses four-tuple (src IP, dst IP, src port, dst port) for UDP
* Uses two-tuple (src IP, dst IP) for other protocols
1. **Queue mapping**: Converts hash values to logical queue IDs
2. **Metadata propagation**: Stores queue ID in `dst_qid` output metadata
3. **NIC integration**: Enables further processing by other NIC modules

## RSS Concepts

### What is RSS?

Receive Side Scaling (RSS) is a network technology that:

* Distributes incoming network traffic across multiple CPU cores
* Prevents single-core bottlenecks in high-speed networks
* Improves overall system throughput and latency
* Uses hash-based distribution for consistent packet ordering per flow

### Traditional vs. RSS Processing

**Traditional Processing**:

* All packets arrive at a single CPU core
* Creates bottlenecks at high data rates
* Inefficient use of multi-core processors

**RSS Processing**:

* Packets distributed across multiple CPU cores
* Load balanced based on flow characteristics
* Better utilization of available processing resources
* Maintains flow integrity (packets of same flow go to same core)

### Hash Tuples Explained

* **Four-tuple hash** (UDP): Uses source IP, destination IP, source port, destination port
  * Provides finer granularity for port-based protocols
  * Better distribution for UDP traffic with many flows

* **Two-tuple hash** (other protocols): Uses source IP and destination IP
  * Efficient for protocols without port information
  * Maintains flow consistency for non-UDP traffic

## Network Topology

```
    Host 1                   Host 2                    Host 3
10.0.1.1/24              10.0.1.2/24               10.0.1.3/24
MAC: c2:0c:20:4a:23:65   MAC: 62:9b:0c:db:ac:20   MAC: 08:00:00:00:01:03
      │                        │                        │
      │ p1                     │ p1                     │ p1
  ┌───┴────┐               ┌───┴────┐               ┌───┴────┐
  │ NIC 1  │               │ NIC 2  │               │ NIC 3  │
  └───┬────┘               └───┬────┘               └───┬────┘
      │ p0                     │ p0                     │ p0
      │                     p1 │                        │
      │          p0┌───────────┴──────────┐p2           │
      └────────────│        Bridge        │─────────────┘
                   └──────────────────────┘

Firewall P4 Program runs on all NICs (n1, n2, n3)
NIC 1 receives packets, set meta.dst_qid of packet from Host 2 as 1, set meta.dst_qid of packet from Host 3 as 2
```

**Configuration:**

* **Smart NIC**: Runs P4 program implementing RSS logic
* **CPU Cores**: Multiple cores to process distributed traffic
* **Traffic Types**: Mixed IPv4 traffic including UDP and other protocols
* **NIC Modules**: Additional hardware components that map logical queue IDs to CPU cores

## P4 Program Details

### Headers Definition

```c
header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length;
    bit<16> checksum;
}

struct headers_t {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    udp_t        udp;
}
```

### User Metadata Definition

```c
struct metadata_t {
    bit<32> hash_value;
}
```

### Parser Logic

```c
state parse_ipv4 {
    pkt.extract(hdr.ipv4);
    transition select(hdr.ipv4.protocol) {
        PROTOCOL_UDP: parse_udp;
        default: accept;
    }
}

state parse_udp {
    pkt.extract(hdr.udp);
    transition accept;
}
```

### Define Hash Instance

```c
Hash<bit<32>>(HashAlgorithm.toeplitz) my_hash;
```

### Actions: Calculate hash

```c
action calc_udp_hash() {
    // calculate four-tuple hash for udp
    user_meta.hash_value = my_hash.get_hash(
        {hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.udp.srcPort, hdr.udp.dstPort});
}

action calc_ipv4_hash() {
    // calculate two-tuple hash for ipv4 default
    user_meta.hash_value = my_hash.get_hash(
        {hdr.ipv4.srcAddr, hdr.ipv4.dstAddr});
}
```

### hash_calc Table

```c
table hash_calc {
    key = {
        hdr.ipv4.protocol: exact;
    }
    actions = {
        calc_udp_hash;
        calc_ipv4_hash;
    }
    default_action = calc_ipv4_hash();
    const entries = {
        PROTOCOL_UDP : calc_udp_hash();
    }
    size = 32;
}
```

### Actions: set Queue id to output metadata

```c
action get_dst_qid(bit<8> qid) {
    ostd.dst_qid = (bit<14>)(qid);
}

action get_default_qid() {
    ostd.dst_qid = 0;
}
```

### rss Table

```c
table rss {
    key = {
        user_meta.hash_value: ternary;
    }
    actions = {
        get_dst_qid;
        get_default_qid;
    }
    default_action = get_default_qid();
    const entries = {  // match hash value LSB 8bit to logic qid
        0x57 &&& 0xFF : get_dst_qid(1);
        0x36 &&& 0xFF : get_dst_qid(2);
    }
    size = 256;
}
```

Control applies hash_calc and rss tables to set dst_qid in output metadata during the ingress pipeline

### Pipeline Structure

**Ingress Pipeline**:

* Parser: Extracts Ethernet and IPv4 headers, identifies protocol field
* Control:
  * Checks if protocol is UDP
  * Performs appropriate hash calculation (four-tuple or two-tuple)
  * Maps hash value to logical queue ID
  * Stores queue ID in `dst_qid` metadata
* Deparser: Reassembles and emits headers

**Egress Pipeline**:

* Minimal processing (no RSS-specific logic)

RSS processing in ingress ensures traffic distribution decisions are made as early as possible, optimizing latency.

## How to Run

In your shell, run:
```bash
cd tuna/app/rss
make
```
This will:
1. compile `rss.p4`
2. start the topo in Mininet and configure all NIC with the appropriate P4 program + table entries, and configure all hosts with the commands listed in [topology.json](./topology.json)
3. You should now see a Mininet command prompt. Try to ping between hosts in the topology:
   ```bash
   mininet> h1 python3 recv.py bmv2 &
   mininet> h2 python3 send.py bmv2 10.0.1.1 5
   mininet> h3 python3 send.py bmv2 10.0.1.1 5
   ```

   You will get:
   ```bash
   mininet> h1 python3 recv.py bmv2 &
   mininet> h2 python3 send.py bmv2 10.0.1.1 5
   ###[ Ethernet ]### 
     dst       = c2:0c:20:4a:23:65
     src       = 62:9b:0c:db:ac:20
     type      = IPv4
   ###[ IP ]### 
        version   = 4
        ihl       = 5
        tos       = 0x0
        len       = 39
        id        = 1
        flags     = 
        frag      = 0
        ttl       = 64
        proto     = udp
        chksum    = 0x64c3
        src       = 10.0.1.2
        dst       = 10.0.1.1
        \options   \
   ###[ UDP ]### 
           sport     = 1234
           dport     = 4321
           len       = 19
           chksum    = 0xf610
   ###[ Raw ]### 
              load      = 'P4 rss test'

   .
   Sent 1 packets.
   .
   Sent 1 packets.
   .
   Sent 1 packets.
   .
   Sent 1 packets.
   .
   Sent 1 packets.
   mininet> h3 python3 send.py bmv2 10.0.1.1 5
   ###[ Ethernet ]### 
     dst       = c2:0c:20:4a:23:65
     src       = 08:00:00:00:01:03
     type      = IPv4
   ###[ IP ]### 
        version   = 4
        ihl       = 5
        tos       = 0x0
        len       = 39
        id        = 1
        flags     = 
        frag      = 0
        ttl       = 64
        proto     = udp
        chksum    = 0x64c2
        src       = 10.0.1.3
        dst       = 10.0.1.1
        \options   \
   ###[ UDP ]### 
           sport     = 1234
           dport     = 4321
           len       = 19
           chksum    = 0xf60f
   ###[ Raw ]### 
              load      = 'P4 rss test'

   .
   Sent 1 packets.
   .
   Sent 1 packets.
   .
   Sent 1 packets.
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

- You will find that the two messages "`tuna_ingress_output_metadata.dst_qid: 1`" and "`tuna_ingress_output_metadata.dst_qid: 2`" are each printed five times in the ./logs/n1.log

## Understanding the RSS Logic

### Packet Processing Flow

1. **Packet arrives at smart NIC ingress**
2. **Parser extracts headers**: Identifies Ethernet and IPv4 headers, extracts protocol field
3. **Protocol detection**:
* If UDP (protocol 17), perform four-tuple hash
* For other protocols, perform two-tuple hash
4. **Hash computation**: Calculates hash value from selected tuple fields
5. **Queue mapping**: Converts hash value to logical queue ID using lookup table
6. **Metadata update**: Stores queue ID in `dst_qid` output metadata
7. **Subsequent processing**:
* NIC hardware reads `dst_qid` from metadata
* Maps logical queue ID to global queue ID
* Delivers packet to appropriate CPU core

### Why Different Hash Types?

Using protocol-specific hash tuples provides:

* **Efficiency**: Avoids unnecessary field extraction for non-UDP protocols
* **Accuracy**: Uses port information when available for better distribution
* **Compatibility**: Works with both port-based and non-port-based protocols
* **Consistency**: Maintains flow affinity across different protocol types

## Key Concepts

### Flow Affinity

A critical aspect of RSS is maintaining "flow affinity":

* Packets belonging to the same flow always go to the same CPU core
* Ensures in-order processing for each flow
* Simplifies stateful processing at the application layer
* Achieved through consistent hash calculation and mapping

### Hash Distribution

The effectiveness of RSS depends on:

* **Hash quality**: Uniform distribution across possible values
* **Mapping function**: Even spread of hash values to CPU cores
* **Tuple selection**: Appropriate fields for different protocol types
* **Scalability**: Ability to handle increasing numbers of CPU cores

## Production Considerations

A production RSS implementation would typically include:

1. **Multi-protocol Support**: Extend beyond IPv4 to IPv6, TCP, etc.
2. **Configurable Hash Functions**: Allow selection of hash algorithms (Toeplitz, CRC32)
3. **Dynamic Mapping**: Adjust queue-to-core mapping without reconfiguring P4
4. **Hash Configuration**: Let users select which fields to include in hashing
5. **Load Monitoring**: Track core utilization and rebalance if needed
6. **Large Receive Offload (LRO)**: Integrate with packet aggregation
7. **Security**: Prevent hash manipulation attacks

## What's Next?

After understanding basic RSS implementation:

* [QOS](../qos): Integrate with quality of service mechanisms
* Extend to support TCP and other transport protocols
* Add IPv6 support with extended tuple fields
* Implement configurable hash functions in P4
* Add flow table support for dynamic mapping adjustments
* Explore how RSS interacts with other smart NIC features like checksum offload
