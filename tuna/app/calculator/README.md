# Calculator - Custom Protocol with Arithmetic and Logic Operations

## Overview

This example demonstrates how to define and implement a custom protocol in P4. The calculator program processes packets containing arithmetic and logical operations, performs the computation in the data plane, and returns the result to the sender.

This exercise showcases P4's power to implement custom packet processing logic beyond traditional networking protocols.

## Learning Objectives

By completing this exercise, you will learn:

- **Custom Protocol Design**: Define your own packet header formats and protocol types
- **Arithmetic Operations**: Perform addition and subtraction in the data plane
- **Bitwise Operations**: Implement AND, OR, XOR operations on packet data
- **Logical Comparisons**: Execute comparison operations (==, !=, >, <, >=, <=)
- **Conditional Logic**: Use if statements in P4 actions
- **Protocol Identification**: Use custom EtherType values for protocol detection

## What You'll Implement

The P4 program implements a calculator protocol that:

1. **Recognizes calculator packets**: Uses EtherType 0x1234
2. **Validates packet format**: Checks for 'P4' magic bytes and version
3. **Performs operations**: Executes arithmetic, bitwise, and comparison operations
4. **Returns results**: Fills in the result field of the packet

## Network Topology

```
      Host 1                           Host 2
    (Sender)                        (Receiver)
        │                                │
        │                                │
   ┌────┴────┐                      ┌────┴────┐
   │  NIC 1  │──────────────────────│  NIC 2  │
   └─────────┘                      └─────────┘
   Calculator P4 Program          Calculator P4 Program
```

Both NICs run the calculator P4 program and can process calculator packets.

## Custom Protocol Specification

### P4Calc Protocol Header

```
 0                1                  2              3                4
+----------------+----------------+----------------+---------------+
|      P         |       4        |     Version    |  Op (16bits)  |
+----------------+----------------+----------------+---------------+
|                          Operand A (32 bits)                     |
+----------------+----------------+----------------+---------------+
|                          Operand B (32 bits)                     |
+----------------+----------------+----------------+---------------+
|                          Result (32 bits)                        |
+----------------+----------------+----------------+---------------+
```

**Field Descriptions:**

- **P (8 bits)**: ASCII 'P' (0x50) - Magic byte
- **4 (8 bits)**: ASCII '4' (0x34) - Magic byte
- **Version (8 bits)**: Protocol version 0.1 (0x01)
- **Op (16 bits)**: Operation code (see below)
- **Operand A (32 bits)**: First operand
- **Operand B (32 bits)**: Second operand
- **Result (32 bits)**: Computation result (filled by the P4 program)

### Supported Operations

**Arithmetic Operations:**
- `+` (0x2b00): Addition - `Result = Operand A + Operand B`
- `-` (0x2d00): Subtraction - `Result = Operand A - Operand B`

**Bitwise Operations:**
- `&` (0x2600): Bitwise AND - `Result = Operand A & 0xF` (note: operand B fixed to 0xF)
- `|` (0x7c00): Bitwise OR - `Result = Operand A | 0xF`
- `^` (0x5e00): Bitwise XOR - `Result = Operand A ^ Operand B`

**Comparison Operations:**
- `==` (0x3d3d): Equal - `Result = 1 if A == B, else 0`
- `!=` (0x213d): Not equal - `Result = 1 if A != B, else 0`
- `>` (0x3e00): Greater than - `Result = 1 if A > B, else 0`
- `<` (0x3c00): Less than - `Result = 1 if A < B, else 0`
- `>=` (0x3e3d): Greater or equal - `Result = 1 if A >= B, else 0`
- `<=` (0x3c3d): Less or equal - `Result = 1 if A <= B, else 0`

## P4 Program Details

### Custom Header Definition

```c
header p4calc_t {
    bit<8>  p;           // 'P'
    bit<8>  four;        // '4'
    bit<8>  ver;         // Version
    bit<16> op;          // Operation
    bit<32> operand_a;   // First operand
    bit<32> operand_b;   // Second operand
    bit<32> res;         // Result
}
```

### Parser Logic

The parser identifies calculator packets by EtherType:

```c
state start {
    packet.extract(hdr.ethernet);
    transition select(hdr.ethernet.etherType) {
        P4CALC_ETYPE : parse_p4calc;  // 0x1234
        default      : reject;         // Drop non-calculator packets
    }
}
```

### Example Action Implementation

```c
action operation_add() {
    hdr.p4calc.res = hdr.p4calc.operand_a + hdr.p4calc.operand_b;
}

action operation_equal() {
    if (hdr.p4calc.operand_a == hdr.p4calc.operand_b)
        hdr.p4calc.res = 1;
}
```

### Calculate Table

```c
table calculate {
    key = {
        hdr.p4calc.op : exact;  // Match on operation code
    }
    actions = {
        operation_add;
        operation_sub;
        operation_and;
        // ... other operations
    }
    const entries = {
        P4CALC_PLUS  : operation_add();
        P4CALC_MINUS : operation_sub();
        // ... other mappings
    }
}
```

## How to Run

