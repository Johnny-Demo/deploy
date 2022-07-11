#!/bin/bash
# Author: Johny
# Email: xxx@163.com
# Date: 05/25/2022
# Filename: install_ha.sh


# 安装 keepalived 和 haproxy
yum -y install keepalived haproxy  
chmod +x ha.sh && source ha.sh
chmod +x check.sh && source check.sh
systemctl enable keepalived && systemctl start keepalived && systemctl status keepalived
systemctl enable haproxy && systemctl start haproxy && systemctl status haproxy


# 其他控制节点安装 keepalived haproxy
ip_list="192.168.200.4 192.168.200.5"

for a in $ip_list
do
   ssh root@$a yum -y install keepalived haproxy
   scp ha.sh check.sh $a: 
   ssh root@$a source ha.sh 
   ssh root@$a source check.sh 
   ssh root@$a sed -i 's/MASTER/BACKUP/g' /etc/keepalived/keepalived.conf
   ssh root@$a systemctl enable keepalived  
   ssh root@$a systemctl start keepalived 
   ssh root@$a systemctl enable haproxy 
   ssh root@$a systemctl start haproxy
done


# 修改第二台控制节点的 keepalived 权重
list1=192.168.200.4

for b in $list1
do
  ssh root@$b sed -i 's/100/90/g' /etc/keepalived/keepalived.conf
  ssh root@$b systemctl restart keepalived 
  ssh root@$b systemctl status keepalived 
done


# 修改第二台控制节点的 keepalived 权重
list2=192.168.200.5

for c in $list2
do
  ssh root@$c sed -i 's/100/80/g' /etc/keepalived/keepalived.conf
  ssh root@$c systemctl restart keepalived 
  ssh root@$c systemctl status keepalived
done
