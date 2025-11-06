#!/bin/bash

source ../../../test/cmd_api.sh

# 主函数
test() {
    local test_name="tunnel"
    local result=0
    print_info "${test_name}开始测试..."

    # topo1测试：两个同网段主机的网卡直连，主机配置私网IP，网卡上通过公网IP连接
    log_file="${test_name}.log"
    rm pcaps/*.txt | true
    {
        make << EOF
        h1 ping h2 -c 2 -W 5
        exit
EOF
        make stop
    } > "$log_file" 2>&1
    check_log_result "$log_file" "2 packets transmitted, 2 received" "h1 ping h2" || result=1
    check_log_result "./logs/n1.log" "Deparsing header 'innerIpv4'" "encap ipv4" 4 || result=1
    check_log_result "./logs/n1.log" "Deparsing header 'gre'" "encap gre" 2 || result=1
    check_log_result "./logs/n2.log" "Deparsing header 'ipv4'" "decap ipv4" 2 || result=1
    check_log_result "./logs/n2.log" "Deparsing header 'gre'" "decap gre" 2 || result=1

    # pcap: h1 to n1
    pcap_name="pcaps/n1-eth1_in"
    tshark -r ${pcap_name}.pcap -T fields -e ip.src -e ip.dst -e ip.proto -E separator=, -E quote=d > ${pcap_name}.txt
    check_log_result "${pcap_name}.txt" "\"192.168.1.3\",\"192.168.1.2\",\"1\"" "h1 to n1 pcap" 2 || result=1
    # pcap: n1 to n2
    pcap_name="pcaps/n1-eth0_out"
    tshark -r ${pcap_name}.pcap -T fields -e ip.src -e ip.dst -e ip.proto -E separator=, -E quote=d > ${pcap_name}.txt
    check_log_result "${pcap_name}.txt" "\"10.0.1.3,192.168.1.3\",\"10.0.1.2,192.168.1.2\",\"47,1\"" "n1 to n2 pcap" 2 || result=1
    # pcap: n2 to h2
    pcap_name="pcaps/n2-eth1_out"
    tshark -r ${pcap_name}.pcap -T fields -e ip.src -e ip.dst -e ip.proto -E separator=, -E quote=d > ${pcap_name}.txt
    check_log_result "${pcap_name}.txt" "\"192.168.1.3\",\"192.168.1.2\",\"1\"" "n2 to h2 pcap" 2 || result=1

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
