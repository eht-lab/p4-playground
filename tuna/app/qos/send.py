#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
# Reason-GPL: import-scapy

import socket
import sys
import netifaces
from time import sleep

from scapy.all import (
    Ether,
    Dot1Q,
    IP,
    sendp
)

iface = 'eth0'
dst_mac="62:9b:0c:db:ac:20"

def main():
    if len(sys.argv) < 5:
        print('pass 4 arguments: <destination> <Dot1Q/IPv4> <priority> <duration>')
        exit(1)

    addrs = netifaces.ifaddresses(iface)
    ipv4_info = addrs.get(netifaces.AF_INET)
    if ipv4_info:
        src_ip = ipv4_info[0]['addr']
    dst_ip = socket.gethostbyname(sys.argv[1])
    priority = int(sys.argv[3])
    if sys.argv[2] == 'Dot1Q':
        pkt = Ether(dst=dst_mac) / Dot1Q(prio=priority) / IP(src=src_ip, dst=dst_ip, tos=0) / "P4 qos test"
    elif sys.argv[2] == 'IPv4':
        priority = priority << 2
        pkt = Ether(dst=dst_mac) / IP(src=src_ip, dst=dst_ip, tos=priority) / "P4 qos test"
    else:
        print('argument 3 only support Dot1Q or IPv4')
        exit(1)
    pkt.show2()
    try:
      for i in range(int(sys.argv[4])):
        sendp(pkt, iface=iface)
        sleep(1)
    except KeyboardInterrupt:
        raise

if __name__ == '__main__':
    main()
