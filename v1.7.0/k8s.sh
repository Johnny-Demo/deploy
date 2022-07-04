#!/bin/bash
# Author: Johny
# Email: xxx@163.com
# Date: 05/25/2022
# Filename: k8s.sh


# 定义变量
ip1="192.168.200.4 192.168.200.5"
ip2="192.168.200.4 192.168.200.5 192.168.200.6"


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
yum -y install ipvsadm ipset sysstat conntrack libseccomp
 
for host in $ip2;
do
   ssh root@$host yum -y install ipvsadm ipset sysstat conntrack libseccomp
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

for host in $ip2;
do
   scp /etc/sysconfig/modules/ipvs.modules $host:/etc/sysconfig/modules/ 
   ssh root@$host chmod 755 /etc/sysconfig/modules/ipvs.modules
   ssh root@$host bash /etc/sysconfig/modules/ipvs.modules
   ssh root@$host lsmod | grep -e ip_vs -e nf_conntrack_ipv4
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

for host in $ip2;
do
   scp /etc/sysctl.d/k8s.conf $host:/etc/sysctl.d/
   ssh root@$host modprobe br_netfilter && sysctl -p /etc/sysctl.d/k8s.conf
done
   

# 同步各节点的时间
timedatectl set-timezone Asia/Shanghai && chronyc -a makestep

for host in $ip2;
do
   ssh root@$host timedatectl set-timezone Asia/Shanghai && chronyc -a makestep
done
   

# 各节点安装 docker
cd /etc/yum.repos.d/ && wget https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce-19.03.5-3.el7
systemctl enable docker && systemctl start docker

for host in $ip2;
do   
   scp /etc/yum.repos.d/docker-ce.repo $host:/etc/yum.repos.d/ 
   ssh root@$host yum -y install docker-ce-19.03.5-3.el7
   ssh root@$host systemctl enable docker
   ssh root@$host systemctl start docker
done
   

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

for host in $ip2;
do 
   scp /etc/docker/daemon.json $host:/etc/docker/
   ssh root@$host systemctl restart docker
   ssh root@$host docker info | grep Cgroup
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

for host in $ip2;
do
   scp /etc/yum.repos.d/kubernetes.repo $host:/etc/yum.repos.d/
done
   

# 各节点安装 kubeadm kubelet kubectl
yum -y install kubeadm-1.22.2 kubelet-1.22.2 kubectl-1.22.2
systemctl daemon-reload && systemctl enable kubelet

for host in $ip2;
do
   ssh root@$host yum -y install kubeadm-1.22.2 kubelet-1.22.2 kubectl-1.22.2
   ssh root@$host systemctl daemon-reload
   ssh root@$host systemctl enable kubelet 
done


# 下载 k8s 镜像
kubeadm config images pull --config kubeadm-config.yaml 

for host in $ip1;  
do
   scp kubeadm-config.yaml $host: 
   ssh root@$host kubeadm config images pull --config kubeadm-config.yaml 
done


# 初始化集群
source yaml.sh


# 其他 master 节点创建路径
for host in $ip1;
do
   ssh root@$host mkdir -p /etc/kubernetes/pki/etcd
   echo -e "\033[1;32m 路径创建完成\033[0m"
done


# 将主节点证书复制到其他主节点
for host in $ip1;
do
   ssh root@$host mkdir -p /etc/kubernetes/pki/etcd
   scp /etc/kubernetes/pki/ca.* $host:/etc/kubernetes/pki/
   scp /etc/kubernetes/pki/sa.* $host:/etc/kubernetes/pki/
   scp /etc/kubernetes/pki/front-proxy-ca.* $host:/etc/kubernetes/pki/
   scp /etc/kubernetes/pki/etcd/ca.* $host:/etc/kubernetes/pki/etcd/
   scp /etc/kubernetes/admin.conf $host:/etc/kubernetes/
done


# 将 admin.conf 证书复制到其他 node 节点
b=192.168.200.6

for host in $b;
do
   scp /etc/kubernetes/admin.conf $host:/etc/kubernetes/
done


# root 用户执行以下命令
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
source .bash_profile

for host in $ip1;
do
   ssh root@$host echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile && source .bash_profile
done

