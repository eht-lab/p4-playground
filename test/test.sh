#!/bin/bash

echo "测试结果" > report

test_all() {
    sudo -s << EOF
        source cmd_api.sh
        index=1

        # 进入模拟器运行环境
        source p4setup.bash

        # 获取目录列表并处理每个目录
        report_path=\$PROJECT_PATH/p4-playground/test/report
        dirs=\$(ls -1 \$PROJECT_PATH/p4-playground/tuna/app)
        for case_name in \$dirs; do
            dir_path="\$PROJECT_PATH/p4-playground/tuna/app/\$case_name"
            # 检查是否为目录
            if [ -d \$dir_path ]; then
                print_info "测试: \$case_name"
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
        print_info "测试结果保存在./report文件中"

        # 退出模拟器运行环境
        deactivate
EOF
}

test_single() {
    app_or_sample=$1
    case_name=$2
    export app_or_sample case_name

    sudo -E -s << EOF
        source cmd_api.sh

        # 进入模拟器运行环境
        source p4setup.bash

        if [ \$app_or_sample = "app" ]; then
            dir_path="\$PROJECT_PATH/p4-playground/tuna/app/\$case_name"
        else
            dir_path="\$PROJECT_PATH/p4-playground/tuna/samples/\$case_name"
        fi

        report_path=\$PROJECT_PATH/p4-playground/test/report

        # 检查是否为目录
        if [ -d \$dir_path ]; then
            print_info "测试: \$case_name"
            cd \$dir_path
            ./test.sh
            if [ \$? -eq 0 ]; then
                printf "\033[32m%-20s %s\033[0m\n" "\$case_name" "PASS" >> \$report_path
            else
                printf "\033[31m%-20s %s\033[0m\n" "\$case_name" "FAILED" >> \$report_path
            fi
        fi
        print_info "测试结果保存在./report文件中"

        # 退出模拟器运行环境
        deactivate
EOF
}

# 解析参数并执行
if [ $# -eq 0 ]; then
    test_all
else
    test_single "$1" "$2"
fi
