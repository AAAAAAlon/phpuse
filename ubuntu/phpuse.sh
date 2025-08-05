#!/bin/bash

# 新增帮助函数
usage() {
    echo "PHP 版本管理工具"
    echo "用法:"
    echo "  phpuse list               # 列出已安装的 PHP 版本"
    echo "  phpuse <版本号>           # 切换到指定 PHP 版本"
    echo "  phpuse install <版本号>  # 安装指定 PHP 版本"
    echo "  phpuse self-update  # 更新phpuse"
    echo "示例:"
    echo "  phpuse list"
    echo "  phpuse 8.1"
    echo "  phpuse install 8.2"
    echo "  phpuse self-update"
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
            echo "使用 GitHub 源进行更新..."
            ;;
        2)
            SCRIPT_URL="https://gitee.com/ashin_33/phpuse/raw/master/ubuntu/phpuse.sh"
            echo "使用 Gitee 源进行更新..."
            ;;
        *)
            echo "无效选择，更新取消"
            exit 1
            ;;
    esac

    echo "正在检查更新..."
    TEMP_FILE=$(mktemp)

    # 下载最新版本
    if curl -sSL "$SCRIPT_URL" > "$TEMP_FILE"; then
        # 比较版本差异
        if ! cmp -s "$0" "$TEMP_FILE"; then
            echo "发现新版本，正在更新..."
            # 备份当前脚本
            BACKUP_FILE="$0.bak.$(date +%Y%m%d%H%M%S)"
            sudo cp "$0" "$BACKUP_FILE"

            # 替换为最新版本
            chmod +x "$TEMP_FILE"
            sudo mv "$TEMP_FILE" "$0"
            echo "更新成功！"
        else
            echo "当前已是最新版本。"
            rm -f "$TEMP_FILE"
        fi
    else
        echo "错误：无法下载最新版本"
        rm -f "$TEMP_FILE"
        exit 1
    fi
    exit 0
}

# 列出已安装的 PHP 版本函数
list_installed_php_versions() {
    echo "已安装的 PHP 版本:"
    # 查找所有已安装的 PHP 版本
    find /usr/bin -name 'php*' -type f -executable | grep -P '/php\d+\.\d+$' | sort -V | while read -r php_path; do
        version=$(basename "$php_path" | sed 's/php//')
        # 检查是否是当前使用的版本
        if [ "$(readlink -f /etc/alternatives/php)" = "$php_path" ]; then
            echo "  * ${version} (当前使用)"
        else
            echo "  - ${version}"
        fi
    done

    # 检查是否有 PHP-FPM 服务
    echo -e "\nPHP-FPM 服务状态:"
    systemctl list-unit-files --type=service | grep -P 'php\d+\.\d+-fpm\.service' | sort -V | while read -r service status; do
        service_name=${service%.service}
        if systemctl is-active --quiet "$service_name"; then
            echo "  * ${service_name} (运行中)"
        else
            echo "  - ${service_name} (未运行)"
        fi
    done
}

# 新增：安装 PHP 版本函数
install_php_version() {
    local version=$1
    echo "准备安装 PHP ${version}..."

    # 检查是否已安装
    if [ -f "/usr/bin/php${version}" ]; then
        echo "PHP ${version} 已经安装"
        return 0
    fi

    # 添加 Ondřej 的 PHP PPA
    if ! grep -q "ondrej/php" /etc/apt/sources.list.d/ondrej-*.list 2>/dev/null; then
        echo "添加 Ondřej PHP PPA..."
        sudo apt-get update
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository -y ppa:ondrej/php
    fi

    echo "安装 PHP ${version} 和相关扩展..."
    sudo apt-get update
    sudo apt-get install -y "php${version}" "php${version}-fpm" "php${version}-cli" \
        "php${version}-common" "php${version}-mbstring" "php${version}-xml" \
        "php${version}-mysql" "php${version}-curl" "php${version}-redis" "php${version}-bcmath"

    # 验证安装
    if [ -f "/usr/bin/php${version}" ]; then
        echo "PHP ${version} 安装成功!"
    else
        echo "PHP ${version} 安装失败!"
        exit 1
    fi
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
