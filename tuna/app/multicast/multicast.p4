// SPDX-License-Identifier: Apache-2.0
/* -*- P4_16 -*- */

#include <core.p4>
#include "tuna.p4"

const bit<16> TYPE_IPV4 = 0x800;
const bit<24> MULTICAST_MAC_PREFIX = 0x01005e;
const bit<4> MULTICAST_IP_PREFIX = 0xe;

typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

struct empty_metadata_t { }

struct user_metadata_t { }

struct headers_t {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
}

/*************************************************************************
 ***********************I N G R E S S    P A R S E R  ********************
 *************************************************************************/
parser IngressParserImpl(packet_in pkt,
                         out headers_t hdr,
                         inout user_metadata_t user_meta,
                         in tuna_ingress_parser_input_metadata_t istd,
                         in empty_metadata_t recirculate_meta) {
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }
}

/*************************************************************************
 ************   C H E C K S U M    V E R I F I C A T I O N   *************
 *************************************************************************/
control IngressVerifyChecksumImpl(inout headers_t hdr,
                                  inout user_metadata_t meta) {
    apply { }
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control cIngress(inout headers_t hdr,
                 inout user_metadata_t user_meta,
                 in    tuna_ingress_input_metadata_t  istd,
                 inout tuna_ingress_output_metadata_t ostd) {
    action transmit() {
        // do nothing
    }

    action drop() {
        ostd.drop = 1;
    }

    table multicast_filter {
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        actions = {
            transmit;
            drop;
        }
        default_action = drop();
        const entries = {  // filter multicast packet by dst MAC
            0x01005e000102 : transmit();  // MAC: 01:00:5e:00:01:02, IP: X.0.1.2
        }
        size = 1024;
    }

    apply {
        if (hdr.ethernet.dstAddr[47:24] == MULTICAST_MAC_PREFIX &&
            hdr.ipv4.dstAddr[31:28] == MULTICAST_IP_PREFIX) {
            ostd.mc = 1;
            multicast_filter.apply();
        }
    }
}

/*************************************************************************
 *************   C H E C K S U M    C O M P U T A T I O N   **************
 *************************************************************************/
control IngressComputeChecksumImpl(inout headers_t hdr,
                                   inout user_metadata_t meta) {
    apply { }
}

/*************************************************************************
 ***********************  I N G R E S S  D E P A R S E R  ****************
 *************************************************************************/
control IngressDeparserImpl(packet_out buffer,
                            out empty_metadata_t recirculate_meta,
                            out empty_metadata_t normal_meta,
                            inout headers_t hdr,
                            in user_metadata_t meta,
                            in tuna_ingress_output_metadata_t istd) {
    apply {
        buffer.emit(hdr.ethernet);
        buffer.emit(hdr.ipv4);
    }
}

/*************************************************************************
 *********************  E G R E S S    P A R S E R  **********************
 *************************************************************************/
parser EgressParserImpl(packet_in buffer,
                        out headers_t hdr,
                        inout user_metadata_t user_meta,
                        in tuna_egress_parser_input_metadata_t istd,
                        in empty_metadata_t normal_meta) {
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        buffer.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        buffer.extract(hdr.ipv4);
        transition accept;
    }
}

/*************************************************************************
 ************   C H E C K S U M    V E R I F I C A T I O N   *************
 *************************************************************************/
control EgressVerifyChecksumImpl(inout headers_t hdr,
                                 inout user_metadata_t meta) {
    apply { }
}

/*************************************************************************
 **************  E G R E S S   P R O C E S S I N G   *********************
 *************************************************************************/
control cEgress(inout headers_t hdr,
                inout user_metadata_t user_meta,
                in    tuna_egress_input_metadata_t  istd,
                inout tuna_egress_output_metadata_t ostd) {
    apply { }
}

/*************************************************************************
 *************   C H E C K S U M    C O M P U T A T I O N   **************
 *************************************************************************/
control EgressComputeChecksumImpl(inout headers_t hdr,
                                  inout user_metadata_t meta) {
    apply { }
}

/*************************************************************************
 ***********************  E G R E S S  D E P A R S E R  ******************
 *************************************************************************/
control EgressDeparserImpl(packet_out buffer,
                           out empty_metadata_t recirculate_meta,
                           inout headers_t hdr,
                           in user_metadata_t meta,
                           in tuna_egress_output_metadata_t istd) {
    apply {
        buffer.emit(hdr.ethernet);
        buffer.emit(hdr.ipv4);
    }
}

IngressPipeline(IngressParserImpl(),
                IngressVerifyChecksumImpl(),
                cIngress(),
                IngressComputeChecksumImpl(),
                IngressDeparserImpl()) ip;

EgressPipeline(EgressParserImpl(),
               EgressVerifyChecksumImpl(),
               cEgress(),
               EgressComputeChecksumImpl(),
               EgressDeparserImpl()) ep;

TunaNic(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;
