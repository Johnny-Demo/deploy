#!/bin/bash

# 安装 Keepalived 和 Haproxy 并加入开机启动
yum -y install keepalived haproxy
systemctl enable keepalived && systemctl enable haproxy

# 备份原文件
cp /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak

# 把以下内容到覆盖到 Keepalived.conf 文件
cat > /etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived
global_defs {
   router_id LVS_DEVEL
# 添加如下内容
   script_user root
   enable_script_security
}
vrrp_script haproxy {
    script "/etc/keepalived/haproxy.sh"        
    interval 3
    weight -2 
    fall 10
    rise 2
}
vrrp_instance VI_1 {
    state MASTER            
    interface ens33        
    virtual_router_id 51
    priority 100             
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.192.191.4      
    }
    track_script {
        haproxy       
    }
}
EOF

# 把以下内容覆盖到 Haproxy.cfg 文件
cat > /etc/haproxy/haproxy.cfg <<EOF
#---------------------------------------------------------------------
# Example configuration for a possible web application.  See the
# full configuration options online.
#
#   http://haproxy.1wt.eu/download/1.4/doc/configuration.txt
#
#---------------------------------------------------------------------
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats
#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000
#---------------------------------------------------------------------
# main frontend which proxys to the backends
#---------------------------------------------------------------------
frontend  kubernetes-apiserver
    mode                        tcp
    bind                        *:16443
    option                      tcplog
    default_backend             kubernetes-apiserver
#---------------------------------------------------------------------
# static backend for serving up images, stylesheets and such
#---------------------------------------------------------------------
listen stats
    bind            *:1080
    stats auth      admin:awesomePassword
    stats refresh   5s
    stats realm     HAProxy\ Statistics
    stats uri       /admin?stats
#---------------------------------------------------------------------
# round robin balancing between the various backends
#---------------------------------------------------------------------
backend kubernetes-apiserver
    mode        tcp
    balance     roundrobin
    server master1.com 192.192.191.10:6443 check
    server master2.com 192.192.191.11:6443 check
    server master3.com 192.192.191.12:6443 check
EOF

# 定义 IP 组
ip="192.192.191.11 192.192.191.12"

# 发送文件到其他主机并修改文件
for file in $ip
do
    ssh root@$file yum -y install keepalived haproxy
    ssh root@$file systemctl enable keepalived && systemctl enable haproxy
    ssh root@$file mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak
    ssh root@$file mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
    scp /etc/keepalived/keepalived.conf $file:/etc/keepalived/
    scp /etc/haproxy/haproxy.cfg $file:/etc/haproxy/
    ssh root@$file sed -i 's/MASTER/BACKUP/g' /etc/keepalived/keepalived.conf
done

# 修改其他 Keepalived 节点选举权
ip2="192.192.191.11"
ssh root@$ip2 sed -i 's/100/90/g' /etc/keepalived/keepalived.conf

ip3="192.192.191.12"
ssh root@$ip3 sed -i 's/100/80/g' /etc/keepalived/keepalived.conf

# 运行 check.sh 脚本自动创建
source /root/deploy/check.sh

# 发送 check.sh 脚本到其他主节点并运行
for file2 in $ip
do
   scp /root/deploy/check.sh $file2:/root/check.sh
   ssh root@$file2 sh /root/check.sh
done