In your shell, run:
```bash
cd tuna/app/calculator
make
```
This will:
1. compile `calculator.p4`
2. start the topo in Mininet and configure all NIC with the appropriate P4 program + table entries, and configure all hosts with the commands listed in [topology.json](./topology.json)
3. You should now see a Mininet command prompt. Try to ping between hosts in the topology:
   ```bash
   mininet> h2 python3 recv.py &
   mininet> h1 python3 send.py
   > 100+50
   > 100-50
   ```

   You will get:
   ```bash
   mininet> h2 python3 recv.py &
   mininet> h1 python3 send.py
   > 100+50
   100+50
   /home/hezhanpeng/Work/p4-open/p4-playground/tuna/app/calculator/send.py:46: DeprecationWarning: ast.Num is deprecated and will be removed in Python 3.14; use ast.Constant instead
   if isinstance(node, ast.Num):  # Number
   /home/hezhanpeng/Work/p4-open/p4-playground/tuna/app/calculator/send.py:47: DeprecationWarning: Attribute n is deprecated and will be removed in Python 3.14; use value instead
   return node.n
   0000  62 9B 0C DB AC 20 00 00 00 00 00 00 12 34 50 34  b.... .......4P4
   0010  01 2B 00 00 00 00 64 00 00 00 32 00 00 00 00 50  .+....d...2....P
   0020  34 63 61 6C 63 20 74 65 73 74                    4calc test
   result is :  150
   > 100-50
   100-50
   0000  62 9B 0C DB AC 20 00 00 00 00 00 00 12 34 50 34  b.... .......4P4
   0010  01 2D 00 00 00 00 64 00 00 00 32 00 00 00 00 50  .-....d...2....P
   0020  34 63 61 6C 63 20 74 65 73 74                    4calc test
   result is :  50
   >
   ```
4. Type `quit` to leave send.py, if will self-check the calculate result
   You will get:
   ```bash
   > quit
   0000  62 9B 0C DB AC 20 00 00 00 00 00 00 12 34 50 34  b.... .......4P4
   0010  01 71 75 00 00 00 64 00 00 00 32 00 00 00 00 50  .qu...d...2....P
   0020  34 63 61 6C 63 20 74 65 73 74                    4calc test
   .
   Sent 1 packets.
   calculator test success!
   mininet>
   ```
5. Type `exit` to leave each xterm and the Mininet command line.
   Then, to stop mininet:
   ```bash
   make stop
   ```
   And to delete all pcaps, build files, and logs:
   ```bash
   make clean
   ```

## Test Scripts

### send.py

Constructs and sends calculator protocol packets:

```python
# Example usage
python3 send.py 100+50
python3 send.py 100-50
python3 send.py 255&15
python3 send.py 42==42
python3 send.py 100>50
```

### recv.py

Receives and parses calculator protocol response packets, displaying the result.

## Expected Results

**Test Case 1: Addition**
```
Input:  Operand A = 100, Operand B = 50, Op = '+'
Output: Result = 150
```

**Test Case 2: Subtraction**
```
Input:  Operand A = 100, Operand B = 50, Op = '-'
Output: Result = 50
```

**Test Case 3: Bitwise AND**
```
Input:  Operand A = 255, Operand B = (ignored), Op = '&'
Output: Result = 15  (255 & 0xF)
```

**Test Case 4: Equality**
```
Input:  Operand A = 42, Operand B = 42, Op = '=='
Output: Result = 1  (true)
```

**Test Case 5: Greater Than**
```
Input:  Operand A = 100, Operand B = 50, Op = '>'
Output: Result = 1  (true)
```

## Understanding the Packet Flow

1. **Host sends calculator packet**:
   - Ethernet frame with EtherType 0x1234
   - P4Calc header with operation and operands

2. **NIC ingress processing**:
   - Parser extracts Ethernet and P4Calc headers
   - No control plane processing
   - Deparser emits headers unchanged

3. **NIC egress processing**:
   - Parser extracts headers again
   - Control block applies `calculate` table
   - Performs operation and fills result field
   - Deparser emits modified packet

4. **Host receives response**:
   - Same packet structure with result field filled

## Key Concepts

### Custom Protocol Design

This example demonstrates best practices for custom protocols:
- **Magic bytes**: 'P' and '4' for protocol identification
- **Version field**: For protocol evolution
- **Type field**: Operation code for action selection
- **Fixed-size fields**: Simplifies parsing and processing

### Data Plane Computation

The calculator performs computation directly in the network data plane:
- **Low latency**: No CPU involvement for simple calculations
- **Line rate**: Processes packets at wire speed
- **Offloading**: Reduces host CPU load

### Limitations

Current implementation has some constraints:
- **Bitwise operations**: Operand B is fixed to 0xF for AND and OR
- **No overflow handling**: Results may overflow 32-bit fields
- **No error reporting**: Invalid operations drop packets

## What's Next?

After mastering the calculator, explore:

- **[GRE Tunnel](../tunnel)**: Learn complex header manipulation with encapsulation
- **[Firewall](../firewall)**: Add stateless packet filtering
- Try extending the calculator with more operations (multiplication, division)
