# ECN - Explicit Congestion Notification

## Overview

This example implements basic Explicit Congestion Notification (ECN) functionality using P4, focusing on the data plane's role in handling ECN markings. The P4 program extracts the 2-bit ECN field from IPv4 headers and passes it to output metadata during the ingress pipeline. Functions like queue threshold monitoring and Congestion Notification Packet (CNP) generation are handled by the bmv2 switch and Linux protocol stack, demonstrating how data plane programming integrates with system-level components for congestion management.

This example introduces network congestion control concepts in P4 programming and shows how to implement ECN field processing at line rate.

## Learning Objectives

By completing this exercise, you will learn:

* **ECN Field Handling**: Extract and propagate ECN markings from IPv4 headers
* **Metadata Communication**: Pass packet information between data plane and switch/protocol stack
* **Data Plane-Stack Integration**: How P4 programs interact with switch hardware and OS protocol stacks
* **Congestion Signaling**: Basics of explicit congestion notification vs. packet dropping
* **IPv4 Header Processing**: Work with IPv4 header fields in P4 pipelines

## What You'll Implement

The P4 program implements ECN field processing that:

1. **Parses IPv4 headers**: Extracts the ECN field from IPv4 packets
2. **Processes in ingress**: Handles ECN information in the pipeline
3. **Propagates ECN metadata**: Copies the 2-bit ECN value to output metadata
4. **Integrates with system components**: Enables bmv2 and Linux to handle congestion decisions

## ECN Concepts

### ECN vs. Traditional Congestion Control

Traditional congestion control relies on **packet dropping** to signal congestion, which:

* Wastes network resources (packets already transmitted)
* Causes retransmissions and latency
* Reduces throughput in high-congestion scenarios

ECN provides a more efficient alternative by:

* **Marking packets** instead of dropping them
* Enabling end-to-end congestion signaling
* Maintaining throughput during moderate congestion
* Reducing retransmissions and latency

### ECN Field Details

The ECN functionality uses 2 bits in the IPv4 Type of Service (ToS) field:

| ECN Value | Meaning                                           |
| --------- | ------------------------------------------------- |
| 00        | Not ECN-Capable Transport (ECT)                   |
| 01        | ECT(1) - Endpoint can use ECN                     |
| 10        | ECT(0) - Endpoint can use ECT                     |
| 11        | Congestion Experienced (CE) - Congestion detected |

### End-to-End ECN Operation

1. **Sender**: Marks packets with ECT(0) or ECT(1) indicating ECN capability
2. **Intermediate node**: Sets CE bit when congestion is detected
3. **Receiver**: Notifies sender of CE-marked packets via CNP
4. **Sender**: Reduces transmission rate upon receiving CNP

## Network Topology

```
Host 1 (192.168.1.3/24)          Host 2 (10.0.1.2/24)
        │                                │
        │                                │
   ┌────┴────┐send.py        recv.py┌────┴────┐
   │  NIC 1  │──────────────────────│  NIC 2  │
   └─────────┘iperf                 └─────────┘
   Gateway: 192.168.1.10            Gateway: 10.0.1.10
```

**Configuration:**

* **Host 1**: ECN-capable sender, marks packets with ECT(0)
* **Host 2**: ECN-capable receiver, generates CNPs when CE is detected
* **Switch**: Runs P4 program for ECN field processing, uses bmv2 for congestion detection
* **Traffic**: Simulated high-bandwidth flow from Host 1 to Host 2 to trigger congestion

## P4 Program Details

### Control

```c
apply { 
    ostd.ecn = hdr.ipv4.ecn;
}
```

Control passes the 2-bit ECN field from IPv4 header to output metadata during the ingress pipeline

### Pipeline Structure

**Ingress Pipeline:**

* Parser: Extracts Ethernet and IPv4 headers
* Control: Copies ECN 2-bit value from IPv4 header to output metadata
* Deparser: Emits Ethernet and IPv4 headers

