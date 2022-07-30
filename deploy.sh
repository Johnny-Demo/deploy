#!/bin/bash
# Author: Michael Lee
# Email: xxx@163.com
# Date: 05/25/2022
# Filename: deploy.sh


# 定义全局变量
ip1="192.168.200.4 192.168.200.5"
ip2="192.168.200.4 192.168.200.5 192.168.200.6"
ip3="192.168.200.3 192.168.200.4 192.168.200.5 192.168.200.6"


# 添加个节点 IP 到 hosts 文件
cat >> /etc/hosts << EOF
192.168.200.3 master3
192.168.200.4 master4
192.168.200.5 master5
192.168.200.6 node6
EOF

for host in $ip2;
do
   scp /etc/hosts $host:/etc/
done
   

# 各节点安装 ipset
for service in $ip3;
do
   ssh root@$service yum -y install ipvsadm ipset sysstat conntrack libseccomp
done


# 各节点启用 IPVS 模块
cat > /etc/sysconfig/modules/ipvs.modules << EOF
#!/bin/sh
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

for modules in $ip2;
do
   scp /etc/sysconfig/modules/ipvs.modules $modules:/etc/sysconfig/modules/ 
   ssh root@$modules chmod 755 /etc/sysconfig/modules/ipvs.modules && \
                      bash /etc/sysconfig/modules/ipvs.modules && \
                      lsmod | grep -e ip_vs -e nf_conntrack_ipv4
done


# 将各节点的 IPv4 流量传递到 iptables 的链
modprobe br_netfilter
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1
EOF
sysctl -p /etc/sysctl.d/k8s.conf

for conf in $ip2;
do
   scp /etc/sysctl.d/k8s.conf $conf:/etc/sysctl.d/
   ssh root@$conf modprobe br_netfilter && sysctl -p /etc/sysctl.d/k8s.conf
done
   

# 同步各节点的时间
for time in $ip3;
do
   ssh root@$time timedatectl set-timezone Asia/Shanghai && chronyc -a makestep
done
   

# 各节点安装 docker
wget https://download.docker.com/linux/centos/docker-ce.repo && scp /root/docker-ce.repo /etc/yum.repos.d/
rm -rf /root/docker-ce.repo

for repo in $ip2;
do
   scp /etc/yum.repos.d/docker-ce.repo $repo:/etc/yum.repos.d/
done


for containerd in $ip3;
do       
   ssh root@$containerd yum -y install docker-ce-18.06.0.ce-3.el7
   ssh root@$containerd systemctl enable docker 
   ssh root@$containerd systemctl start docker
done
   
 
# 配置各节点的 docker 驱动
cat > /etc/docker/daemon.json << EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
systemctl restart docker
docker info | grep Cgroup

for json in $ip2;
do 
   scp /etc/docker/daemon.json $json:/etc/docker/
   ssh root@$json systemctl restart docker
   ssh root@$json docker info | grep Cgroup
done
   

# 配置各节点 k8s 源和镜像仓库
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=0    
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

for repo2 in $ip2;
do
   scp /etc/yum.repos.d/kubernetes.repo $repo2:/etc/yum.repos.d/
done
   

# 各节点安装 kubeadm kubelet kubectl
for cli in $ip3;
do
   ssh root@$cli yum -y install kubeadm-1.18.2 kubelet-1.18.2 kubectl-1.18.2
   ssh root@$cli systemctl daemon-reload 
   ssh root@$cli systemctl enable kubelet 
done


# 获取默认配置文件
kubeadm config print init-defaults > /root/deploy/kubeadm-config.yaml


# 调用脚本
echo -e "\033[1;32m 正在调用 yaml 脚本部署当前任务！\033[0m"
source /root/deploy/yaml.sh
echo -e "\033[1;32m 调用完成\033[0m"


# 下载 k8s 镜像
kubeadm config images pull --config /root/deploy/kubeadm-config.yaml 
echo -e "\033[1;32m k8s 镜像下载完成\033[0m"

for yaml in $ip1;  
do
   scp /root/deploy/kubeadm-config.yaml $yaml:/root/
   ssh root@$yaml kubeadm config images pull --config kubeadm-config.yaml
   echo -e "\033[1;32m k8s 镜像下载完成\033[0m" 
done


# 初始化 k8s 集群
if [ ! -f "/root/log.txt" ];then
   touch /root/log.txt
fi

kubeadm init --config /root/deploy/kubeadm-config.yaml --ignore-preflight-errors=all > /root/log.txt


# 其他 master 节点创建路径
for dir in $ip1;
do
   ssh root@$dir mkdir -p /etc/kubernetes/pki/etcd
   echo -e "\033[1;32m 路径创建完成\033[0m"
done


# 将主节点证书复制到其他主节点
for cer in $ip1;
do
   ssh root@$cer mkdir -p /etc/kubernetes/pki/etcd
   scp /etc/kubernetes/pki/ca.* $cer:/etc/kubernetes/pki/
   scp /etc/kubernetes/pki/sa.* $cer:/etc/kubernetes/pki/
   scp /etc/kubernetes/pki/front-proxy-ca.* $cer:/etc/kubernetes/pki/
   scp /etc/kubernetes/pki/etcd/ca.* $cer:/etc/kubernetes/pki/etcd/
   scp /etc/kubernetes/admin.conf $cer:/etc/kubernetes/
done


# 将 admin.conf 证书复制到其他 node 节点
for cer2 in 192.168.200.6;
do
   scp /etc/kubernetes/admin.conf $cer2:/etc/kubernetes/
done


# 复制脚本到其他 master 节点
for master_sh in $ip1;
do
   scp /root/deploy/join_master.sh $master_sh:/root/
done


# 复制脚本到其他 node 节点
for node_sh in 192.168.200.6;
do
   scp /root/deploy/join_node.sh $node_sh:/root/
done


# 登录到其他 master 节点执行 join_master.sh 脚本
for ssh in $ip1;
do
   ssh root@$ssh . /root/join_master.sh
done


# 登录到其他 node 节点执行 join_node.sh 脚本
for ssh in 192.168.200.6;
do
   ssh root@$ssh . /root/join_node.sh
done


# 所有 master 节点执行以下命令
ip="192.168.200.3 192.168.200.4 192.168.200.5"
for cmd in $ip;
do
   ssh root@$cmd mkdir -p $HOME/.kube && \
                 cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && \
                 chown $(id -u):$(id -g) $HOME/.kube/config
done




