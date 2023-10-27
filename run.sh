#!/bin/bash

# master 组(根据自己节点添加，一共三台主节点，192.192.191.10这台主节点不用写，因为是从这台主节点往其他主节点传送文件。)
ip1="192.192.191.11 192.192.191.12"

# node 组(根据自己节点添加)
ip2="192.192.191.13"

# IP 组(master 和 node 混合，根据自己节点添加)
ip3="192.192.191.11 192.192.191.12 192.192.191.13"

# 调用 deploy.sh 脚本
source /root/deploy-Uat-three/deploy.sh

# 发送 deploy.sh 到其他服务器
for host in $ip3
do
   scp /root/deploy-Uat-three/deploy.sh $host:/root/
   ssh root@$host sh /root/deploy.sh
done

# 调用 install-config.sh 脚本
source /root/deploy-Uat-three/install_config.sh

# 获取默认配置文件
kubeadm config print init-defaults > /root/kubeadm-config.yaml

# 调用 yaml.sh 脚本
source /root/deploy-Uat-three/yaml.sh

# 下载 k8s 镜像
kubeadm config images pull --config /root/kubeadm-config.yaml

# 创建 k8s.txt 文件
touch /root/k8s.txt

# 初始化集群结果保存到 k8s.txt 文件
kubeadm init --config /root/kubeadm-config.yaml > /root/k8s.txt

# 发送 k8s.txt 到其他节点
for a in $ip3
do
   scp /root/k8s.txt $a:/root/
done

# 执行以下命令
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 调用 join_master.sh 把证书发送到其他 master 节点
for cer in $ip1
do
   ssh root@$cer mkdir -p /etc/kubernetes/pki/etcd
   scp /etc/kubernetes/pki/ca.* $cer:/etc/kubernetes/pki/
   scp /etc/kubernetes/pki/sa.* $cer:/etc/kubernetes/pki/
   scp /etc/kubernetes/pki/front-proxy-ca.* $cer:/etc/kubernetes/pki/
   scp /etc/kubernetes/pki/etcd/ca.* $cer:/etc/kubernetes/pki/etcd/
   scp /etc/kubernetes/admin.conf $cer:/etc/kubernetes/
done

# 把 admin.conf 复制到其他 node 节点
for cer2 in $ip2
do
   scp /etc/kubernetes/admin.conf $cer2:/etc/kubernetes/
done

# 安装网络插件
git clone https://github.com/flannel-io/flannel.git && kubectl apply -f /root/deploy-Uat-three/flannel/Documentation/kube-flannel.yml  