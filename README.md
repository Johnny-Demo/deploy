要修改脚本里面的 ip 地址，根据自己情况修改，然后在部署，要不然会出错。 \
执行 kernel.sh 升级 linux 内核，关闭 selinux 和 swap 分区，重启服务器。 \
执行 run.sh 部署k8s，master 和 node 手动加入集群，无法自动获取加入集群的认证。(没有dashboard部署文件，没写)

注意：\
1、只要是 ip 都需要修改 \
2、只运行 kernel.sh 和 run.sh 脚本就行，其他脚本不需要执行 \
3、一共三台主节点，只有第一台主节点 IP 不用写在脚本里，其他 matster 节点 ip 和 其他 node 节点 ip 都要写在脚本里，所有脚本都是在第一台 matster 节点，需要把第一台脚本发送给 \其他节点，所以第一台 IP 不用写。
