#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
# Reason-GPL: import-scapy
import re
import sys
import netifaces

from scapy.all import (
    Ether,
    IntField,
    Packet,
    StrFixedLenField,
    XByteField,
    bind_layers,
    sniff,
    sendp,
    Raw,
)

iface = 'eth0'
my_mac = "62:9b:0c:db:ac:20"
dst_mac="c2:0c:20:4a:23:65"

# Define custom packet class for P4calc
class P4calc(Packet):
    name = "P4calc"
    # Define fields for the P4calc packet
    fields_desc = [ StrFixedLenField("P", "P", length=1),
                    StrFixedLenField("Four", "4", length=1),
                    XByteField("version", 0x01),
                    StrFixedLenField("op", "a", length=2),
                    IntField("operand_a", 0),
                    IntField("operand_b", 0),
                    IntField("result", 0xDEADBABE)]

# Bind custom packet class to Ethernet type 0x1234
bind_layers(Ether, P4calc, type=0x1234)

def handle_pkt(pkt):
    if (pkt.haslayer(Ether) and pkt[Ether].type == 0x1234):
        if (pkt[Ether].src != my_mac):
            pkt.show2()
            print(pkt[P4calc].result)
            print(pkt[P4calc].op)
            if pkt[P4calc].op.decode('utf-8') == "qu":
                exit
            sendpkt = Ether(dst=dst_mac, src=my_mac, type=0x1234) / P4calc(result=pkt[P4calc].result)
            sendpkt = sendpkt/Raw(load="P4calc send back")
            sendpkt.show2()
            sendp(sendpkt, iface=iface, verbose=False)


def stop_pkt(pkt):
    if (pkt.haslayer(Ether) and pkt[Ether].type == 0x1234):
        if (pkt[Ether].src != my_mac):
            if (pkt[P4calc].op.decode('utf-8') == "qu"):
                return True


def main():
    sniff(iface = iface, prn = handle_pkt, stop_filter=stop_pkt, store=False)

if __name__ == '__main__':
    main()
