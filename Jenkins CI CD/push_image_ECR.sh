#login to wso2 Docker registry
echo -e "login to wso2 Docker registry"
docker login docker.wso2.com/wso2ei-integrator -u $USERNAME -p $PASSWORD

#pull the image to local
echo -e "pull the image from wso2 docker registry to local"
docker pull "docker.wso2.com/wso2ei-integrator:$WSO2_IMAGE_NUM"


echo -e "check if image got downloaded"
docker image ls |grep -i "wso2ei-integrator" |grep -i $WSO2_IMAGE_NUM


IMAGE_ID=`docker image ls |grep -i "wso2ei-integrator" |grep -i $WSO2_IMAGE_NUM|awk '{print $3}'`
echo -e "Image ID is $IMAGE_ID"

docker logout docker.wso2.com/wso2ei-integrator

echo "Tag the Image"
docker tag $IMAGE_ID 549615285520.dkr.ecr.eu-central-1.amazonaws.com/wso2ei:$WSO2_IMAGE_NUM

echo "logging to ECR registry"
sudo aws ecr get-login --registry-ids 549615285520 --region eu-central-1 --no-include-email|xargs sudo

#push it to ECR
echo -e "Pushing Image to ECR"
docker push 549615285520.dkr.ecr.eu-central-1.amazonaws.com/wso2ei:$WSO2_IMAGE_NUM

#delete the image from local
echo -e "Delete the image from jenkins server"
docker rmi $IMAGE_ID -f
