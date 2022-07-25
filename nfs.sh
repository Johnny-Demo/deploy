#!/bin/bash
# Author: Michael Lee
# Email: xxx@163.com
# Date: 07/14/2022
# Filename: nfs.sh


# 定义全局变量
ip_groups1="192.168.200.3 192.168.200.4 192.168.200.5 192.168.200.6"
ip_groups2="192.168.200.4 192.168.200.5"
ip_groups3="192.168.200.3 192.168.200.4 192.168.200.5"


# 安装 nfs 服务端
for service in $ip_groups1;
do
    ssh root@$service yum -y install nfs-utils rpcbind
    ssh root@$service systemctl enable nfs && systemctl start nfs
    ssh root@$service systemctl enable rpcbind && systemctl start rpcbind
    echo -e "\033[1;32m nfs 服务已启动\033[0m"
done


# 创建挂载目录
for dir in $ip_groups3;
do
    ssh root@$dir mkdir -pv /data/volumes/{v1,v2,v3}
    echo -e "\033[1;32m 路径创建完成\033[0m"
done


# 添加以下内容到 /etc/exports 配置文件
cat > /etc/exports << EOF
/data/volumes/v1  192.168.200.0/24(rw,no_root_squash,no_all_squash)
/data/volumes/v2  192.168.200.0/24(rw,no_root_squash,no_all_squash)
/data/volumes/v3  192.168.200.0/24(rw,no_root_squash,no_all_squash)
EOF

for file in $ip_groups2;
do 
    scp /etc/exports $file:/etc/
    echo -e "\033[1;32m 配置完成\033[0m"
done


# 发布并查看状态
for host in $ip_groups3;
do
    ssh root@$host exportfs -arv && \
                   showmount -e
    echo -e "\033[1;32m 已发布\033[0m"
done


# 下载 nfs 插件
mkdir /root/storage && cd /root/storage
for file in class.yaml deployment.yaml rbac.yaml test-claim.yaml; 
do     
    wget https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs-client/deploy/$file
    echo -e "\033[1;32m 文件下载成功\033[0m" 
done
cd


# 修改 deployment.yaml 文件
sed -i 's/value: 10.10.10.60/value: 192.168.200.3/g' /root/storage/deployment.yaml
sed -i 's!value: /ifs/kubernetes!value: /data/volumes/v1!g' /root/storage/deployment.yaml
sed -i 's/server: 10.10.10.60/server: 192.168.200.3/g' /root/storage/deployment.yaml
sed -i 's!path: /ifs/kubernetes!path: /data/volumes/v1!g' /root/storage/deployment.yaml


# 部署 nfs 服务并设置默认 StorageClass
kubectl apply -f /root/storage/.

sleep 30s
    
kubectl get storageclass

# 标记一个StorageClass为默认的
kubectl patch storageclass managed-nfs-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

kubectl get storageclass


