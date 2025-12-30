#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

source ../../../test/cmd_api.sh

test() {
    local test_name="rss"
    local result=0
    print_info "${test_name} start testing..."

    # topology1: The NICs of two hosts on the same network segment are directly connected
    log_file="${test_name}.log"
    recv_log="recv.log"
    send_log1="send1.log"
    send_log2="send2.log"
    rm -f *.log >/dev/null 2>&1
    make clean >/dev/null 2>&1 || true
    {
        make << EOF
        h1 python3 recv.py > $recv_log 2>&1 &
        h1 sleep 1
        h2 python3 send.py 10.0.1.1 5 > $send_log1 2>&1
        h2 sleep 1
        h3 python3 send.py 10.0.1.1 5 > $send_log2 2>&1
        h3 sleep 1
        exit
EOF
        make stop
    } > "$log_file" 2>&1
    check_log_result "logs/n1.log" "tuna_ingress_output_metadata.dst_qid: 1" "set h2 packet dst_qid as 1" 5 || result=1
    check_log_result "logs/n1.log" "tuna_ingress_output_metadata.dst_qid: 2" "set h3 packet dst_qid as 2" 5 || result=1

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
