#!/bin/bash


ssh-keygen -t rsa 

name_group="master3 master4 master5 node6"
for host in $name_group;
do
   ssh-copy-id -i ~/.ssh/id_rsa.pub $host:
done
