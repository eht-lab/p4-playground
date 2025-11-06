#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
# Reason-GPL: import-scapy

import re
import ast
import operator
#import numpy as np  # 用于处理按位取反
import sys

from scapy.all import (
    Ether,
    IntField,
    Packet,
    StrFixedLenField,
    XByteField,
    bind_layers,
    srp1,
    sendp,
    Raw,
    hexdump
)

iface = 'eth0'
dst_mac="62:9b:0c:db:ac:20"

def safe_eval(expr):
    # 允许的操作符
    allowed_ops = {
        ast.Add: operator.add,
        ast.Sub: operator.sub,
        ast.BitAnd: operator.and_,
        ast.BitOr: operator.or_,
        ast.BitXor: operator.xor,
        ast.Invert: lambda x: ~int(x),  # 按位取反
        ast.Lt: operator.lt,
        ast.LtE: operator.le,
        ast.Gt: operator.gt,
        ast.GtE: operator.ge,
        ast.Eq: operator.eq,
        ast.NotEq: operator.ne,
        ast.USub: operator.neg,  # 负号
    }
    
    def _eval(node):
        if isinstance(node, ast.Num):  # 数字
            return node.n
        elif isinstance(node, ast.BinOp):  # 二元运算
            left = _eval(node.left)
            right = _eval(node.right)
            return allowed_ops[type(node.op)](left, right)
        elif isinstance(node, ast.UnaryOp):  # 一元运算（取反、负号）
            operand = _eval(node.operand)
            return allowed_ops[type(node.op)](operand)
        elif isinstance(node, ast.Compare):  # 比较运算
            left = _eval(node.left)
            for op, comparator in zip(node.ops, node.comparators):
                right = _eval(comparator)
                if not allowed_ops[type(op)](left, right):
                    return False
                left = right
            return True
        else:
            raise ValueError(f"不支持的表达式类型: {type(node).__name__}")
    
    try:
        node = ast.parse(expr, mode='eval')
        return _eval(node.body)
    except (SyntaxError, ValueError, KeyError) as e:
        raise ValueError(f"无效表达式: {e}")

# Define custom packet class for P4calc
class P4calc(Packet):
    name = "P4calc"
    # Define fields for the P4calc packet
    fields_desc = [ StrFixedLenField("P", "P", length=1),
                    StrFixedLenField("Four", "4", length=1),
                    XByteField("version", 0x01),
                    StrFixedLenField("op", "+", length=2),
                    IntField("operand_a", 0),
                    IntField("operand_b", 0),
                    IntField("result", 0)]

# Bind custom packet class to Ethernet type 0x1234
bind_layers(Ether, P4calc, type=0x1234)

# Custom exception for number parsing error
class NumParseError(Exception):
    pass

# Custom exception for operator parsing error
class OpParseError(Exception):
    pass

# Token class for representing parsed tokens
class Token:
    def __init__(self, type, value=None):
        self.type = type
        self.value = value

# Parser function for parsing number literals
def num_parser(s, i, ts):
    pattern = r"^\s*([0-9]+)\s*"
    match = re.match(pattern,s[i:])
    if match:
        ts.append(Token('num', match.group(1)))
        return i + match.end(), ts
    raise NumParseError('Expected number literal.')

# Parser function for parsing binary operators
def op_parser(s, i, ts):
    pattern = r"^\s*((>=)|(<=)|(==)|(!=)|[-+&|^~<>])\s*"
    match = re.match(pattern,s[i:])
    if match:
        operator = next((g for g in match.groups() if g is not None), None)
        ts.append(Token('op', operator))
        return i + match.end(), ts
    raise OpParseError("Expected binary operator like '>=', '<=', '==', '!=', '-', '+', '&', '|', '~', '^', '<', or '>'.")

# Function to create a sequence of parsers
def make_seq(p1, p2):
    def parse(s, i, ts):
        i,ts2 = p1(s,i,ts)
        return p2(s,i,ts2)
    return parse


def main():
    p = make_seq(num_parser, make_seq(op_parser,num_parser))  # Create parser for number and operator sequence
    s = ''
    flag = True

    while True:
        try:
            s = input('> ')
            s = s.replace(" ", "")
            if s == "quit":
                ts[1].value = "qu"
            else:
                print(s)
                true_result = safe_eval(s)

                i,ts = p(s,0,[])
                if (ts[1].value == '&' or ts[1].value == '|'):
                    ts[2].value = 15
                    print("warning: & and | operators only support fixed number, so operand_b is always 0xF.")

            # Construct packet using parsed tokens
            pkt = Ether(dst=dst_mac, type=0x1234) / P4calc(op=ts[1].value,
                                              operand_a=int(ts[0].value),
                                              operand_b=int(ts[2].value))

            pkt = pkt/Raw(load="P4calc test")
            hexdump(pkt)

            if s == "quit":
                sendp(pkt, iface=iface)
                break

            resp = srp1(pkt, iface=iface, timeout=1, verbose=False)  # Send packet and receive response
            if resp:
                p4calc=resp[P4calc]
                if p4calc:
                    print("result is : ", p4calc.result)  # Print the result from the response packet
                    if p4calc.result != true_result:
                        flag = False
                        print("result is failed")
                else:
                    flag = False
                    print("cannot find P4calc header in the packet")
            else:
                flag = False
                print("Didn't receive response")
        except Exception as error:
            flag = False
            print(error)  # Print any exceptions that occur during parsing or packet handling
        except EOFError:
            break  # Exit the loop gracefully on EOF


    if flag == False:
        print("calculator test failed!")
    else:
        print("calculator test success!")

if __name__ == '__main__':
    main()
