#!/bin/bash
##############################################
#
# 关闭 selinux
#
##############################################

# Author: Johnny
# Email: xxx@163.com
# Date: 05/25/2022
# File name: selinux.sh

ip_list1="192.168.200.5 192.168.200.7 192.168.200.6"


# 关闭 selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

for a in $ip_list1
do
  ssh root@$a sed -i 's/^ *SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  echo -e "\033[1;32m selinux 已关闭\033[0m"
done
  