**Egress Pipeline:**

* Parser: Extracts Ethernet and IPv4 headers
* Control: Empty
* Deparser: Emits Ethernet and IPv4 headers

ECN processing in ingress ensures congestion-related information is available for congestion decisions.

## How to Run

In your shell, run:
```bash
cd tuna/app/ecn
make
```
This will:
1. compile `ecn.p4`
2. start the topo in Mininet and configure all NIC with the appropriate P4 program + table entries, and configure all hosts with the commands listed in [topology.json](./topology.json)
3. You should now see a Mininet command prompt. Try to ping between hosts in the topology:
   ```bash
   mininet> h2 python3 recv.py bmv2 &
   mininet> h1 python3 send.py bmv2 10.0.1.2 10 &
   mininet> h2 iperf -s -u &
   mininet> h1 iperf -c 10.0.1.2 -t 3 -u -b 50m
   ```

   You will get:
   ```bash
   mininet> h2 python3 recv.py bmv2 &
   mininet> h1 python3 send.py bmv2 10.0.1.2 10 &
   mininet> h2 iperf -s -u &
   sniffing on eth0
   ###[ Ethernet ]### 
     dst       = 62:9b:0c:db:ac:20
     src       = c2:0c:20:4a:23:65
     type      = IPv4
   ###[ IP ]### 
        version   = 4
        ihl       = 5
        tos       = 0x1
        len       = 39
        id        = 1
        flags     = 
        frag      = 0
        ttl       = 64
        proto     = udp
        chksum    = 0x64c2
        src       = 10.0.1.1
        dst       = 10.0.1.2
        \options   \
   ###[ UDP ]### 
           sport     = domain
           dport     = 4321
           len       = 19
           chksum    = 0xac0
   ###[ Raw ]### 
              load      = 'P4 ecn test'

   ###[ Ethernet ]### 
     dst       = 62:9b:0c:db:ac:20
     src       = c2:0c:20:4a:23:65
     type      = IPv4
   ###[ IP ]### 
        version   = 4
        ihl       = 5
        tos       = 0x1
        len       = 39
        id        = 1
        flags     = 
        frag      = 0
        ttl       = 64
        proto     = udp
        chksum    = 0x64c2
        src       = 10.0.1.1
        dst       = 10.0.1.2
        \options   \
   ###[ UDP ]### 
           sport     = domain
           dport     = 4321
           len       = 19
           chksum    = 0xac0
   ###[ Raw ]### 
              load      = 'P4 ecn test'

   ###[ Ethernet ]### 
     dst       = 62:9b:0c:db:ac:20
     src       = c2:0c:20:4a:23:65
     type      = IPv4
   ###[ IP ]### 
        version   = 4
        ihl       = 5
        tos       = 0x1
        len       = 39
        id        = 1
        flags     = 
        frag      = 0
        ttl       = 64
        proto     = udp
        chksum    = 0x64c2
        src       = 10.0.1.1
        dst       = 10.0.1.2
        \options   \
   ###[ UDP ]### 
           sport     = domain
           dport     = 4321
           len       = 19
           chksum    = 0xac0
   ###[ Raw ]### 
              load      = 'P4 ecn test'

   ------------------------------------------------------------
   Server listening on UDP port 5001
   UDP buffer size:  208 KByte (default)
   ------------------------------------------------------------
   mininet> h1 iperf -c 10.0.1.2 -t 3 -u -b 50m
   ###[ Ethernet ]### 
     dst       = 62:9b:0c:db:ac:20
     src       = c2:0c:20:4a:23:65
     type      = IPv4
   ###[ IP ]### 
        version   = 4
        ihl       = 5
        tos       = 0x1
        len       = 39
        id        = 1
        flags     = 
        frag      = 0
        ttl       = 64
        proto     = udp
        chksum    = 0x64c2
        src       = 10.0.1.1
        dst       = 10.0.1.2
        \options   \
   ###[ UDP ]### 
           sport     = domain
           dport     = 4321
           len       = 19
           chksum    = 0xac0
   ###[ Raw ]### 
              load      = 'P4 ecn test'

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
   .
   Sent 1 packets.
   .
   Sent 1 packets.
   .
   Sent 1 packets.
   .
   Sent 1 packets.
   ------------------------------------------------------------
   Client connecting to 10.0.1.2, UDP port 5001
   Sending 1470 byte datagrams, IPG target: 235.20 us (kalman adjust)
   UDP buffer size:  208 KByte (default)
   ------------------------------------------------------------
   [  1] local 10.0.1.1 port 36408 connected with 10.0.1.2 port 5001
   .
   Sent 1 packets.
   [ ID] Interval       Transfer     Bandwidth
   [  1] 0.0000-3.0003 sec  17.9 MBytes  50.0 Mbits/sec
   [  1] Sent 12759 datagrams
   [  1] Server Report:
   [ ID] Interval       Transfer     Bandwidth        Jitter   Lost/Total Datagrams
   [  1] 0.0000-3.0296 sec  16.4 MBytes  45.5 Mbits/sec   0.168 ms 1039/12758 (8.1%)
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

- You will find `"Congestion experienced, set output_metadata.ecn to 3(CE)"` printed in ./logs/n2.log

## Understanding the ECN Logic

### Packet Processing Flow

1. **Packet arrives at switch ingress**
2. **Parser extracts headers**: Identifies Ethernet and IPv4 headers
3. **ECN metadata handling**:
* Ingress control copies 2-bit ECN value from IPv4 header
* Stores ECN value in dedicated output metadata field
4. **bmv2 switch operation**:
* Monitors queue utilization against thresholds
* If congestion detected, sets CE bit in metadata
* Updates IPv4 header via metadata if needed
5. **Linux protocol stack**:
* Receiver detects CE-marked packets
* Generates Congestion Notification Packets (CNPs)
* Sender adjusts transmission rate based on CNPs

### Why Metadata Propagation?

Using metadata to transmit ECN information provides:

* **Separation of concerns**: P4 handles field extraction, bmv2 handles congestion logic
* **Flexibility**: Congestion thresholds can be adjusted without modifying P4 code
* **Performance**: Avoids repeated header parsing in different system components
* **Compatibility**: Follows standard ECN implementation patterns across systems

## Key Concepts

### ECN in the Data Plane

The P4 program's role in ECN is intentionally focused:

* **Extract and propagate** rather than make congestion decisions
* Works with existing mechanisms in switch hardware and OS
* Maintains line-rate performance critical for congestion signaling

### Data Plane and Control Plane Collaboration

This example demonstrates a common network function pattern:

* **P4 (data plane)**: Handles high-speed packet field operations
* **bmv2 (switch)**: Implements congestion detection logic
* **Linux (protocol stack)**: Manages end-to-end congestion response
* **Metadata**: The communication channel between these components

## Production Considerations

A production ECN implementation would typically include:

1. **AQM Integration**: Active Queue Management algorithms (RED, PIE, CoDel)
2. **Per-flow Processing**: Differentiated ECN handling based on traffic classes
3. **Dynamic Thresholds**: Adjusting congestion thresholds based on network conditions
4. **ECN Validation**: Ensuring ECN markings follow RFC specifications
5. **Performance Metrics**: Tracking ECN effectiveness and congestion patterns
6. **Security Measures**: Preventing ECN field spoofing
7. **Multi-protocol Support**: Extending beyond IPv4 to IPv6 and transport protocols

## What's Next?

After understanding basic ECN implementation:

* [QOS](../qos): Integrate with quality of service mechanisms
* [RSS](../rss): Integrate with Receive Side Scaling mechanisms
* Add ECN support for IPv6 headers
* Extend to handle transport protocol interactions (TCP ECN)
* Implement ECN-based rate limiting in the data plane
