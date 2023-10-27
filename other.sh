#!/bin/bash

# 定义 IP 组
ip="192.192.191.11 192.192.191.12 192.192.191.13"

# 发送 deploy 到其他服务器
for host in $ip
do
   scp /root/deploy-Uat-three/deploy.sh $host:/root/
   ssh root@$host sh /root/deploy.sh
done