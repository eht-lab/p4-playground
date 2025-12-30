#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

source ../../../test/cmd_api.sh

test() {
    local test_name="multicast"
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
        h1 python3 send.py 62:9b:0c:db:ac:20 10.0.1.2 2 >> $send_log 2>&1
        h1 python3 send.py 01:00:5e:00:01:02 224.0.1.2 2 >> $send_log 2>&1
        h1 python3 send.py 01:00:5e:00:02:04 239.0.2.4 2 >> $send_log 2>&1
        exit
EOF
        make stop
    } > "$log_file" 2>&1
    check_log_result "logs/n2.log" "tuna_ingress_output_metadata.mc: 1" "identify multicast packets" 4 || result=1
    check_log_result "logs/n2.log" "tuna_ingress_output_metadata.mc: 0" "identify normal packets" -2 || result=1
    check_log_result "logs/n2.log" "tuna_ingress_output_metadata.drop: 1" "drop unmatched multicast packets" 2 || result=1
    check_log_result "logs/n2.log" "tuna_ingress_output_metadata.drop: 0" "transmit matched multicast packets and normal packets" -4 || result=1

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
