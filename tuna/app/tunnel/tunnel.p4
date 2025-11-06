/* -*- P4_16 -*- */
/* Test reject funtion for Apollo Tuna NIC architecture */

#include <core.p4>
#include <tuna.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<8> PROTOCOL_GRE = 47;

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

header gre_t {
    bit<1>  c;
    bit<1>  r;
    bit<1>  k;
    bit<1>  s;
    bit<1>  rsv0;
    bit<3>  version;
    bit<8>  rsv1;
    bit<16> protocolType;
}

struct empty_metadata_t { }

struct metadata_t { }

struct headers_t {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    gre_t        gre;
    ipv4_t       innerIpv4;
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
        transition select(hdr.ipv4.protocol) {
            PROTOCOL_GRE: parse_gre;
            default: accept;
        }
    }

    state parse_gre {
        buffer.extract(hdr.gre);
        transition select(hdr.gre.protocolType) {
            TYPE_IPV4: parse_inner_ipv4;
            default: accept;
        }
    }

    state parse_inner_ipv4 {
        buffer.extract(hdr.innerIpv4);
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
    action gre_decapsulation() {
        hdr.ipv4.setInvalid();
        hdr.gre.setInvalid();
    }
    
    table gre_decap {
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        actions = {
            gre_decapsulation;
        }
        const entries = {  // 匹配公网IP进行解封装
            0x0a000102 : gre_decapsulation();
            0x0a000103 : gre_decapsulation();
        }
        size = 1024;
    }
    
    apply {
        if (hdr.ipv4.isValid() && hdr.gre.isValid()) {  // 带gre进入解封装处理
            gre_decap.apply();
        }
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
        buffer.emit(hdr.gre);
        buffer.emit(hdr.innerIpv4);
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
        transition select(hdr.ipv4.protocol) {
            PROTOCOL_GRE: parse_gre;
            default: accept;
        }
    }

    state parse_gre {
        buffer.extract(hdr.gre);
        transition select(hdr.gre.protocolType) {
            TYPE_IPV4: parse_inner_ipv4;
            default: accept;
        }
    }

    state parse_inner_ipv4 {
        buffer.extract(hdr.innerIpv4);
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
    action gre_encapsulation(ip4Addr_t srcAddr, ip4Addr_t dstAddr) {
        hdr.gre.setValid();
        hdr.gre.c = 0;
        hdr.gre.r = 0;
        hdr.gre.k = 0;
        hdr.gre.s = 0;
        hdr.gre.rsv0 = 0;
        hdr.gre.version = 0;
        hdr.gre.rsv1 = 0;
        hdr.gre.protocolType = TYPE_IPV4;
        
        hdr.innerIpv4.setValid();
        hdr.innerIpv4 = hdr.ipv4;  // 原始ipv4复制到内层ipv4，外层ipv4变为封装头重新赋值
        hdr.ipv4.version = 4;
        hdr.ipv4.ihl = 5;
        hdr.ipv4.diffserv = 0;
        hdr.ipv4.totalLen = hdr.innerIpv4.totalLen + 24;  // 增加了外层ipv4（20B）和gre（4B）
        hdr.ipv4.identification = 0;
        hdr.ipv4.flags = 2;
        hdr.ipv4.fragOffset = 0;
        hdr.ipv4.ttl = 64;
        hdr.ipv4.protocol = PROTOCOL_GRE;
        hdr.ipv4.hdrChecksum = 0;  // checksum重新计算，TBD
        hdr.ipv4.srcAddr = srcAddr;
        hdr.ipv4.dstAddr = dstAddr;
    }

    table gre_encap {
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        actions = {
            gre_encapsulation;
        }
        const entries = {  // 匹配私网IP进行封装，通过公网IP互联
            0xc0a80102 : gre_encapsulation(0x0a000103, 0x0a000102);
            0xc0a80103 : gre_encapsulation(0x0a000102, 0x0a000103);
        }
        size = 1024;
    }

    apply {
        if (hdr.ipv4.isValid() && !hdr.gre.isValid()) {  // 不带gre进入封装处理
            gre_encap.apply();
        }
    }
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
        buffer.emit(hdr.gre);
        buffer.emit(hdr.innerIpv4);
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
