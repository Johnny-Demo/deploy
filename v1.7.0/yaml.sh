#!/bin/bash
# Author: Johny
# Email: xxx@163.com
# Date: 05/25/2022
# Filename: yaml.sh

# 获取默认配置文件并修改配置文件参数
kubeadm config print init-defaults > kubeadm-config.yaml 

# 替换参数
sed -i 's/1.2.3.4/192.168.200.3/g' /root/kubeadm-config.yaml
sed -i 's/name: node/name: master3/g' /root/kubeadm-config.yaml
sed -i 's/1.22.0/1.22.2/g' /root/kubeadm-config.yaml

# 添加内容
sed -i '/clusterName/a controlPlaneEndpoint: "192.168.200.16:16443"' /root/kubeadm-config.yaml   
sed -i '/dnsDomain/a\  podSubnet: "10.244.0.0/16"' /root/kubeadm-config.yaml

# 文件末尾追加内容
echo "---" >> /root/kubeadm-config.yaml
echo "apiVersion: kubeproxy.config.k8s.io/v1alpha1" >> /root/kubeadm-config.yaml
echo "kind: KubeProxyConfiguration" >> /root/kubeadm-config.yaml
echo "mode: ipvs" >> /root/kubeadm-config.yaml

# 初始化 k8s 集群
kubeadm init --config kubeadm-config.yaml
