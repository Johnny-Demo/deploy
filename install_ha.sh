#!/bin/bash
# Author: Johnny Lee
# Email: xxx@outlook.com
# Date: 07/18/2022
# Filename: install_ha.sh

# 定义全局变量
ip_groups="192.168.200.1 192.168.200.2 192.168.200.3"

# 安装 keepalived 和 haproxy
for service in $ip_groups;
do
    ssh root@$service yum -y install keepalived haproxy
    ssh root@$service systemctl enable keepalived && systemctl enable haproxy
done

# 调用脚本
echo -e "\033[1;32m 正在调用 ha 脚本部署当前任务\033[0m"
source /root/deploy/ha.sh
echo -e "\033[1;32m 调用完成，开始调用下一个脚本\033[0m"