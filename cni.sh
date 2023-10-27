#!/bin/bash

# 安装网络插件
git clone https://github.com/flannel-io/flannel.git && kubectl apply -f /root/deploy/flannel/Documentation/kube-flannel.yml  
