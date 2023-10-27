#!/bin/bash

# 创建 haproxy.sh 脚本
touch /etc/keepalived/haproxy.sh

# 高可用检测脚本
cat > /etc/keepalived/haproxy.sh <<EOF
#!/bin/bash

if [ ps -C haproxy --no-header | wc -l -eq 0 ]
then
   systmectl start haproxy
    if [ ps -C haproxy --no-header | wc -l -eq 0 ]
    then
       killall -9 haproxy
    echo "haproxy down" | mail -s "haproxy"
       sleep 3600
    fi 
fi
EOF

# 启动 keepalived 和 haproxy
systemctl start keepalived && systemctl start haproxy

# 创建 log.txt 文件
touch /root/log.txt

# 把启动日志保存到 log.txt
systemctl status keepalived > /root/log.txt && systemctl status haproxy >> /root/log.txt 