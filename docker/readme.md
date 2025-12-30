# P4 Development Environment Setup Guide

## Overview

This guide helps you set up a containerized P4 (Programming Protocol-independent Packet Processors) development environment using Docker. The container includes all necessary tools and dependencies for P4 programming, including BMv2 (behavioral model version 2), P4C compiler, and other related utilities.

## Prerequisites

### Install Docker and Docker Compose

Before starting, you need to install Docker and Docker Compose on your system.

#### Quick Installation Steps

**For Ubuntu/Debian:**
```bash
# Update package index
sudo apt-get update

# Install Docker
sudo apt-get install -y docker.io

# Install Docker Compose
sudo apt-get install -y docker-compose-plugin

# Add your user to the docker group (optional, to run docker without sudo)
sudo usermod -aG docker $USER
# Note: Log out and log back in for this to take effect
```

**For other operating systems:**
- Docker Installation: Visit [Docker Official Documentation](https://docs.docker.com/engine/install/)
- Docker Compose Installation: Visit [Docker Compose Official Documentation](https://docs.docker.com/compose/install/)

#### Verify Installation

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker compose version
```

## Configuration

### Default Configuration

The `docker-compose.yaml` file comes pre-configured with sensible defaults:

```yaml
services:
  p4-dev:
    image: "jinxdh/p4-ubuntu:latest"
    restart: unless-stopped
    privileged: true
    ports:
      - "2222:22"
    volumes:
      - /mnt:/mnt
    command: ["/bin/bash", "-c", "echo 'p4:123' | chpasswd && /usr/sbin/sshd -D"]
```

**Default Settings:**
- **Container Name**: `p4-dev`
- **Docker Image**: `jinxdh/p4-ubuntu:latest`
- **SSH Port**: `2222` (host) → `22` (container)
- **Default User**: `p4`
- **Default Password**: `123`
- **Volume Mount**: `/mnt` directory is mounted for easy file access

### Optional: Customize Configuration

If you need to change the SSH port (e.g., if port 2222 is already in use):

1. Edit the `ports` section in `docker-compose.yaml`:
   ```yaml
   ports:
     - "YOUR_PORT:22"  # Change 2222 to your preferred port
   ```

2. Optionally change the password by modifying the `command` section:
   ```yaml
   command: ["/bin/bash", "-c", "echo 'p4:YOUR_PASSWORD' | chpasswd && /usr/sbin/sshd -D"]
   ```

## Docker Operations

### Start the Container

Navigate to the directory containing `docker-compose.yaml` and run:

```bash
cd docker/p4
sudo docker compose up -d
```

The `-d` flag runs the container in detached mode (in the background).

### Check Container Status

```bash
sudo docker compose ps
```

### Stop the Container

When you need to stop the container:

```bash
sudo docker compose down
```

### Restart the Container

If you need to restart your container (e.g., after configuration changes):

```bash
sudo docker compose restart
```

## Accessing the Container

### Method 1: SSH Access (Recommended)

Once the container is running, you can SSH into it using the default credentials:

```bash
ssh p4@localhost -p 2222
```

**Login Credentials:**
- **Username**: `p4`
- **Password**: `123`

**First-time SSH connection:**
If this is your first time connecting, you'll see a message about the host's authenticity. Type `yes` to continue.

### Method 2: Direct Shell Access

Alternatively, you can access the container directly using Docker:

```bash
# Find your container name
sudo docker ps

# Access the container shell as p4 user
sudo docker exec -it -u p4 p4-dev /bin/bash

# Or access as root if needed
sudo docker exec -it p4-dev /bin/bash
```

## Troubleshooting

### Port Already in Use

If you get a "port already in use" error, either:
1. Choose a different port in your `docker-compose.yaml`, or
2. Stop the service using that port

### Container Won't Start

Check the container logs:
```bash
sudo docker compose logs
```

## Next Steps

After successfully accessing your container, you're ready to start working with P4!

The container comes with **TUNA-compatible P4C compiler and BMv2** pre-installed, so you can start developing immediately without any additional setup:

- **p4c-apollo-tuna**: The P4 compiler for TUNA architecture (pre-installed)
- **BMv2 (Behavioral Model v2)**: Software switch for TUNA target (pre-installed)
- **tunic**: TUNA NIC driver and control interface
- **make**: Build automation for compiling and testing examples
- Test scripts and utilities for verifying your P4 programs

#### Building from Source (Optional)

If you want to compile TUNA's P4C and BMv2 from source code, refer to the following repositories:

- **TUNA P4C Compiler**: [https://github.com/eht-lab/behavioral-model]
- **TUNA BMv2**: [https://github.com/eht-lab/p4c]

> **Note**: Building from source is optional. The pre-installed tools are sufficient for all examples in this repository.


### Explore P4 Examples

This repository includes hands-on P4 examples specifically designed for the TUNA architecture. We recommend starting with these practical examples:

1. **[Ping (Basic Forwarding)](../tuna/app/ping)** - Your first P4 program for basic packet forwarding
2. **[L3 Forwarding](../tuna/app/l3_forward)** - IPv4 layer 3 routing between different network segments
3. **[Calculator](../tuna/app/calculator)** - Custom protocol with arithmetic and logic operations
4. **[GRE Tunnel](../tuna/app/tunnel)** - Packet encapsulation and tunneling
5. **[Firewall](../tuna/app/firewall)** - Stateless packet filtering
6. **[ECN](../tuna/app/ecn)** - Explicit congestion notification
7. **[RSS](../tuna/app/rss)** - Receive side scaling
8. **[QoS](../tuna/app/qos)** - Quality of service
9. **[Multicast](../tuna/app/multicast)** - Multicast filtering

**See the [Root README](../README.md) for a complete guide to all examples with detailed descriptions.**

### Development Tools

Inside your container, you'll have access to:
- **p4c-apollo-tuna**: The P4 compiler for TUNA architecture
- **tunic**: TUNA NIC driver and control interface
- **make**: Build automation for compiling and testing examples
- Test scripts and utilities for verifying your P4 programs

### Learning Resources

For general P4 programming concepts and language documentation:
- [P4 Official Website](https://p4.org/) - Language specifications and community resources
- [P4 Tutorials](https://github.com/p4lang/tutorials) - Comprehensive P4 tutorials for BMv2 architecture
- [P4 Language Specification](https://p4.org/specs/) - Official P4_16 language reference
