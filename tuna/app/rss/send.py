#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
# Reason-GPL: import-scapy

import socket
import sys
import netifaces
from time import sleep

from scapy.all import (
    Ether,
    IP,
    UDP,
    sendp
)

iface = 'eth0'
dst_mac="c2:0c:20:4a:23:65"

def main():
    if len(sys.argv) < 3:
        print('pass 2 arguments: <destination> <duration>')
        exit(1)

    addrs = netifaces.ifaddresses(iface)
    ipv4_info = addrs.get(netifaces.AF_INET)
    if ipv4_info:
        src_ip = ipv4_info[0]['addr']
    dst_ip = socket.gethostbyname(sys.argv[1])
    pkt = Ether(dst=dst_mac) / IP(src=src_ip, dst=dst_ip) / UDP(sport=1234, dport=4321) / "P4 rss test"
    pkt.show2()
    try:
      for i in range(int(sys.argv[2])):
        sendp(pkt, iface=iface)
        sleep(1)
    except KeyboardInterrupt:
        raise

if __name__ == '__main__':
    main()
