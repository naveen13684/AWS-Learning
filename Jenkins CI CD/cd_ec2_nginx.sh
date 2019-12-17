#!/bin/bash
# Docker login for ECR Common Account
sudo aws ecr get-login --registry-ids xxxxxxxxxx --region eu-central-1 --no-include-email|xargs sudo

#Download new image
sudo docker pull xxxxx.dkr.ecr.eu-central-1.amazonaws.com/devand:devandnginx-${IMAGE_ID}

#List current container
sudo docker container ls

#List current images
sudo docker image ls

#list all running/stopped container
sudo docker ps -a

# stop existing container
sudo docker container ls|awk '{print $1}'|grep -v CONTAINER|xargs docker stop

# remove old stopped container
sudo docker ps -a|awk '{print $1}'|grep -v CONTAINER|xargs docker rm -f

#Start the new container
sudo docker run -p 80:80 -p 443:443 -v /var/log/splunklogs:/var/log/nginx --name devand-nginx-${IMAGE_ID}  -d XXXXXXXXX.dkr.ecr.eu-central-1.amazonaws.com/devand:devandnginx-${IMAGE_ID} 

#
sudo docker container ls

#Checking if new container serving requests 


