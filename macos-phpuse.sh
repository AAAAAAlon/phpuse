#!/bin/bash

# 在脚本开头定义当前版本号
CURRENT_VERSION="v1.0.0"

# 定义颜色变量
COLOR_RED="\033[1;31m"    # 红色
COLOR_CYAN="\033[1;36m"   # 亮青色
COLOR_YELLOW="\033[1;33m"     # 亮黄色
COLOR_BLUE="\033[1;34m"    # 亮蓝色
COLOR_RESET="\033[0m"      # 重置颜色

dangerMsg(){
  echo -e "${COLOR_RED}$1${COLOR_RESET}"
}
infoMsg(){
  echo -e "${COLOR_CYAN}$1${COLOR_RESET}"
}
warningMsg(){
  echo -e "${COLOR_YELLOW}$1${COLOR_RESET}"
}
primaryMsg(){
  echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
}

# 新增帮助函数
usage() {
    infoMsg "PHP 版本管理工具 (Mac版) v${CURRENT_VERSION}"
    warningMsg "用法:"
    echo "  phpuse list               # 列出已安装的 PHP 版本"
    echo "  phpuse <版本号>           # 切换到指定 PHP 版本"
    echo "  phpuse install <版本号>  # 安装指定 PHP 版本"
    echo "  phpuse self-update        # 更新 phpuse"
    echo "  phpuse -v                 # 显示当前版本"
    warningMsg "示例:"
    echo "  phpuse list"
    echo "  phpuse php@8.1"
    echo "  phpuse install php@8.2"
    echo "  phpuse self-update"
    echo "  phpuse -v"
}

# 显示版本函数
show_version() {
    echo ''
    infoMsg '  _____  _    _  _____  _    _  _____ ______ '
    infoMsg ' |  __ \| |  | ||  __ \| |  | |/ ____|  ____|'
    infoMsg ' | |__) | |__| || |__) | |  | | (___ | |__   '
    infoMsg ' |  ___/|  __  ||  ___/| |  | |\___ \|  __|  '
    infoMsg ' | |    | |  | || |    | |__| |____) | |____ '
    infoMsg ' |_|    |_|  |_||_|     \____/|_____/|______|'
    echo ''
    warningMsg "版本: ${CURRENT_VERSION}"
    primaryMsg "GitHub: https://github.com/AAAAAAlon/phpuse"
    exit 0
}

# 自我更新函数
self_update() {
    infoMsg "请选择更新源:"
    echo "1) GitHub (国际用户推荐)"
    echo "2) Gitee (中国大陆用户推荐)"
    echo -e "${COLOR_YELLOW}"
    read -rp "请输入选择 [1-2]: " source_choice
    echo -e "${COLOR_RESET}"

    case $source_choice in
        1)
            infoMsg "使用 GitHub 源进行更新..."
            SCRIPT_URL="https://github.com/AAAAAAlon/phpuse/releases/latest/download/macos-phpuse.sh"
            VERSION_URL="https://raw.githubusercontent.com/AAAAAAlon/phpuse/master/mac/version.txt"
            ;;
        2)
            infoMsg "使用 Gitee 源进行更新..."
            SCRIPT_URL="https://gitee.com/ashin_33/phpuse/releases/download/latest/macos-phpuse.sh"
            VERSION_URL="https://gitee.com/ashin_33/phpuse/raw/master/mac/version.txt"
            ;;
        *)
            dangerMsg "无效选择，更新取消"
            exit 1
            ;;
    esac

    echo "正在检查更新..."

    # 获取远程版本号
    REMOTE_VERSION=$(curl -sSL "$VERSION_URL" | head -n 1 | tr -d '\n')

    if [ -z "$REMOTE_VERSION" ]; then
        dangerMsg "错误：无法获取远程版本号"
        exit 1
    fi

    infoMsg "当前版本: ${CURRENT_VERSION}"
    warningMsg "最新版本: ${REMOTE_VERSION}"

    # 比较版本号
    if [ "$CURRENT_VERSION" = "$REMOTE_VERSION" ]; then
        warningMsg "当前已是最新版本。"
        exit 0
    fi

    # 使用 sort -V 进行版本比较
    HIGHER_VERSION=$(echo  "$CURRENT_VERSION\n$REMOTE_VERSION" | sort -V | tail -n1)

    if [ "$HIGHER_VERSION" = "$CURRENT_VERSION" ]; then
        warningMsg "当前版本比远程版本还新，无需更新。"
        exit 0
    fi

    infoMsg "发现新版本，正在更新..."
    TEMP_FILE=$(mktemp)

    # 下载最新版本
    if curl -sSL "$SCRIPT_URL" > "$TEMP_FILE"; then
        # 替换为最新版本
        chmod +x "$TEMP_FILE"
        sudo mv "$TEMP_FILE" "$0"
        infoMsg "更新成功！请重新运行脚本以使用新版本。"
    else
        dangerMsg "错误：无法下载最新版本"
        rm -f "$TEMP_FILE"
        exit 1
    fi
    exit 0
}

