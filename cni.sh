#!/bin/bash
# Author: Michael Lee
# Email: xxx@163.com
# Date: 07/18/2022
# Filename: cni.sh


# 安装网络插件并查看集群状态
git clone https://github.com/flannel-io/flannel.git
kubectl apply -f /root/flannel/Documentation/kube-flannel.yml  
 

# 睡眠
sleep 40s 


# 查看集群和所有 pod 运行状态
kubectl get nodes 

kubectl get po --all-namespaces -o wide 

kubectl get cs