#!/bin/bash
# Author: Johny
# Email: xxx@163.com
# Date: 05/25/2022
# Filename: check.sh

touch /etc/keepalived/check_haproxy.sh
cat > /etc/keepalived/check_haproxy.sh << EOF
#!/bin/bash

A=`ps -C haproxy --no-header | wc -l`

if [ $A -eq 0 ]
then
   systmectl start haproxy

if [ ps -C haproxy --no-header | wc -l -eq 0 ]
then
   killall -9 haproxy
   echo "HAPROXY down" | mail -s "haproxy"
   sleep 3600
fi 

fi
EOF
chmod +x /etc/keepalived/check_haproxy.sh