#!/bin/bash

PROJECT_PATH="$PWD/../.."

# 颜色输出函数
print_info() {
    echo -e "\033[32m[INFO]\033[0m $1"
}

print_error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
}

print_warning() {
    echo -e "\033[33m[WARNING]\033[0m $1"
}

# 检查log文件中是否有预期打印，支持检查匹配次数
# 参数说明：
# $1: 日志文件路径
# $2: 期望匹配的字符串
# $3: 测试名称
# $4: 匹配次数（可选，默认1次）
check_log_result() {
    local log_file=$1
    local expect=$2
    local test_name=$3
    local count=${4:-1}

    local match_count=$(grep -c "$expect" "$log_file")
    if [ $match_count -eq $count ]; then
        print_info "$test_name success"
        return 0
    else
        print_error "$test_name fail"
        return 1
    fi
}
