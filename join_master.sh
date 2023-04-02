#!/bin/bash
# Author: Johnny Lee
# Email: xxx@outlook.com
# Date: 05/25/2022
# Filename: join_master.sh

# 定义变量
if [ ! -f "/root/1.txt" ];then
   touch /root/1.txt
fi

cat /root/deploy/kubeadm-config.yaml|grep 'controlPlaneEndpoint'|awk '{print $2}' > /root/1.txt
sed -i 's/"//g' /root/1.txt
vip=$(cat /root/1.txt)
key="cat /root/log.txt|grep 'sha256'|awk '{print $2}'"

# master 节点加入集群
kubeadm join $vip --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash $key \
    --control-plane
