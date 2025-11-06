#!/bin/bash

source ../../../test/cmd_api.sh

# 主函数
test() {
    local test_name="ping"
    local result=0
    print_info "${test_name}开始测试..."

    # topo1测试：两个同网段主机的网卡直连
    print_info "测试topology1.json..."
    log_file="${test_name}_topo1.log"
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

    # topo2测试：三个同网段主机的网卡通过一个bridge连接
    print_info "测试topology2.json..."
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

    # topo3测试：四个同网段主机的网卡分两组，组内由一个bridge连接，两个bridge直连
    print_info "测试topology3.json..."
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
        print_info "${test_name}测试通过"
        return 0
    else
        print_error "${test_name}测试失败"
        return 1
    fi
}

# 执行主函数
test
