#!/bin/bash
# Author: Michael Lee
# Email: xxx@163.com
# Date: 07/18/2022
# Filename: check.sh


# 定义全局变量
ip_groups1="192.168.200.4 192.168.200.5"
ip_groups2="192.168.200.3 192.168.200.4 192.168.200.5"


cat > /etc/keepalived/haproxy.sh << EOF
#!/bin/bash
# Author: Michael Lee
# Email: xxx@163.com
# Date: 07/24/2022
# Filename: haproxy.sh


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

chmod +x /etc/keepalived/haproxy.sh

for sh in $ip_groups1;
do 
    scp /etc/keepalived/haproxy.sh $sh:/etc/keepalived
done


for start in $ip_groups2;
do
    ssh root@$sh systemctl start keepalived
    ssh root@$sh systemctl start haproxy
done
