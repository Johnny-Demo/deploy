#!/bin/bash
# Author: Michael Lee
# Email: xxx@163.com
# Date: 05/25/2022
# Filename: yaml.sh


# 定义变量
vip="cat deploy/kubeadm-config.yaml|grep 'controlPlaneEndpoint'|awk '{print $2}'"
key="cat log.txt|grep 'sha256'|awk '{print $2}'"


# node 节点加入集群
kubeadm join $vip --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash $key 