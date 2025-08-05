#!/bin/bash

# 定义安装目录（通常选择 /usr/local/bin）
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="phpuse"
SCRIPT_SOURCE="phpuse.sh"

# 检查脚本文件是否存在
if [ ! -f "$SCRIPT_SOURCE" ]; then
    echo "错误: 找不到 $SCRIPT_SOURCE 文件"
    exit 1
fi

# 检查安装目录是否存在
if [ ! -d "$INSTALL_DIR" ]; then
    echo "错误: 安装目录 $INSTALL_DIR 不存在"
    exit 1
fi

# 复制脚本到安装目录并设置可执行权限
sudo cp "$SCRIPT_SOURCE" "$INSTALL_DIR/$SCRIPT_NAME"
sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# 检查是否在 PATH 环境变量中
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "注意: $INSTALL_DIR 不在你的 PATH 环境变量中"
    echo "你可能需要将以下行添加到 ~/.bashrc, ~/.zshrc 或 ~/.profile 文件中:"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\""
fi

echo "安装成功! 现在你可以使用 '$SCRIPT_NAME 8.1' 来运行脚本了"