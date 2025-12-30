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

def main():
    if len(sys.argv) < 3:
        print('pass 2 arguments: <dst_mac> <dst_ip> <duration>')
        exit(1)

    dst_ip = socket.gethostbyname(sys.argv[2])
    pkt = Ether(dst=sys.argv[1]) / IP(dst=dst_ip) / UDP(sport=1234, dport=4321) / "P4 multicast test"
    pkt.show2()
    try:
      for i in range(int(sys.argv[3])):
        sendp(pkt, iface=iface)
        sleep(1)
    except KeyboardInterrupt:
        raise

if __name__ == '__main__':
    main()
