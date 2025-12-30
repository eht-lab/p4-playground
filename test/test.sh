#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

source cmd_api.sh

report_path=$PROJECT_PATH/p4-playground/test/report
echo "Test Results" > $report_path

# Display usage help
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  (no args)                 - Build all test cases (default behavior)"
    echo "  help                      - Show this help message"
    echo "  [dir] [case]              - Run the specified test case in the specified directory"
    echo ""
    echo "Examples:"
    echo "  $0                 # Run all test cases"
    echo "  $0 app l3_forward  # Run l3_forward case in app directory"
    echo ""
}

test_all() {
    index=1

    # Get directory list and process each directory
    echo "app:" >> $report_path
    dirs=$(ls -1 $PROJECT_PATH/p4-playground/tuna/app)
    for case_name in $dirs; do
        dir_path="$PROJECT_PATH/p4-playground/tuna/app/$case_name"
        # Check if it is a directory
        if [ -d $dir_path ]; then
            printf "[$index] Testing: $case_name\n"
            cd $dir_path
            ./test.sh
            if [ $? -eq 0 ]; then
                printf "\033[32m%-20s %s\033[0m\n" "$index. $case_name" "PASS" >> $report_path
            else
                printf "\033[31m%-20s %s\033[0m\n" "$index. $case_name" "FAILED" >> $report_path
            fi
            index=$((index + 1))
        fi
    done

    printf "\nTest results saved in ./report file\n"
}

test_single() {
    dir_name=$1
    case_name=$2

    if [ $dir_name = "app" ]; then
        dir_path="$PROJECT_PATH/p4-playground/tuna/app/$case_name"
    else
        return
    fi

    # Check if it is a directory
    if [ -d $dir_path ]; then
        printf "Testing: $case_name\n"
        cd $dir_path
        ./test.sh
        if [ $? -eq 0 ]; then
            printf "\033[32m%-20s %s\033[0m\n" "$case_name" "PASS" >> $report_path
        else
            printf "\033[31m%-20s %s\033[0m\n" "$case_name" "FAILED" >> $report_path
        fi
    fi

    printf "\nTest results saved in ./report file\n"
}

# Parse arguments and execute
if [ $# -eq 0 ]; then
    test_all
elif [ $# -eq 1 ]; then
    if [ $1 = "help" ]; then
        show_usage
    fi
else
    test_single "$1" "$2"
fi
