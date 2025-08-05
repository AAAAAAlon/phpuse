# 说明

> 该脚本用于切换ubuntu系统中apt安装的各个php版本,后续安装扩展之类的动作可继续使用apt或者pecl等命名

# 安装

```bash
## github下载
sudo curl -L -O https://raw.githubusercontent.com/AAAAAAlon/phpuse/master/ubuntu/phpuse.sh
## gitee下载
sudo curl -L -O https://gitee.com/ashin_33/phpuse/raw/master/ubuntu/phpuse.sh
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
 