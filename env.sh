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


# 定义变量（后面调用方便些）
ip_list1="192.168.200.4 192.168.200.5 192.168.200.6"
ip_list2="192.168.200.4 192.168.200.5"


# 获取个节点 IP
read -p "请输入 master1 节点 ip:"
read -p "请输入 master2 节点 ip:"
read -p "请输入 master3 节点 ip:"
read -p "请输入 node1 节点 ip:"


# 添加个节点 IP 到 hosts 文件
cat >> /etc/hosts << EOF
$master1 master1
$master2 master2
$master3 master3
$node1 node1
EOF

for n in $ip_list1
do
   scp /etc/hosts $n:/etc/
done


# 关闭各节点防火墙
systemctl stop firewalld && systemctl disable firewalld

for n in $ip_list1
do 
   ssh root@$n systemctl stop firewalld && systemctl disable firewalld
done


# 关闭各节点 swap 分区
sed -i '/swap/s/^/#/g' /etc/fstab

for n in $ip_list1
do
   ssh root@$n sed -i '/swap/s/^/#/g' /etc/fstab
done


# 关闭各节点 selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

for a in $ip_list1
do
  ssh root@$a sed -i 's/^ *SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
done


# 各节点安装 ipset
yum -y install ipvsadm ipset sysstat conntrack libseccomp

for n in $ip_list1
do
   ssh root@$n yum -y install ipvsadm ipset sysstat conntrack libseccomp
done


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
touch /etc/sysctl.d/k8s.conf
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1
EOF

for n in $ip_list1
do
   scp /etc/sysctl.d/k8s.conf $n:/etc/sysctl.d/
   ssh root@$n sysctl -p /etc/sysctl.d/k8s.conf
done


# 同步各节点的时间
timedatectl set-timezone Asia/Shanghai && chronyc -a makestep

for a in $ip_list1
do
   ssh root@$a timedatectl set-timezone Asia/Shanghai && chronyc -a makestep
done


# 各节点安装 docker
cd /etc/yum.repos.d/ && wget https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce-18.06.0.ce-3.el7
systemctl enable docker && systemctl start docker

for n in $ip_list1
do
   ssh root@$n cd /etc/yum.repos.d/
   scp docker-ce.repo $n:/etc/yum.repos.d/ 
   ssh root@$n yum -y install docker-ce-18.06.0.ce-3.el7
   ssh root@$n systemctl enable docker && systemctl start docker
done


# 配置各节点的 docker 加速器
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

for n in $ip_list1 
do 
   scp /etc/docker/daemon.json $n:/etc/docker/
   ssh root@$n systemctl restart docker
   ssh root@$n docker info | grep Cgroup
done


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


# 各节点安装 kubeadm kubelet kubectl
yum -y install kubeadm-1.18.2 kubelet-1.18.2 kubectl-1.18.2
systemctl enable kubelet && systemctl daemon-reload

for n in $ip_list1
do
   ssh root@$n yum -y install kubeadm-1.18.2 kubelet-1.18.2 kubectl-1.18.2
   ssh root@$n systemctl enable kubelet && systemctl daemon-reload
done
