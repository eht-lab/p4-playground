#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
# Reason-GPL: import-scapy
import sys

from scapy.all import (
    IP,
    UDP,
    sniff
)

iface = 'eth0'

def handle_pkt(pkt):
    if (pkt.haslayer(UDP) and pkt[UDP].dport == 4321):
        pkt.show2()

def main():
    sniff(iface = iface, prn = handle_pkt, store=False)

if __name__ == '__main__':
    main()
