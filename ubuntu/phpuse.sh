#!/bin/bash

# 在脚本开头定义当前版本号
CURRENT_VERSION="1.0.0"

# 新增帮助函数
usage() {
    echo "PHP 版本管理工具 v${CURRENT_VERSION}"
    echo "用法:"
    echo "  phpuse list               # 列出已安装的 PHP 版本"
    echo "  phpuse <版本号>           # 切换到指定 PHP 版本"
    echo "  phpuse install <版本号>  # 安装指定 PHP 版本"
    echo "  phpuse self-update        # 更新phpuse"
    echo "  phpuse -v                 # 显示当前版本"
    echo "示例:"
    echo "  phpuse list"
    echo "  phpuse 8.1"
    echo "  phpuse install 8.2"
    echo "  phpuse self-update"
    echo "  phpuse -v"
}

# 显示版本函数
show_version() {
   local COLOR_TITLE="\033[1;36m"   # 亮青色
   local COLOR_VER="\033[1;33m"     # 亮黄色
   local COLOR_DESC="\033[1;34m"    # 亮蓝色
   local COLOR_RESET="\033[0m"      # 重置颜色

    echo -e "${COLOR_TITLE}"
    echo '  _____  _    _  _____   _    _  _____ ______ '
    echo ' |  __ \| |  | |/ ____| | |  | |/ ____|  ____|'
    echo ' | |__) | |__| | (___   | |  | | (___ | |__   '
    echo ' |  ___/|  __  |\___ \  | |  | |\___ \|  __|  '
    echo ' | |    | |  | |____) | | |__| |____) | |____ '
    echo ' |_|    |_|  |_|_____/   \____/|_____/|______|'
    echo -e "${COLOR_RESET}"
    echo -e "${COLOR_VER}版本: ${CURRENT_VERSION}${COLOR_RESET}"
    echo -e "${COLOR_DESC}GitHub: https://github.com/AAAAAAlon/phpuse${COLOR_RESET}"
    exit 0
}

# 自我更新函数
self_update() {
    echo "请选择更新源:"
    echo "1) GitHub (国际用户推荐)"
    echo "2) Gitee (中国大陆用户推荐)"
    read -p "请输入选择 [1-2]: " source_choice

    case $source_choice in
        1)
            SCRIPT_URL="https://raw.githubusercontent.com/AAAAAAlon/phpuse/master/ubuntu/phpuse.sh"
            VERSION_URL="https://raw.githubusercontent.com/AAAAAAlon/phpuse/master/ubuntu/version.txt"
            echo "使用 GitHub 源进行更新..."
            ;;
        2)
            SCRIPT_URL="https://gitee.com/ashin_33/phpuse/raw/master/ubuntu/phpuse.sh"
            VERSION_URL="https://gitee.com/ashin_33/phpuse/raw/master/ubuntu/version.txt"
            echo "使用 Gitee 源进行更新..."
            ;;
        *)
            echo "无效选择，更新取消"
            exit 1
            ;;
    esac

    echo "正在检查更新..."

    # 获取远程版本号
    REMOTE_VERSION=$(curl -sSL "$VERSION_URL" | head -n 1 | tr -d '\n')

    if [ -z "$REMOTE_VERSION" ]; then
        echo "错误：无法获取远程版本号"
        exit 1
    fi

    echo "当前版本: ${CURRENT_VERSION}"
    echo "最新版本: ${REMOTE_VERSION}"

    # 比较版本号
    if [ "$CURRENT_VERSION" = "$REMOTE_VERSION" ]; then
        echo "当前已是最新版本。"
        exit 0
    fi

    # 使用 sort -V 进行版本比较
    HIGHER_VERSION=$(echo -e "$CURRENT_VERSION\n$REMOTE_VERSION" | sort -V | tail -n1)

    if [ "$HIGHER_VERSION" = "$CURRENT_VERSION" ]; then
        echo "当前版本比远程版本还新，无需更新。"
        exit 0
    fi

    echo "发现新版本，正在更新..."
    TEMP_FILE=$(mktemp)

    # 下载最新版本
    if curl -sSL "$SCRIPT_URL" > "$TEMP_FILE"; then

        # 替换为最新版本
        chmod +x "$TEMP_FILE"
        sudo mv "$TEMP_FILE" "$0"
        echo "更新成功！请重新运行脚本以使用新版本。"
    else
        echo "错误：无法下载最新版本"
        rm -f "$TEMP_FILE"
        exit 1
    fi
    exit 0
}

# 主逻辑
case "$1" in
    list)
        list_installed_php_versions
        exit 0
        ;;
    install)
        if [ -z "$2" ]; then
            echo "错误：请提供要安装的 PHP 版本号"
            usage
            exit 1
        fi
        install_php_version "$2"
        exit 0
        ;;
    self-update)
        self_update
        ;;
    -v|--version)
        show_version
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    "")
        usage
        exit 1
        ;;
    *)
        # 原有的版本切换逻辑保持不变
        PHP_VERSION=$1
        PHP_PATH="/usr/bin/php${PHP_VERSION}"
        PHP_FPM_SERVICE="php${PHP_VERSION}-fpm"

        # 检查目标 PHP 版本是否存在
        if [ ! -f "$PHP_PATH" ]; then
            echo "错误：找不到 PHP ${PHP_VERSION} 的可执行文件"
            echo "请确认已安装 PHP ${PHP_VERSION} 或者使用 'phpuse install ${PHP_VERSION}' 安装"
            exit 1
        fi

        # 执行版本切换
        sudo update-alternatives --set php "$PHP_PATH"

        # 检查命令是否执行成功
        if [ $? -ne 0 ]; then
            echo "切换 PHP 版本失败"
            exit 1
        fi

        # 处理 PHP-FPM 服务
        echo "正在处理 PHP-FPM 服务..."

        # 查找所有正在运行的 php-fpm 服务
        RUNNING_FPM_SERVICES=$(systemctl list-units --type=service --state=running | grep -oP 'php[0-9.]+-fpm\.service' || true)

        # 停止所有正在运行的 php-fpm 服务
        if [ -n "$RUNNING_FPM_SERVICES" ]; then
            echo "发现以下正在运行的 PHP-FPM 服务:"
            echo "$RUNNING_FPM_SERVICES"

            for service in $RUNNING_FPM_SERVICES; do
                # 跳过要启动的目标服务
                if [ "$service" != "${PHP_FPM_SERVICE}.service" ]; then
                    echo "正在停止 $service..."
                    sudo systemctl stop "${service%.service}"
                fi
            done
        fi

        # 启动目标 PHP-FPM 服务
        if systemctl list-unit-files | grep -q "^${PHP_FPM_SERVICE}.service"; then
            echo "正在启动 ${PHP_FPM_SERVICE}..."
            sudo systemctl start "$PHP_FPM_SERVICE"

            # 检查服务状态
            if systemctl is-active --quiet "$PHP_FPM_SERVICE"; then
                echo "已成功启动 ${PHP_FPM_SERVICE}"
            else
                echo "警告：${PHP_FPM_SERVICE} 启动失败，请手动检查"
                sudo systemctl status "$PHP_FPM_SERVICE"
                exit 1
            fi
        else
            echo "警告：找不到 ${PHP_FPM_SERVICE} 服务，跳过 FPM 处理"
        fi

        # 显示最终结果
        echo ""
        echo "已成功切换到 PHP ${PHP_VERSION}"
        php -v
        ;;
esac
