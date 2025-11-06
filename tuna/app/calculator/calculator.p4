/* -*- P4_16 -*- */

/*
 * P4 Calculator
 *
 * This program implements a simple protocol. It can be carried over Ethernet
 * (Ethertype 0x1234).
 *
 * The Protocol header looks like this:
 *
 *        0                1                  2              3
 * +----------------+----------------+----------------+---------------+
 * |      P         |       4        |     Version    |     Op        |
 * +----------------+----------------+----------------+---------------+
 * |                              Operand A                           |
 * +----------------+----------------+----------------+---------------+
 * |                              Operand B                           |
 * +----------------+----------------+----------------+---------------+
 * |                              Result                              |
 * +----------------+----------------+----------------+---------------+
 *
 * P is an ASCII Letter 'P' (0x50)
 * 4 is an ASCII Letter '4' (0x34)
 * Version is currently 0.1 (0x01)
 * Op is an operation to Perform:
 *   '+' (0x2b) Result = OperandA + OperandB
 *   '-' (0x2d) Result = OperandA - OperandB
 *   '&' (0x26) Result = OperandA & OperandB
 *   '|' (0x7c) Result = OperandA | OperandB
 *   '^' (0x5e) Result = OperandA ^ OperandB
 *
 * The device receives a packet, performs the requested operation, fills in the
 * result and sends the packet back out of the same port it came in on, while
 * swapping the source and destination addresses.
 *
 * If an unknown operation is specified or the header is not valid, the packet
 * is dropped
 */

#include <core.p4>
#include <tuna.p4>

/*
 * Define the headers the program will recognize
 */

/*
 * Standard ethernet header
 */
typedef bit<48> macAddr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

/*
 * This is a custom protocol header for the calculator. We'll use
 * ethertype 0x1234 for is (see parser)
 */
const bit<16> P4CALC_ETYPE  = 0x1234;
const bit<8>  P4CALC_P      = 0x50;   // 'P'
const bit<8>  P4CALC_4      = 0x34;   // '4'
const bit<8>  P4CALC_VER    = 0x01;   // v0.1
/* compute operation */
const bit<16>  P4CALC_PLUS   = 0x2b00;   // '+'
const bit<16>  P4CALC_MINUS  = 0x2d00;   // '-'
/* bitwise operation */
const bit<16>  P4CALC_AND    = 0x2600;   // '&'
const bit<16>  P4CALC_OR     = 0x7c00;   // '|'
const bit<16>  P4CALC_CARET  = 0x5e00;   // '^'
const bit<16>  P4CALC_INVERT = 0x7e00;   // '~'
/* compare operation*/
const bit<16>  P4CALC_EQL    = 0x3d3d;   // '=='
const bit<16>  P4CALC_UNEQL  = 0x213d;   // '!='
const bit<16>  P4CALC_GRTR   = 0x3e00;   // '>'
const bit<16>  P4CALC_LESS   = 0x3c00;   // '<'
const bit<16>  P4CALC_GORE   = 0x3e3d;   // '>='
const bit<16>  P4CALC_LORE   = 0x3c3d;   // '<='

header p4calc_t {
    bit<8>  p;
    bit<8>  four;
    bit<8>  ver;
    bit<16> op;
    bit<32> operand_a;
    bit<32> operand_b;
    bit<32> res;
}

/*
 * All headers, used in the program needs to be assembed into a single struct.
 * We only need to declare the type, but there is no need to instantiate it,
 * because it is done "by the architecture", i.e. outside of P4 functions
 */
struct headers_t {
    ethernet_t   ethernet;
    p4calc_t     p4calc;
}

struct empty_metadata_t { }

struct metadata_t { }

/*************************************************************************
 ***********************I N G R E S S    P A R S E R  ********************
 *************************************************************************/
parser IngressParserImpl(packet_in packet,
                         out headers_t hdr,
                         inout metadata_t user_meta,
                         in tuna_ingress_parser_input_metadata_t istd,
                         in empty_metadata_t recirculate_meta) {
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            P4CALC_ETYPE : parse_p4calc;
            default      : reject;
        }
    }

    state parse_p4calc {
        packet.extract(hdr.p4calc);
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
    apply { }
}

