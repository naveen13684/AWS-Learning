echo "The workspace is ${WORKSPACE}"
export GOPATH=~/go
export SOPS=~/go/bin
export PATH=$PATH:$SOPS
#KMS KEY Name - upload-config
export SOPS_KMS_ARN="arn:aws:kms:eu-central-1:549615285520:key/61d73fa6-3a56-4cbc-a6fa-05cb5a6a2acc"
ecr=549615285520.dkr.ecr.eu-central-1.amazonaws.com/anddev:devandnginx
n=git show --name-only --diff-filter=AMRC --pretty="format:" HEAD|grep -i "nginx\/devandnginx\/" | wc -l

echo -e "decryping file sunder ssl folder"

for i in `ls nginx/devandnginx/nginx/ssl|egrep "*.crt|*.pem|*.key"` ; do 
sops -i -d nginx/devandnginx/nginx/ssl/$i
done

echo -e "decryping file sunder ssl folder"

for i in `ls nginx/devandnginx/certs|egrep "*.crt|*.pem|*.key"` ; do 
sops -i -d nginx/devandnginx/certs/$i
done


cd ${WORKSPACE}/nginx/devandnginx

docker build -t $ecr-${BUILD_ID} --no-cache -f Dockerfile_ML .
docker image ls |grep -i "devandnginx-${BUILD_ID}"

sudo aws ecr get-login --registry-ids 549615285520 --region eu-central-1 --no-include-email|xargs sudo
sudo docker push $ecr-${BUILD_ID}
sudo docker rmi -f $ecr-${BUILD_ID}
sudo rm -rf ${WORKSPACE}/nginx/devandnginx

echo -e "IMAGE_ID is : devandnginx-${BUILD_ID}"
