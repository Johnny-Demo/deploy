#!/bin/bash
# Author: Michael Lee
# Email: xxx@163.com
# Date: 07/26/2022
# Filename: etcd.sh


# 定义变量
url="https://github.com/etcd-io/etcd/releases/download/v3.4.14/etcd-v3.4.14-linux-amd64.tar.gz"
path="/root/etcd"


# 下载 etcd 客户端并加入环境变量
if [ ! -d "$path" ];then
    mkdir /root/etcd
fi

cd $path && wget $url && tar -zxf *.tar.gz
mv */etcdctl /usr/local/bin && chmod +x /usr/local/bin/


# 查看 etcdctl 版本
etcdctl version


# 查看 etcd 高可用集群健康状态
ETCDCTL_API=3 etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key --write-out=table --endpoints=192.168.200.3:2379,192.168.200.4:2379,192.168.200.5:2379 endpoint health


# 查看 etcd 高可用集群列表
ETCDCTL_API=3 etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key --write-out=table --endpoints=192.168.200.3:2379,192.168.200.4:2379,192.168.200.5:2379 member list


# 查看 etcd 高可用集群 leader
ETCDCTL_API=3 etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key --write-out=table --endpoints=192.168.200.3:2379,192.168.200.4:2379,192.168.200.5:2379 endpoint status
