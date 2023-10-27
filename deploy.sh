#!/bin/bash

# 添加 hosts 文件解析
cat >> /etc/hosts <<EOF
192.192.191.10 k8s-master1
192.192.191.11 k8s-master2
192.192.191.12 k8s-master3
192.192.191.13 k8s-node1
EOF
   
# 关闭防火墙
systemctl stop firewalld && systemctl disable firewalld 2>&1 >/dev/null

# 同步服务器时间
timedatectl set-timezone Asia/Shanghai && chronyc -a makestep 2>&1 >/dev/null

# 安装 ipset
yum -y install ipvsadm ipset sysstat conntrack libseccomp 2>&1 >/dev/null

# 判断 ipvs.modules 文件是否存在不存在则创建
if [ ! -f "/etc/sysconfig/modules/ipvs.modules" ]
then
   touch /etc/sysconfig/modules/ipvs.modules
else
   echo "文件已存在"
fi

# 开启 br_netfilter 模块 （临时，重启会失效）
modprobe br_netfilter

# 把以下内容覆盖到 ipvs.modules 文件
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack # 低内核改成 modprobe -- nf_conntrack_ipv4
EOF

# 给脚本添加权限并执行查看是否生效
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

# 判断 k8s.conf 文件是否存在不存在则创建
if [ ! -f "/etc/sysctl.d/k8s.conf" ]
then
   touch /etc/sysctl.d/k8s.conf
else
   echo "文件已存在"
fi

# 把以下内容覆盖到 k8s.conf 文件
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1
EOF

# 立即生效
sysctl -p /etc/sysctl.d/k8s.conf

# 下载 docker 源并安装 docker
wget -P /etc/yum.repos.d/ https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo  2>&1 >/dev/null
yum -y install docker-ce-18.06.0.ce-3.el7 2>&1 >/dev/null
systemctl enable docker && systemctl start docker

# 判断 daemon.json 文件是否存在不存在则创建
if [ ! -f "/etc/docker/daemon.json" ]
then
   touch /etc/docker/daemon.json
else
   echo "文件已存在"
fi

# 配置 k8s 驱动
cat > /etc/docker/daemon.json <<EOF
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

# 重启 docker 并查看驱动是否生效
systemctl restart docker
docker info | grep Cgroup
 
# 判断 kubernetes.repo 文件是否存在不存在则创建
if [ ! -f "/etc/yum.repos.d/kubernetes.repo" ]
then
   touch /etc/yum.repos.d/kubernetes.repo
else
    echo "文件已存在"
fi

# 把以下内容覆盖到 kubernetes.repo 文件
cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=0    
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

# 安装 kubeadm kubelet kubectl 并加入开机启动
yum -y install kubeadm-1.18.2 kubelet-1.18.2 kubectl-1.18.2 2>&1 >/dev/null
systemctl daemon-reload && systemctl enable kubelet
