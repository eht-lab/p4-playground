#!/bin/bash

source ../../../test/cmd_api.sh

# 主函数
test() {
    local test_name="l3_forward"
    local result=0
    print_info "${test_name}开始测试..."

    # topo1测试：两个不同网段主机的网卡直连
    log_file="${test_name}.log"
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
        print_info "${test_name}测试通过"
        return 0
    else
        print_error "${test_name}测试失败"
        return 1
    fi
}

# 执行主函数
test
