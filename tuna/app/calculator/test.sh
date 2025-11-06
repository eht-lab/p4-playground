#!/bin/bash

source ../../../test/cmd_api.sh

# 主函数
test() {
    local test_name="calculator"
    local result=0
    print_info "${test_name}开始测试..."

    # topo1测试：两个同网段主机的网卡直连
    log_file="${test_name}.log"
    recv_log="recv.log"
    send_log="send.log"
    rm -f $recv_log $send_log
    {
        make << EOF
        h2 python3 recv.py > $recv_log 2>&1 &
        h1 sleep 1
        h1 echo -e "\
            10+1\n\
            10-1\n\
            63&15\n\
            64|15\n\
            63^15\n\
            10>1\n\
            10<1\n\
            10>=1\n\
            10<=1\n\
            10==10\n\
            10!=1\n\
            quit"\
            | python3 send.py > $send_log 2>&1
        h1 sleep 1
        exit
EOF
        make stop
    } > "$log_file" 2>&1
    check_log_result "$send_log" "calculator test success!" "total result is" || result=1

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
