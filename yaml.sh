#!/bin/bash
# Author: Michael Lee
# Email: xxx@163.com
# Date: 05/25/2022
# Filename: yaml.sh


# 替换参数
sed -i 's/1.2.3.4/192.168.200.3/g' /root/deploy/kubeadm-config.yaml
sed -i 's/name: node/name: master3/g' /root/deploy/kubeadm-config.yaml
sed -i 's/1.22.0/1.22.5/g' /root/deploy/kubeadm-config.yaml


# 添加内容
sed -i '/clusterName/a controlPlaneEndpoint: "192.168.200.10:16443"' /root/deploy/kubeadm-config.yaml   
sed -i '/dnsDomain/a\  podSubnet: "10.244.0.0/16"' /root/deploy/kubeadm-config.yaml


# 文件末尾追加内容
echo "---" >> /root/deploy/kubeadm-config.yaml
echo "apiVersion: kubeproxy.config.k8s.io/v1alpha1" >> /root/deploy/kubeadm-config.yaml
echo "kind: KubeProxyConfiguration" >> /root/deploy/kubeadm-config.yaml
echo "mode: ipvs" >> /root/deploy/kubeadm-config.yaml

