#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

source ../../../test/cmd_api.sh

test() {
    local test_name="firewall"
    local result=0
    print_info "${test_name} start testing..."

    # topology1: The NICs of three hosts on the same network segment are connected via a bridge
    log_file="${test_name}.log"
    rm -f *.log >/dev/null 2>&1
    make clean >/dev/null 2>&1 || true
    {
        make << EOF
        h1 ping h2 -c 2 -W 5
        h1 ping h3 -c 3 -W 5
        h2 ping h3 -c 4 -W 5
        pingall
        exit
EOF
        make stop
    } > "$log_file" 2>&1
    check_log_result "$log_file" "2 packets transmitted, 0 received" "h1 cannot ping h2" || result=1
    check_log_result "$log_file" "3 packets transmitted, 3 received" "h1 ping h3" || result=1
    check_log_result "$log_file" "4 packets transmitted, 0 received" "h2 cannot ping h3" || result=1
    check_log_result "$log_file" "h1 -> X h3" "h1 test pingall" || result=1
    check_log_result "$log_file" "h2 -> X X" "h2 test pingall" || result=1
    check_log_result "$log_file" "h3 -> h1 X" "h3 test pingall" || result=1
    check_log_result "$log_file" "(2/6 received)" "pingall result" || result=1

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