/*************************************************************************
 ************   C H E C K S U M    V E R I F I C A T I O N   *************
 *************************************************************************/
control IngressComputeChecksumImpl(inout headers_t hdr,
                                   inout metadata_t meta) {
    apply { }
}

/*************************************************************************
 ***********************  I N G R E S S  D E P A R S E R  ****************
 *************************************************************************/
control IngressDeparserImpl(packet_out packet,
                            out empty_metadata_t recirculate_meta,
                            out empty_metadata_t normal_meta,
                            inout headers_t hdr,
                            in metadata_t meta,
                            in tuna_ingress_output_metadata_t istd) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.p4calc);
    }
}

/*************************************************************************
 *********************  E G R E S S    P A R S E R  **********************
 *************************************************************************/
parser EgressParserImpl(packet_in packet,
                        out headers_t hdr,
                        inout metadata_t user_meta,
                        in tuna_egress_parser_input_metadata_t istd,
                        in empty_metadata_t normal_meta) {
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            P4CALC_ETYPE : parse_p4calc;
            default      : reject;
        }
    }

    state parse_p4calc {
        packet.extract(hdr.p4calc);
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
    action operation_add() {
        hdr.p4calc.res = hdr.p4calc.operand_a + hdr.p4calc.operand_b;
    }

    action operation_sub() {
        hdr.p4calc.res = hdr.p4calc.operand_a - hdr.p4calc.operand_b;
    }

    action operation_and() {
        hdr.p4calc.res = hdr.p4calc.operand_a & 0xF;
    }

    action operation_or() {
        hdr.p4calc.res = hdr.p4calc.operand_a | 0xF;
    }

    action operation_xor() {
        hdr.p4calc.res = hdr.p4calc.operand_a ^ hdr.p4calc.operand_b;
    }

    action operation_equal() {
        if (hdr.p4calc.operand_a == hdr.p4calc.operand_b)
            hdr.p4calc.res = 1;
    }

    action operation_unequal() {
        if (hdr.p4calc.operand_a != hdr.p4calc.operand_b)
            hdr.p4calc.res = 1;
    }

    action operation_greater() {
        if (hdr.p4calc.operand_a > hdr.p4calc.operand_b)
            hdr.p4calc.res = 1;
    }

    action operation_less() {
        if (hdr.p4calc.operand_a < hdr.p4calc.operand_b)
            hdr.p4calc.res = 1;
    }

    action operation_greaterorequal() {
        if (hdr.p4calc.operand_a >= hdr.p4calc.operand_b)
            hdr.p4calc.res = 1;
    }

    action operation_lessorequal() {
        if (hdr.p4calc.operand_a <= hdr.p4calc.operand_b)
            hdr.p4calc.res = 1;
    }

    table calculate {
        key = {
            hdr.p4calc.op        : exact;
        }
        actions = {
            operation_add;
            operation_sub;
            operation_and;
            operation_or;
            operation_xor;
            operation_equal;
            operation_unequal;
            operation_greater;
            operation_less;
            operation_greaterorequal;
            operation_lessorequal;
        }
        const entries = {
            P4CALC_PLUS  : operation_add();
            P4CALC_MINUS : operation_sub();
            P4CALC_AND   : operation_and();
            P4CALC_OR    : operation_or();
            P4CALC_CARET : operation_xor();
            P4CALC_EQL   : operation_equal();
            P4CALC_UNEQL : operation_unequal();
            P4CALC_GRTR  : operation_greater();
            P4CALC_LESS  : operation_less();
            P4CALC_GORE  : operation_greaterorequal();
            P4CALC_LORE  : operation_lessorequal();
        }
    }

    apply {
        calculate.apply();
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
control EgressDeparserImpl(packet_out packet,
                           out empty_metadata_t recirculate_meta,
                           inout headers_t hdr,
                           in metadata_t meta,
                           in tuna_egress_output_metadata_t istd) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.p4calc);
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
