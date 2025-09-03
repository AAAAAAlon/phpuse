# 说明

> 该脚本用于切换ubuntu系统或mac系统中的php版本,后续安装扩展之类的动作可继续使用apt或者pecl等操作
 
- [x] ubuntu apt
- [x] macos brew

# 安装

## ubuntu

### github 安装

```bash
sudo curl -L -o "phpuse.sh" "https://github.com/AAAAAAlon/phpuse/releases/latest/download/ubuntu-phpuse.sh"
sudo mv phpuse.sh /usr/local/bin/phpuse
sudo chmod +x /usr/local/bin/phpuse
```

### gitee 安装

```bash
sudo curl -L -o "phpuse.sh" "https://gitee.com/ashin_33/phpuse/releases/download/latest/ubuntu-phpuse.sh"
sudo mv phpuse.sh /usr/local/bin/phpuse
sudo chmod +x /usr/local/bin/phpuse
```

# 使用

```bash
phpuse list               # 列出已安装的 PHP 版本
phpuse <版本号>           # 切换到指定 PHP 版本
phpuse install <版本号>  # 安装指定 PHP 版本
phpuse self-update  # 更新phpuse
phpuse -v #获取phpuse版本号
```

## mac

### github 安装

```bash
sudo curl -L -o "phpuse.sh" "https://github.com/AAAAAAlon/phpuse/releases/latest/download/macos-phpuse.sh"
sudo mv phpuse.sh /usr/local/bin/phpuse
sudo chmod +x /usr/local/bin/phpuse
```

### gitee 安装

```bash
sudo curl -L -o "phpuse.sh" "https://gitee.com/ashin_33/phpuse/releases/download/latest/macos-phpuse.sh"
sudo mv phpuse.sh /usr/local/bin/phpuse
sudo chmod +x /usr/local/bin/phpuse
```

# 使用

```bash
phpuse list               # 列出已安装的 PHP 版本
phpuse <版本号>           # 切换到指定 PHP 版本
phpuse install <版本号>  # 安装指定 PHP 版本
phpuse self-update  # 更新phpuse
phpuse -v #获取phpuse版本号
```