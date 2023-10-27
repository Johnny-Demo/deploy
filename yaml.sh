#!/bin/bash

# 替换参数
sed -i 's/1.2.3.4/192.192.191.10/g' /root/kubeadm-config.yaml
sed -i 's/1.18.0/1.18.2/g' /root/kubeadm-config.yaml

# 添加内容
sed -i '/clusterName/a controlPlaneEndpoint: "192.192.191.4:16443"' /root/kubeadm-config.yaml   
sed -i '/dnsDomain/a\  podSubnet: "10.244.0.0/16"' /root/kubeadm-config.yaml

# 文件末尾追加内容
echo "---" >> /root/kubeadm-config.yaml
echo "apiVersion: kubeproxy.config.k8s.io/v1alpha1" >> /root/kubeadm-config.yaml
echo "kind: KubeProxyConfiguration" >> /root/kubeadm-config.yaml
echo "featureGates:" >> /root/kubeadm-config.yaml
sed -i '/featureGates/a\  SupportIPVSProxyMode: true' /root/kubeadm-config.yaml
echo "mode: ipvs" >> /root/kubeadm-config.yaml
