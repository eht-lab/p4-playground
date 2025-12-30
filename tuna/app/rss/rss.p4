// SPDX-License-Identifier: Apache-2.0
/* -*- P4_16 -*- */

#include <core.p4>
#include "tuna.p4"

const bit<16> TYPE_IPV4 = 0x800;
const bit<8> PROTOCOL_UDP = 17;

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

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length;
    bit<16> checksum;
}

struct empty_metadata_t { }

struct user_metadata_t {
    bit<32> hash_value;
}

struct headers_t {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    udp_t        udp;
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
        transition select(hdr.ipv4.protocol) {
            PROTOCOL_UDP: parse_udp;
            default: accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
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
    Hash<bit<32>>(HashAlgorithm.toeplitz) my_hash;

    action calc_udp_hash() {
        // calculate four-tuple hash for udp
        user_meta.hash_value = my_hash.get_hash(
            {hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.udp.srcPort, hdr.udp.dstPort});
    }

    action calc_ipv4_hash() {
        // calculate two-tuple hash for ipv4 default
        user_meta.hash_value = my_hash.get_hash(
            {hdr.ipv4.srcAddr, hdr.ipv4.dstAddr});
    }

    table hash_calc {
        key = {
            hdr.ipv4.protocol: exact;
        }
        actions = {
            calc_udp_hash;
            calc_ipv4_hash;
        }
        default_action = calc_ipv4_hash();
        const entries = {
            PROTOCOL_UDP : calc_udp_hash();
        }
        size = 32;
    }

    action get_dst_qid(bit<8> qid) {
        ostd.dst_qid = (bit<14>)(qid);
    }

    action get_default_qid() {
        ostd.dst_qid = 0;
    }

    table rss {
        key = {
            user_meta.hash_value: ternary;
        }
        actions = {
            get_dst_qid;
            get_default_qid;
        }
        default_action = get_default_qid();
        const entries = {  // match hash value LSB 8bit to logic qid
            0x57 &&& 0xFF : get_dst_qid(1);
            0x36 &&& 0xFF : get_dst_qid(2);
        }
        size = 256;
    }

    apply {
        hash_calc.apply();
        rss.apply();
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
        buffer.emit(hdr.udp);
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
