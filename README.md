# P4 Playground

* [Introduction](#introduction)
* [Getting Started](#getting-started)
* [P4 Examples](#p4-examples)
* [Documentation](#documentation)
* [License](#license)

## Introduction

Welcome to P4 Playground! This repository provides a comprehensive P4 programming environment with practical examples for the TUNA architecture. Whether you're new to P4 or looking to explore advanced network programming concepts, you'll find hands-on exercises and complete implementations here.

## Getting Started

### Prerequisites

Before you begin, make sure you have set up your P4 development environment. Follow the detailed setup guide in our Docker documentation:

📖 **[Docker Setup Guide](./docker/readme.md)** - Complete instructions for:
- Installing Docker and Docker Compose
- Configuring your containerized P4 development environment
- Accessing and managing your container
- Troubleshooting common issues

### Quick Start

Once your environment is ready, you can dive into the examples below. Each example includes:
- Complete P4 source code
- Test scripts and topology configurations
- Detailed README with step-by-step instructions
- Expected results and verification methods

## P4 Examples

The examples are organized by complexity and feature sets. We recommend following them in order if you're new to P4 programming on TUNA.

### 1. Basic Network Functions

Start here to understand fundamental P4 concepts and TUNA architecture basics.

- **[Ping (Basic Forwarding)](./tuna/app/ping)**<br>
  <small>Learn the basics of packet forwarding in TUNA by implementing a simple ping between hosts in the same network segment. This example demonstrates basic packet reception, processing, and transmission capabilities, serving as your first hands-on experience with TUNA P4 programming.</small>

- **[L3 Forwarding (Layer 3 Routing)](./tuna/app/l3_forward)**<br>
  <small>Build on basic forwarding by implementing IPv4 layer 3 forwarding. Learn to modify destination MAC addresses based on IP routing tables, enabling communication between hosts in different network segments. This exercise introduces you to practical routing logic and ARP handling in P4.</small>

### 2. Advanced Protocol Processing

Progress to more complex protocol implementations and custom header definitions.

- **[Calculator (Arithmetic & Logic Operations)](./tuna/app/calculator)**<br>
  <small>Explore P4's computational capabilities by implementing a custom protocol calculator. This example demonstrates how to define custom packet headers and perform arithmetic operations (+, -), bitwise operations (&, |, ^, ~), and logical comparisons (==, !=, >, <, >=, <=) directly in the data plane.</small>

- **[GRE Tunnel (Tunneling & Encapsulation)](./tuna/app/tunnel)**<br>
  <small>Master packet encapsulation and tunneling by implementing GRE (Generic Routing Encapsulation). Learn how to encapsulate private network traffic within public network packets, enabling hosts with private IPs to communicate across a public IP network through tunnel endpoints.</small>

### 3. Stateless Processing & Security

Explore stateless packet processing and security features.

- **[Firewall (Stateless Packet Filtering)](./tuna/app/firewall)**<br>
  <small>Implement a stateless firewall with blacklist functionality. This example demonstrates how to maintain state across packets and enforce security policies, allowing you to selectively block traffic between hosts while maintaining legitimate connections.</small>

### 4. Quality of Service

Explore traffic management and performance optimization capabilities for diverse network scenarios.

- **[ECN (Explicit Congestion Notification)](./tuna/app/ecn)**<br>
  <small>Implement congestion signaling without packet dropping by processing IPv4 ECN fields. Learn to extract 2-bit ECN markings in the P4 ingress pipeline, propagate them via metadata, and integrate with bmv2/Linux protocol stacks for queue threshold monitoring and CNP generation. This example demonstrates efficient end-to-end congestion control.</small>

- **[RSS (Receive Side Scaling)](./tuna/app/rss)**<br>
  <small>Optimize multi-core CPU utilization with traffic distribution. Implement protocol-aware hash calculations (four-tuple for UDP, two-tuple for other IPv4 traffic) in the P4 ingress pipeline, map hash values to logical queue IDs, and enable NIC modules to route packets to appropriate CPU cores. Master flow affinity and load balancing fundamentals.</small>

- **[QoS (Quality of Service)](./tuna/app/qos)**<br>
  <small>Enable differentiated traffic treatment with dual-pipeline processing. Ingress: Combine VLAN PCP and IPv4 DSCP fields for ternary table lookup to map to CoS values (icos/ocos). Egress: Use chan\_id for exact match table lookup to map to output channels (ochan). Learn to integrate with NIC modules (IPeg/VPE) for resource allocation and scheduling.</small>

### 5. Multicast Transmission

Implement efficient group communication and traffic filtering for multicast scenarios.

- **[Multicast (Group Traffic Filtering)](./tuna/app/multicast)**<br>
  <small>Enable authorized group traffic delivery on smart NICs. Identify multicast packets via destination MAC (01-00-5E prefix) and IPv4 (224.0.0.0/4) checks, set multicast metadata flags, and filter traffic using an IGMP-managed multicast address table. Learn to offload unwanted multicast traffic at the NIC level, reducing host CPU load and improving security.</small>

## Documentation

### TUNA Architecture

All examples in this repository use the TUNA architecture, a high-performance P4 target designed for network interface cards (NICs). Key features include:

- Hardware-accelerated packet processing
- Support for common network protocols
- Custom protocol definition capabilities
- Integration with Linux networking stack

### P4 Language Resources

For general P4 language documentation and specifications:

- [P4 Language Specification](https://p4.org/specs/)
- [P4 Official Website](https://p4.org/)
- [P4 Tutorials](https://github.com/p4lang/tutorials)

### Compiler and Tools

- **p4c-apollo-tuna**: The P4 compiler for TUNA architecture
- **tunic**: TUNA NIC driver and control interface
- Compilation generates firmware binaries deployable on TUNA NICs

## Development Workflow

Typical workflow for developing and testing P4 programs:

1. **Write**: Create or modify P4 programs in the example directories
2. **Compile**: Use `p4c-apollo-tuna` to compile P4 code to TUNA firmware
3. **Deploy**: Load the compiled firmware onto TUNA NICs or test in simulation
4. **Test**: Run test scripts to verify functionality
5. **Debug**: Analyze logs and packet captures to troubleshoot

Each example directory contains a `Makefile` and `test.sh` script to streamline this workflow.

## Project Structure

```
p4-playground/
├── docker/              # Docker environment setup
│   ├── readme.md       # Detailed setup instructions
│   └── p4/             # Docker compose configurations
├── tuna/               # TUNA P4 examples
│   └── app/            # Application examples
│       ├── ping/       # Basic forwarding
│       ├── l3_forward/ # Layer 3 routing
│       ├── calculator/ # Custom protocol calculator
│       ├── tunnel/     # GRE tunneling
│       ├── firewall/   # Stateless firewall
│       ├── ecn/        # Explicit congestion notification
│       ├── rss/        # Receive side scaling
│       ├── qos/        # Quality of service
│       └── multicast/  # Multicast filtering
├── test/               # Test utilities and scripts
└── utils/              # Helper utilities
```

## Next Steps

1. **Set up your environment**: Start with the [Docker Setup Guide](./docker/readme.md)
2. **Try your first example**: Begin with [Ping](./tuna/app/ping) to understand the basics
3. **Explore advanced features**: Progress through the examples to build your P4 skills
4. **Experiment**: Modify existing examples or create your own P4 programs

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.




