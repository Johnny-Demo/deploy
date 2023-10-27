#!/bin/bash

# 升级内核并修改内核启动顺序
yum -y update 2>&1 >/dev/null
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org 2>&1 >/dev/null
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm 2>&1 >/dev/null
yum -y install --enablerepo=elrepo-kernel kernel-ml 2>&1 >/dev/null
grub2-set-default 0 2>&1 >/dev/null

# 关闭swap分区
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 关闭 selinux
sed -i 's/^ *SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config 2>&1 >/dev/null

# 重启
reboot