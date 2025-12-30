#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

source ../../../test/cmd_api.sh

test() {
    local test_name="ecn"
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
        h1 sleep 1
        h1 python3 send.py 10.0.1.2 10 > $send_log 2>&1 &
        h1 sleep 2
        h2 iperf -s -u &
        h1 sleep 2
        h1 iperf -c 10.0.1.2 -t 3 -u -b 10m
        h1 sleep 6
        exit
EOF
        make stop
    } > "$log_file" 2>&1
    check_log_result "$send_log" "tos       = 0x1" "send pkt with ecn=1" || result=1
    check_log_result "$recv_log" "tos       = 0x1" "recv pkt with ecn=1" -1 || result=1
    check_log_result "logs/n2.log" "tuna_ingress_output_metadata.ecn: 1" "meta.ecn=1" -1 || result=1

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
