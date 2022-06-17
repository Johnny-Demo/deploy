# k8s-shell
注意事项：    
一、selinux 脚本单独执行，selinux 关闭之后要重启服务器才能生效。    
二、执行脚本顺序    
1、env.sh  
2、ha.sh  
3、install.sh  
4、reset.sh（如果初始化集群有问题可以直接执行，没必要的情况下可以不执行。）     
