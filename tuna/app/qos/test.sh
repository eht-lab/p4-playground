#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

source ../../../test/cmd_api.sh

test() {
    local test_name="qos"
    local result=0
    print_info "${test_name} start testing..."

    # topology1: The NICs of two hosts on the same network segment are directly connected
    log_file="${test_name}.log"
    recv_log="recv.log"
    send_log="send.log"
    rm -f *.log >/dev/null 2>&1
    make clean >/dev/null 2>&1 || true
    {
        make << EOF
        h2 python3 recv.py > $recv_log 2>&1 &
        h2 sleep 1
        h1 python3 send.py 10.0.1.2 Dot1Q 0 2 >> $send_log 2>&1
        h1 python3 send.py 10.0.1.2 Dot1Q 1 2 >> $send_log 2>&1
        h1 python3 send.py 10.0.1.2 Dot1Q 2 2 >> $send_log 2>&1
        h1 python3 send.py 10.0.1.2 IPv4  0 2 >> $send_log 2>&1
        h1 python3 send.py 10.0.1.2 IPv4  1 2 >> $send_log 2>&1
        h1 python3 send.py 10.0.1.2 IPv4  2 2 >> $send_log 2>&1
        exit
EOF
        make stop
    } > "$log_file" 2>&1
    check_log_result "logs/n1.log" "tuna_egress_output_metadata.ochan: 1" "ochan mapping" -12 || result=1
    check_log_result "logs/n2.log" "tuna_ingress_output_metadata.icos: 4" "Dot1Q pcp 1 test" 2 || result=1
    check_log_result "logs/n2.log" "tuna_ingress_output_metadata.ocos: 3" "Dot1Q pcp 2 test" 2 || result=1
    check_log_result "logs/n2.log" "tuna_ingress_output_metadata.icos: 2" "IPv4 dscp 1 test" 2 || result=1
    check_log_result "logs/n2.log" "tuna_ingress_output_metadata.ocos: 1" "IPv4 dscp 2 test" 2 || result=1
    check_log_result "logs/n2.log" "tuna_ingress_output_metadata.icos: 0" "Dot1Q/IPv4 pcp/dscp 0 test" -4 || result=1

    if [ $result -eq 0 ]; then
        print_info "${test_name} test passed"
        echo "P4 Test Success." >> "$log_file"
        return 0
    else
        print_error "${test_name} test failed"
        return 1
    fi
}

test
