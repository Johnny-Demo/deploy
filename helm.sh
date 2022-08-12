#!/bin/bash
# Author: Michael Lee
# Email: xxx@163.com
# Date: 07/18/2022
# Filename: helm.sh


# 定义变量
url="https://get.helm.sh/helm-v3.0.0-linux-amd64.tar.gz"
path="/root/helm"


# 下载解压并加入环境变量
if [ ! -d "$path" ];then
   mkdir $path
fi

cd $path && wget $url && tar -zxf *.tar.gz
chmod +x */helm && mv */helm /usr/bin


# 查看是否生效
helm version 
helm 


