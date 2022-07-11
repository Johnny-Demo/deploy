#!/bin/bash
##############################################
#
# k8s 各节点安装常用的软件、要修改的各项前置配置
#
##############################################

# Author: Johnny
# Email: xxx@163.com
# Date: 05/25/2022
# File name: env.sh


# 定义变量
ip_list1="192.168.200.5 192.168.200.7 192.168.200.6"
ip_list2="192.168.200.5 192.168.200.7"


# 添加个节点 IP 到 hosts 文件
cat >> /etc/hosts << EOF
192.168.200.4 master2
192.168.200.5 master3
192.168.200.7 master4
192.168.200.6 node1
EOF

for n in $ip_list1
do
   scp /etc/hosts $n:/etc/
done
   echo -e "\033[1;32m 解析完成\033[0m"


# 关闭各节点防火墙
systemctl stop firewalld && systemctl disable firewalld

for n in $ip_list1
do 
   ssh root@$n systemctl stop firewalld && systemctl disable firewalld
done
   echo -e "\033[1;32m firewalld 已关闭\033[0m"


# 关闭各节点 swap 分区
sed -i '/swap/s/^/#/g' /etc/fstab

for n in $ip_list1
do
   ssh root@$n sed -i '/swap/s/^/#/g' /etc/fstab
done
   echo -e "\033[1;32m swap 分区已关闭\033[0m"


# 各节点安装 ipset
yum -y install ipvsadm ipset sysstat conntrack libseccomp 

for n in $ip_list1
do
   ssh root@$n yum -y install ipvsadm ipset sysstat conntrack libseccomp 
done
   echo -e "\033[1;32m 部署完成\033[0m"


# 各节点启用 IPVS 模块
touch /etc/sysconfig/modules/ipvs.modules
cat > /etc/sysconfig/modules/ipvs.modules << EOF
#!/bin/sh
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

for n in $ip_list1
do
   scp /etc/sysconfig/modules/ipvs.modules $n:/etc/sysconfig/modules/ 
   ssh root@$n chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4
done


# 将各节点的 IPv4 流量传递到 iptables 的链
modprobe br_netfilter
touch /etc/sysctl.d/k8s.conf
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1
EOF
sysctl -p /etc/sysctl.d/k8s.conf

for n in $ip_list1
do
   scp /etc/sysctl.d/k8s.conf $n:/etc/sysctl.d/
   ssh root@$n modprobe br_netfilter && sysctl -p /etc/sysctl.d/k8s.conf
done
   echo -e "\033[1;32m IPV4 已设置完成\033[0m"


# 同步各节点的时间
timedatectl set-timezone Asia/Shanghai && chronyc -a makestep

for a in $ip_list1
do
   ssh root@$a timedatectl set-timezone Asia/Shanghai && chronyc -a makestep
done
   echo -e "\033[1;32m 时间同步完成\033[0m"


# 各节点安装 docker
cd /etc/yum.repos.d/ && wget https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce-18.06.0.ce-3.el7
systemctl enable docker && systemctl start docker

for n in $ip_list1
do   
   scp /etc/yum.repos.d/docker-ce.repo $n:/etc/yum.repos.d/ 
   ssh root@$n yum -y install docker-ce-18.06.0.ce-3.el7
   ssh root@$n systemctl enable docker
   ssh root@$n systemctl start docker
done
   echo -e "\033[1;32m docker 已安装\033[0m"


# 配置各节点的 docker 驱动
touch /etc/docker/daemon.json
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

for n in $ip_list1 
do 
   scp /etc/docker/daemon.json $n:/etc/docker/
   ssh root@$n systemctl restart docker
   ssh root@$n docker info | grep Cgroup
done
   echo -e "\033[1;32m docker 加速器配置完成\033[0m"


# 配置各节点 k8s 源和镜像仓库
touch /etc/yum.repos.d/kubernetes.repo
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=0    
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

for n in $ip_list1
do
   scp /etc/yum.repos.d/kubernetes.repo $n:/etc/yum.repos.d/
done
   echo -e "\033[1;32m k8s 镜像源和仓库配置完成\033[0m"


# 各节点安装 kubeadm kubelet kubectl
yum -y install kubeadm-1.18.2 kubelet-1.18.2 kubectl-1.18.2
systemctl enable kubelet && systemctl daemon-reload

for n in $ip_list1
do
   ssh root@$n yum -y install kubeadm-1.18.2 kubelet-1.18.2 kubectl-1.18.2
   ssh root@$n systemctl enable kubelet && systemctl daemon-reload
done
   echo -e "\033[1;32m k8s 客户端和管理工具部署完成\033[0m"