# 检查是否安装了 Homebrew
check_homebrew() {
    if ! command -v brew &> /dev/null; then
        dangerMsg "错误：Homebrew 未安装，请先安装 Homebrew"
        dangerMsg "请使用以下命令安装 HomeBrew "
        echo ""
        warningMsg '/bin/zsh -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"'
        echo ""
        exit 1
    fi
}

# 列出已安装的 PHP 版本函数
list_installed_php_versions() {
    check_homebrew

    infoMsg "已安装的 PHP 版本:"

    # 获取通过 Homebrew 安装的所有 PHP 版本
    local installed_versions=$(brew list --formula | grep -E '^php(@[0-9.]+)?$')

    # 获取当前链接的 PHP 版本
    # shellcheck disable=SC2155
    local current_version=$(php -v 2>/dev/null | head -n 1 | grep -o -E '[0-9]+\.[0-9]+' || echo "")

    # 检查是否安装了 php
    if [ -z "$installed_versions" ]; then
        dangerMsg "未找到通过 Homebrew 安装的 PHP 版本"
        return
    fi

    # 显示已安装的版本
    for version in $installed_versions; do
        # 处理标准php包（非版本化的php）
        if [ "$version" = "php" ]; then
            # 获取标准php包的实际版本号
            local ver=$(brew info php --json | jq -r '.[0].linked_keg')
            # 显示为"php"而不是具体版本号
            display_name="php"
        else
            # 处理版本化的php包（如php@8.1）
            local ver=$(echo $version | sed 's/php@//')
            display_name="$version"
        fi

        # 标记当前正在使用的版本
        if [ "$ver" = "$current_version" ]; then
            echo "  * ${display_name} (当前使用)"
        else
            echo "  - ${display_name}"
        fi
    done

    # 显示 PHP-FPM 服务状态
    echo ""
    infoMsg  "PHP-FPM 服务状态:"
    if brew services list | grep -q 'php'; then
        brew services list | grep 'php' | while read -r service; do
            echo "  $service"
        done
    else
        warningMsg "  没有运行的 PHP-FPM 服务"
    fi
}

# 安装 PHP 版本函数
install_php_version() {
    check_homebrew

    local version=$1
    infoMsg "准备安装 PHP ${version}..."

    # 检查是否已安装
    if brew list --formula | grep -q -E "^php@${version}"; then
        warningMsg "PHP ${version} 已经安装"
        return 0
    fi

    # 添加 Homebrew tap
    brew tap shivammathur/php

    infoMsg "安装 PHP ${version}..."
    brew install shivammathur/php/php@${version}

    # 验证安装
    if brew list --formula | grep -q -E "^php@${version}"; then
        infoMsg "PHP ${version} 安装成功!"

        # 提示用户运行 link 命令
        infoMsg "请运行以下命令链接 PHP ${version}:"
        infoMsg "brew link --overwrite --force ${version}"
    else
        dangerMsg "${version} 安装失败!"
        exit 1
    fi
}

# 停止所有运行的 PHP-FPM 服务
stop_running_php_services() {
    infoMsg "正在停止所有运行的 PHP-FPM 服务..."

    # 获取所有非 none 状态的 PHP 服务
    # shellcheck disable=SC2155
    local running_services=$(brew services list | grep -E '(php@[0-9.]+|php)\s+' | grep -v 'none' | awk '{print $1}')

    if [ -n "$running_services" ]; then
        for service in $running_services; do
            brew services stop "$service"
        done
    else
        warningMsg "没有正在运行的 PHP-FPM 服务"
    fi
}

changeVersion() {
  # 版本切换逻辑
          local PHP_VERSION=$1
          check_homebrew

          # 检查是否安装了该版本
          if ! brew list --formula | grep -q -E "^${PHP_VERSION}"; then
              dangerMsg "错误：找不到 ${PHP_VERSION} 的安装"
              dangerMsg "请确认已安装 ${PHP_VERSION} 或者使用 'phpuse install ${PHP_VERSION}' 安装"
              exit 1
          fi

          # 执行版本切换
          infoMsg "正在切换到 ${PHP_VERSION}..."
          brew link --overwrite --force ${PHP_VERSION}

          # 检查命令是否执行成功
          if [ $? -ne 0 ]; then
              dangerMsg "切换 PHP 版本失败"
              exit 1
          fi

          # 停止所有 PHP-FPM 服务
          stop_running_php_services
          # 启动当前版本的 PHP-FPM
          brew services start ${PHP_VERSION}

          # 显示最终结果
          echo ""
          infoMsg "已成功切换到 ${PHP_VERSION}"
          php -v
}


# 主逻辑
echo ""
case "$1" in
    list)
        list_installed_php_versions
        exit 0
        ;;
    install)
        if [ -z "$2" ]; then
            dangerMsg "错误：请提供要安装的 PHP 版本号"
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
    php*)
      changeVersion "$1"
      ;;
    *)
      dangerMsg "无效命令"
      warningMsg "运行 phpuse -h 查看可用命令"

esac
