// SPDX-License-Identifier: Apache-2.0
/* -*- P4_16 -*- */

#include <core.p4>
#include "tuna.p4"

const bit<16> TYPE_VLAN = 0x8100;
const bit<16> TYPE_IPV4 = 0x800;

typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header vlan_t {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> type;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<6>    dscp;
    bit<2>    ecn;
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
    vlan_t       vlan;
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
            TYPE_VLAN: parse_vlan;
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.type) {
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
    action get_mapping_cos(bit<3> cos) {
        ostd.icos = cos;
        ostd.ocos = cos;
    }

    action get_default_cos() {
        ostd.icos = 0;
        ostd.ocos = 0;
    }

    table cos_mapping {
        key = {
            hdr.vlan.pcp: ternary;
            hdr.ipv4.dscp: ternary;
        }
        actions = {
            get_mapping_cos;
            get_default_cos;
        }
        default_action = get_default_cos();
        const entries = {
            (0x1 &&& 0x7, 0x0 &&& 0x0) : get_mapping_cos(4);  // match 3bit pcp to icos/ocos
            (0x2 &&& 0x7, 0x0 &&& 0x0) : get_mapping_cos(3);
            (0x0 &&& 0x0, 0x1 &&& 0x3F) : get_mapping_cos(2);  // match 6bit dscp to icos/ocos
            (0x0 &&& 0x0, 0x2 &&& 0x3F) : get_mapping_cos(1);
        }
        size = 128;
    }

    apply {
        cos_mapping.apply();
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
        buffer.emit(hdr.vlan);
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
    action get_mapping_ochan(bit<4> chan) {
        ostd.ochan = chan;
    }

    action get_default_ochan() {
        ostd.ochan = 0;
    }

    table ochan_mapping {
        key = {
            istd.chan_id: exact;
        }
        actions = {
            get_mapping_ochan;
            get_default_ochan;
        }
        default_action = get_default_ochan();
        const entries = {  // match chan_id to ochan
            0 : get_mapping_ochan(1);
            1 : get_mapping_ochan(2);
        }
        size = 16;
    }

    apply {
        ochan_mapping.apply();
    }
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
