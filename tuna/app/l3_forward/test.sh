#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

source ../../../test/cmd_api.sh

test() {
    local test_name="l3_forward"
    local result=0
    print_info "${test_name} start testing..."

    # topology1: The NICs of two hosts on different network segments are directly connected
    log_file="${test_name}.log"
    rm -f *.log >/dev/null 2>&1
    make clean >/dev/null 2>&1 || true
    {
        make << EOF
        h1 ping h2 -c 2 -W 5
        h2 ping h1 -c 3 -W 5
        pingall
        exit
EOF
        make stop
    } > "$log_file" 2>&1
    check_log_result "$log_file" "2 packets transmitted, 2 received" "h1 ping h2" || result=1
    check_log_result "$log_file" "3 packets transmitted, 3 received" "h2 ping h1" || result=1
    check_log_result "$log_file" "(2/2 received)" "pingall" || result=1

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
