#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
# Reason-GPL: import-scapy
import sys

from scapy.all import (
    IP,
    sniff
)

iface = 'eth0'
my_ip = '10.0.1.2'

def handle_pkt(pkt):
    if (pkt.haslayer(IP) and pkt[IP].dst_ip == my_ip):
        pkt.show2()

def main():
    sniff(iface = iface, prn = handle_pkt, store=False)

if __name__ == '__main__':
    main()
