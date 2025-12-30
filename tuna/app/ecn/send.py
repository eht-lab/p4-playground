#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
# Reason-GPL: import-scapy

import socket
import sys
from time import sleep

from scapy.all import (
    Ether,
    IP,
    UDP,
    sendp
)

iface = 'eth0'
dst_mac="62:9b:0c:db:ac:20"

def main():
    if len(sys.argv) < 3:
        print('pass 2 arguments: <destination> <duration>')
        exit(1)

    addr = socket.gethostbyname(sys.argv[1])
    pkt = Ether(dst=dst_mac) / IP(dst=addr, tos=1) / UDP(dport=4321) / "P4 ecn test"
    pkt.show2()
    try:
      for i in range(int(sys.argv[2])):
        sendp(pkt, iface=iface)
        sleep(1)
    except KeyboardInterrupt:
        raise

if __name__ == '__main__':
    main()
