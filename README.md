执行 deploy.sh 部署前置环境  
执行 other.sh 把脚本发送到其他节点部署前置环境   
执行 k8s.sh 调用 install_config.sh 部署 keepalived 和 haproxy，再调用 check.sh 创建高可用脚本   
执行 join_master.sh 证书发送并初始化 k8s 集群 （手动加入集群）  
执行 join_node.sh 发送 admin.cof 证书到另外 node 节点 （手动加入集群）   
执行 cni.sh 部署 flannel 插件
