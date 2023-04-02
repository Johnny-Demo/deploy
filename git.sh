#!/bin/bash
# Author: Michael Lee
# Email: xxx@163.com
# Date: 07/20/2022
# Filename: git.sh

# clone 项目分支
git clone https://gitee.com/demo-pre/plugin.git && chmod +x /root/shell-k8s/*

# 调用脚本
echo -e "\033[1;32m 正在调用 ssh.sh 脚本部署当前任务！\033[0m"
source /root/deploy/ssh.sh
echo -e "\033[1;32m 调用完成，开始调用下一个脚本！\033[0m"

echo -e "\033[1;32m 正在调用 install_ha.sh 脚本部署当前任务！\033[0m"
source /root/deploy/install_ha.sh
echo -e "\033[1;32m 调用完成，开始调用下一个脚本！\033[0m"

echo -e "\033[1;32m 正在调用 deploy.sh 脚本部署当前任务！\033[0m"
source /root/deploy/deploy.sh
echo -e "\033[1;32m 调用完成，开始调用下一个脚本！\033[0m"

echo -e "\033[1;32m 正在调用 cni.sh 脚本部署当前任务！\033[0m"
source /root/deploy/cni.sh
echo -e "\033[1;32m 调用完成\033[0m"

echo -e "\033[1;32m 正在调用 helm.sh 脚本部署当前任务！\033[0m"
source /root/deploy/helm.sh
echo -e "\033[1;32m 调用完成\033[0m"

echo -e "\033[1;32m 正在调用 nfs.sh 脚本部署当前任务！\033[0m"
source /root/deploy/nfs.sh
echo -e "\033[1;32m 调用完成\033[0m"