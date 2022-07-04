#!/bin/bash
# Author: Johny
# Email: xxx@163.com
# Date: 05/25/2022
# Filename: cni.sh


# 安装网络插件并查看集群状态
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
