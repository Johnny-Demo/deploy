先执行 kernel.sh 升级 linux 内核，关闭 selinux 和 swap 分区，重启服务器。 \
再执行 run.sh 部署k8s，master 和 node 手动加入集群，无法自动获取加入集群的认证。(没有dashboard部署文件，没写)
