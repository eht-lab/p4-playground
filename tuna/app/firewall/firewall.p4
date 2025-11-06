/* -*- P4_16 -*- */
/* Test reject funtion for Apollo Tuna NIC architecture */

#include <core.p4>
#include <tuna.p4>

const bit<16> TYPE_IPV4 = 0x800;

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

struct metadata_t { }

struct headers_t {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
}

/*************************************************************************
 ***********************I N G R E S S    P A R S E R  ********************
 *************************************************************************/
parser IngressParserImpl(packet_in buffer,
                         out headers_t hdr,
                         inout metadata_t user_meta,
                         in tuna_ingress_parser_input_metadata_t istd,
                         in empty_metadata_t recirculate_meta) {
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
control IngressVerifyChecksumImpl(inout headers_t hdr,
                                  inout metadata_t meta) {
    apply { }
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control cIngress(inout headers_t hdr,
                 inout metadata_t user_meta,
                 in    tuna_ingress_input_metadata_t  istd,
                 inout tuna_ingress_output_metadata_t ostd) {
    action drop() {
        ostd.drop = 1;  // mark to drop
    }

    table blacklist {
        key = {
            hdr.ethernet.srcAddr: exact;
        }
        actions = {
            drop;
        }
        const entries = {
            0x629b0cdbac20 : drop();
        }
        size = 1024;
    }
    
    apply {
        blacklist.apply();
    }
}

/*************************************************************************
 *************   C H E C K S U M    C O M P U T A T I O N   **************
 *************************************************************************/
control IngressComputeChecksumImpl(inout headers_t hdr,
                                   inout metadata_t meta) {
    apply { }
}

/*************************************************************************
 ***********************  I N G R E S S  D E P A R S E R  ****************
 *************************************************************************/
control IngressDeparserImpl(packet_out buffer,
                            out empty_metadata_t recirculate_meta,
                            out empty_metadata_t normal_meta,
                            inout headers_t hdr,
                            in metadata_t meta,
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
                        inout metadata_t user_meta,
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
                                 inout metadata_t meta) {
    apply { }
}

/*************************************************************************
 **************  E G R E S S   P R O C E S S I N G   *********************
 *************************************************************************/
control cEgress(inout headers_t hdr,
                inout metadata_t user_meta,
                in    tuna_egress_input_metadata_t  istd,
                inout tuna_egress_output_metadata_t ostd) {
    apply { }
}

/*************************************************************************
 *************   C H E C K S U M    C O M P U T A T I O N   **************
 *************************************************************************/
control EgressComputeChecksumImpl(inout headers_t hdr,
                                  inout metadata_t meta) {
    apply { }
}

/*************************************************************************
 ***********************  E G R E S S  D E P A R S E R  ******************
 *************************************************************************/
control EgressDeparserImpl(packet_out buffer,
                           out empty_metadata_t recirculate_meta,
                           inout headers_t hdr,
                           in metadata_t meta,
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
