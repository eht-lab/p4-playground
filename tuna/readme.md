# TUNA P4 Examples

This directory contains P4 examples designed for the TUNA model. These examples demonstrate various network programming capabilities including basic forwarding, routing, tunneling, and security features etc.

## Prerequisites

Before running the examples in this directory, you need to set up the following dependencies:

### 1. P4 Compiler: p4c-apollo-tuna

All examples in the `tuna` directory require the **p4c-apollo-tuna** compiler to compile P4 programs into TUNA-compatible firmware.

**Installation:**

Please visit the p4c compiler repository and follow the build instructions:

🔗 **[https://github.com/eht-lab/p4c](https://github.com/eht-lab/p4c)**

The compiler translates P4_16 source code into JSON format that can be loaded onto TUNA NICs or the BMv2 simulator.

### 2. Network Simulator: BMv2 (Behavioral Model v2)

For testing and simulation, the examples use **BMv2** (Behavioral Model version 2), which provides a software simulator for P4 programs.

**Installation:**

Please visit the behavioral-model repository and follow the build instructions:

🔗 **[https://github.com/eht-lab/behavioral-model](https://github.com/eht-lab/behavioral-model)**

BMv2 works together with Mininet to create virtual network topologies for testing P4 programs before deploying to hardware.

### 3. Verify Installation

After installing both dependencies, verify they are available:

```bash
# Check p4c-apollo-tuna compiler
p4c-apollo-tuna --version

# Check BMv2 tuna_nic target(used as tuna_nic in examples)
which tuna_nic
```

## Directory Structure

```
tuna/
├── app/                   # P4 application examples
│   ├── ping/              # Basic packet forwarding
│   ├── l3_forward/        # Layer 3 routing
│   ├── calculator/        # Custom protocol calculator
│   ├── tunnel/            # GRE tunneling
│   ├── firewall/          # Stateless firewall
│   ├── ecn/               # Explicit congestion notification
│   ├── rss/               # Receive side scaling
│   ├── qos/               # Quality of service
│   └── multicast/         # Multicast filtering
└── readme.md              # This file
```

## Running Examples

Each example directory contains:
- **P4 source code** (`.p4` file)
- **Makefile** for compilation
- **Topology files** (`.json`) for network simulation
- **Test scripts** (`test.sh`) for automated testing
- **README.md** with detailed instructions

### Quick Start

To run any example:

```bash
# Enter simulator runtime environment
git clone https://github.com/eht-lab/p4-playground.git

# Navigate to an example directory
cd tuna/app/ping

# Compile the P4 program
make build

# Run the simulation
make run
# or
make
```

## Automated Testing

For automated testing of all examples, please refer to the test framework documentation:

**[Test Framework Guide](../test/readme.md)**

The test framework allows you to:
- Run all examples automatically
- Run individual examples
- Generate test reports with PASS/FAIL results

### Quick Test Commands

```bash
# From the p4-playground root directory

# Test all examples
cd test
./test.sh

# Test a single example
./test.sh app ping
./test.sh app l3_forward
```

## Example Overview

### 1. [Ping - Basic Forwarding](./app/ping)
Learn the basics of packet forwarding in TUNA with a simple pass-through program.

### 2. [L3 Forwarding](./app/l3_forward)
Implement IPv4 layer 3 routing with longest prefix match (LPM) tables.

### 3. [Calculator](./app/calculator)
Define custom protocols and perform arithmetic and logic operations in the data plane.

### 4. [GRE Tunnel](./app/tunnel)
Implement packet encapsulation and decapsulation using GRE protocol.

### 5. [Firewall](./app/firewall)
Build a stateless firewall with MAC address blacklist filtering.

### 6. [ECN](./app/ecn)
Implements basic Explicit Congestion Notification functionality.

### 7. [RSS](./app/rss)
Implements the Receive Side Scaling feature.

### 8. [QoS](./app/qos)
Implements Quality of Service functionality.

### 9. [Multicast](./app/multicast)
Implements multicast filtering functionality.
