#!/bin/bash
##############################################
#
# k8s 初始化集群并加入其他节点
#
##############################################

# Author: Johnny
# Email: xxx@163.com
# Date: 05/25/2022
# Filename: install.sh

# 定义变量
ip_list2="192.168.200.4 192.168.200.5"


# 修改 kubeadm-config.yaml 默认配置文件
kubeadm config print init-defaults > kubeadm-config.yaml
cat > kubeadm-config.yaml << EOF
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 192.168.200.3
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  imagePullPolicy: IfNotPresent
  name: master3
  taints: null
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controlPlaneEndpoint: "192.168.200.16:16443"
controllerManager: {}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: k8s.gcr.io
kind: ClusterConfiguration
kubernetesVersion: 1.23.5
networking:
  dnsDomain: cluster.local
  podSubnet: "10.244.0.0/16"
  serviceSubnet: 10.96.0.0/12
scheduler: {}
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
EOF


# 下载 k8s 镜像
kubeadm config images pull --config kubeadm-config.yaml

for m in $ip_list2  
do
   scp kubeadm-config.yaml $m:/root/ 
   ssh root@$m kubeadm config images pull --config kubeadm-config.yaml
   echo -e "\033[1;32m 镜像下载完成\033[0m"
done


# 初始化集群
kubeadm init --config kubeadm-config.yaml --ignore-preflight-errors=all 


# 将主节点证书复制到其他节点
for m in $ip_list2
do
   ssh root@$m mkdir -p /etc/kubernetes/pki/etcd
   scp /etc/kubernetes/pki/ca.* $m:/etc/kubernetes/pki/
   scp /etc/kubernetes/pki/sa.* $m:/etc/kubernetes/pki/
   scp /etc/kubernetes/pki/front-proxy-ca.* $m:/etc/kubernetes/pki/
   scp /etc/kubernetes/pki/etcd/ca.* $m:/etc/kubernetes/pki/etcd/
   scp /etc/kubernetes/admin.conf $m:/etc/kubernetes/
   echo -e "\033[1;32m 其他控制节点证书传送完成\033[0m"
done


for b in 192.168.200.6
do
   scp /etc/kubernetes/admin.conf $b:/etc/kubernetes/
   echo -e "\033[1;32m 其他工作节点证书传送完成\033[0m"
done
