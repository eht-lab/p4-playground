#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

echo "Test Results" > report

test_all() {
    sudo bash << EOF
        source cmd_api.sh
        index=1

        # Enter simulator environment
        source p4setup.bash

        # Get directory list and process each directory
        report_path=\$PROJECT_PATH/p4-playground/test/report
        dirs=\$(ls -1 \$PROJECT_PATH/p4-playground/tuna/app)
        for case_name in \$dirs; do
            dir_path="\$PROJECT_PATH/p4-playground/tuna/app/\$case_name"
            # Check if it is a directory
            if [ -d \$dir_path ]; then
                print_info "Testing: \$case_name"
                cd \$dir_path
                ./test.sh
                if [ \$? -eq 0 ]; then
                    printf "\033[32m%-20s %s\033[0m\n" "\$index. \$case_name" "PASS" >> \$report_path
                else
                    printf "\033[31m%-20s %s\033[0m\n" "\$index. \$case_name" "FAILED" >> \$report_path
                fi
                index=\$((index + 1))
            fi
        done
        print_info "Test results saved in ./report file"

        # Exit simulator environment
        deactivate
EOF
}

test_single() {
    app_or_sample=$1
    case_name=$2
    export app_or_sample case_name

    sudo -E bash << EOF
        source cmd_api.sh

        # Enter simulator environment
        source p4setup.bash

        if [ \$app_or_sample = "app" ]; then
            dir_path="\$PROJECT_PATH/p4-playground/tuna/app/\$case_name"
        else
            dir_path="\$PROJECT_PATH/p4-playground/tuna/samples/\$case_name"
        fi

        report_path=\$PROJECT_PATH/p4-playground/test/report

        # Check if it is a directory
        if [ -d \$dir_path ]; then
            print_info "Testing: \$case_name"
            cd \$dir_path
            ./test.sh
            if [ \$? -eq 0 ]; then
                printf "\033[32m%-20s %s\033[0m\n" "\$case_name" "PASS" >> \$report_path
            else
                printf "\033[31m%-20s %s\033[0m\n" "\$case_name" "FAILED" >> \$report_path
            fi
        fi
        print_info "Test results saved in ./report file"

        # Exit simulator environment
        deactivate
EOF
}

# Parse arguments and execute
if [ $# -eq 0 ]; then
    test_all
else
    test_single "$1" "$2"
fi
