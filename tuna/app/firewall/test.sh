#!/bin/bash

source ../../../test/cmd_api.sh

# 主函数
test() {
    local test_name="firewall"
    local result=0
    print_info "${test_name}开始测试..."

    # topo1测试：三个同网段主机的网卡通过一个bridge连接
    log_file="${test_name}.log"
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
        print_info "${test_name}测试通过"
        return 0
    else
        print_error "${test_name}测试失败"
        return 1
    fi
}

# 执行主函数
test
