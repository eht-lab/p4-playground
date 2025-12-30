#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

source ../../../test/cmd_api.sh

test() {
    local test_name="ping"
    local result=0
    print_info "${test_name} start testing..."

    # topology1: The NICs of two hosts on the same network segment are directly connected
    print_info "testing topology1.json..."
    log_file="${test_name}_topo1.log"
    rm -f *.log >/dev/null 2>&1
    make clean >/dev/null 2>&1 || true
    {
        make TOPO=topology1.json << EOF
        h1 ping h2 -c 2 -W 5
        h2 ping h1 -c 3 -W 5
        pingall
        exit
EOF
        make stop
    } > "$log_file" 2>&1
    check_log_result "$log_file" "2 packets transmitted, 2 received" "h1 ping h2 (topo1)" || result=1
    check_log_result "$log_file" "3 packets transmitted, 3 received" "h2 ping h1 (topo1)" || result=1
    check_log_result "$log_file" "(2/2 received)" "pingall (topo1)" || result=1

    # topology2: The NICs of three hosts on the same network segment are connected via a bridge
    print_info "testing topology2.json..."
    log_file="${test_name}_topo2.log"
    {
        make TOPO=topology2.json << EOF
        h1 ping h2 -c 2 -W 5
        h1 ping h3 -c 3 -W 5
        h3 ping h2 -c 4 -W 5
        pingall
        exit
EOF
        make stop
    } > "$log_file" 2>&1
    check_log_result "$log_file" "2 packets transmitted, 2 received" "h1 ping h2 (topo2)" || result=1
    check_log_result "$log_file" "3 packets transmitted, 3 received" "h1 ping h3 (topo2)" || result=1
    check_log_result "$log_file" "4 packets transmitted, 4 received" "h3 ping h2 (topo2)" || result=1
    check_log_result "$log_file" "(6/6 received)" "pingall (topo2)" || result=1

    # topology3: The NICs of four hosts on the same network segment are divided into two groups.
    #            The NICs within each group are connected by a bridge, and the two bridges are directly connected to each other
    print_info "testing topology3.json..."
    log_file="${test_name}_topo3.log"
    {
        make TOPO=topology3.json << EOF
        h1 ping h2 -c 2 -W 5
        h4 ping h3 -c 3 -W 5
        h2 ping h3 -c 4 -W 5
        h4 ping h1 -c 5 -W 5
        pingall
        exit
EOF
        make stop
    } > "$log_file" 2>&1
    check_log_result "$log_file" "2 packets transmitted, 2 received" "h1 ping h2 (topo3)" || result=1
    check_log_result "$log_file" "3 packets transmitted, 3 received" "h4 ping h3 (topo3)" || result=1
    check_log_result "$log_file" "4 packets transmitted, 4 received" "h2 ping h3 (topo3)" || result=1
    check_log_result "$log_file" "5 packets transmitted, 5 received" "h4 ping h1 (topo3)" || result=1
    check_log_result "$log_file" "(12/12 received)" "pingall (topo3)" || result=1

    if [ $result -eq 0 ]; then
        print_info "${test_name} test passed"
        echo "P4 Test Success." > ping.log
        return 0
    else
        print_error "${test_name} test failed"
        return 1
    fi
}

test
