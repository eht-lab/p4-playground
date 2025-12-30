#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

PROJECT_PATH="$PWD/../.."

# Colorful output functions
print_info() {
    echo -e "  \033[32m[INFO]\033[0m $1"
}

print_error() {
    echo -e "  \033[31m[ERROR]\033[0m $1"
}

print_warning() {
    echo -e "  \033[33m[WARNING]\033[0m $1"
}

# Check if the log file contains the expected output, supports checking match count
# Parameter description:
# $1: Log file path
# $2: Expected matching string
# $3: Test name
# $4: Match count (optional, default value is 1)
#     - Positive integer n: Requires the actual match count to be strictly equal to n
#     - -x (x is a positive integer): Requires the actual match count to be greater than or equal to x
check_log_result() {
    local log_file=$1
    local expect=$2
    local test_name=$3
    local count=${4:-1}

    if [ ! -f "$log_file" ]; then
        print_error "$test_name fail"
        return 1
    fi

    local match_count=$(grep -c "$expect" "$log_file")
    local match_success=0

    if [[ "$count" =~ ^-[0-9]+$ ]]; then
        local x=${count#-}
        if [ "$match_count" -ge "$x" ]; then
            match_success=1
        fi
    else
        if [ "$match_count" -eq "$count" ]; then
            match_success=1
        fi
    fi

    if [ "$match_success" -eq 1 ]; then
        print_info "$test_name success"
        return 0
    else
        print_error "$test_name fail"
        return 1
    fi
}
