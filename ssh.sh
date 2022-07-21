#!/bin/bash
# Author: Michael Lee
# Email: xxx@163.com
# Date: 05/25/2022
# Filename: ssh.sh


# 定义全局变量
name_group="192.168.200.3 192.168.200.4 192.168.200.5 192.168.200.6"


# 创建 ssh 公钥
ssh-keygen -t rsa 


# 把公钥传送到每台服务器
for pub in $name_group;
do
   ssh-copy-id -i ~/.ssh/id_rsa.pub $pub:
done