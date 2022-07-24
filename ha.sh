#!/bin/bash
# Author: Michael Lee
# Email: xxx@163.com
# Date: 07/18/2022
# Filename: ha.sh


# 定义全局变量
ip_groups="192.168.200.4 192.168.200.5"


# 修改配置文件
echo "" > /etc/keepalived/keepalived.conf
cat > /etc/keepalived/keepalived.conf << EOF
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
        192.168.200.10      
    }
    track_script {
        check_haproxy       
    }
}
EOF
 

echo "" > /etc/haproxy/haproxy.cfg
cat > /etc/haproxy/haproxy.cfg << EOF
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
    server master1 192.168.200.3:6443 check
    server master2 192.168.200.4:6443 check
    server master3 192.168.200.5:6443 check
EOF


for file in $ip_groups;
do
    scp /etc/keepalived/keepalived.conf $file:/etc/keepalived/
    scp /etc/haproxy/haproxy.cfg $file:/etc/haproxy/
    ssh root@$file sed -i 's/MASTER/BACKUP/g' /etc/keepalived/keepalived.conf
done

for b in 192.168.200.4;
do
    ssh root@$b sed -i 's/100/90/g' /etc/keepalived/keepalived.conf
done

for c in 192.168.200.5;
do
    ssh root@$c sed -i 's/100/80/g' /etc/keepalived/keepalived.conf
done


# 调用脚本
echo -e "\033[1;32m 正在调用 check 脚本部署当前任务！\033[0m"
source /root/deploy/check.sh
echo -e "\033[1;32m 调用完成，开始调用下一个脚本！\033[0m"
