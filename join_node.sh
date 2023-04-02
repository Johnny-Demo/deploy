#!/bin/bash
# Author: Johnny Lee
# Email: xxx@outlook.com
# Date: 05/25/2022
# Filename: join_node.sh

# 定义变量
if [ ! -f "/root/2.txt" ];then
   touch /root/2.txt
fi

cat /root/deploy/kubeadm-config.yaml|grep 'controlPlaneEndpoint'|awk '{print $2}' > /root/2.txt
sed -i 's/"//g' /root/2.txt
vip=$(cat /root/2.txt)
key=`cat /root/log.txt|grep 'sha256'|awk '{print $2}'`

# node 节点加入集群
kubeadm join $vip --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash $key 