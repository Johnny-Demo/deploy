#!/bin/bash
# Author: Michael Lee
# Email: xxx@163.com
# Date: 07/20/2022
# Filename: git.sh


# clone 项目分支
git clone https://github.com/Johnny-Demo/deploy.git && chmod +x *.sh


# 调用脚本
echo -e "\033[1;32m 正在调用 ssh 脚本部署当前任务！\033[0m"
source /root/deploy/ssh.sh
echo -e "\033[1;32m 调用完成，开始调用下一个脚本！\033[0m"


echo -e "\033[1;32m 正在调用 install_ha 脚本部署当前任务！\033[0m"
source /root/deploy/install_ha.sh
echo -e "\033[1;32m 调用完成，开始调用下一个脚本！\033[0m"


echo -e "\033[1;32m 正在调用 deploy 脚本部署当前任务！\033[0m"
source /root/deploy/deploy.sh
echo -e "\033[1;32m 调用完成\033[0m"
