#!/bin/bash

TGARN="arn:aws:elasticloadbalancing:eu-central-1:856279758674:targetgroup/DevCP-Nginx1Test443/25fc1cc5fc0c9679"
cdjob1=https://nonprod-aws.jenkins.verifonecp.com/jobs/job/test
#cdjob1=https://nonprod-aws.jenkins.verifonecp.com/jobs/job/dev-nginx-cp/lastBuild/api/json
cdjob2=https://nonprod-aws.jenkins.verifonecp.com/jobs/job/test1
#cdjob2=https://nonprod-aws.jenkins.verifonecp.com/jobs/job/dev-nginx-cp1/lastBuild/api/json

jobs=($cdjob1 $cdjob2)

echo "job links are:"
echo ${jobs[*]}

#Describe the health of the instances for a load balancer

instances=`aws elbv2 describe-target-health --region=$region --target-group-arn $TGARN --query 'TargetHealthDescriptions[*].[Target.[Id]]' --output=text|xargs -n1`
echo -e "List of nginx instances: $instances"
#Take the instance out of the LoadBalancer

fun ()
{

set -- $cdjob1 $cdjob2

for i in `echo $instances`
do

echo -e "job url is $1"
echo -e "array is:"
echo ${jobs[*]}

#Deregister the instance
echo -e "Deregistering target: $i"

aws elbv2 deregister-targets --region=$region --target-group-arn $TGARN --targets Id=$i

echo -e "Wait until target status changes to unused"
        
        while (true)
        do
                status=`aws elbv2 describe-target-health --region=$region --target-group-arn $TGARN --targets Id=$i --query 'TargetHealthDescriptions[*].[Target.[Id],TargetHealth.[State]]' --output=text|xargs -n1 |grep -i "unused"`
				printstatus=`aws elbv2 describe-target-health --region=$region --target-group-arn $TGARN --targets Id=$i --query 'TargetHealthDescriptions[*].[Target.[Id],TargetHealth.[State]]' --output=text|xargs -n1|tail -1`
                
                echo -e "Status of $i: $printstatus"
                sleep 15
                if [ "$status" == "unused" ]
                then
                echo "$i is unregistered"
                break
                fi
                
        done
        
#curl -X POST $1/build --user jenkins:hashpassword --data-urlencode json='{"parameter":[{"name":"IMAGE_ID","value":"'"${BUILD_NUMBER}"'"}]}'

#Run the nginx jobs one by one
#curl -X POST $1/build --user jenkins:hashpassword

IP1=`aws ec2 describe-instances --instance-ids $i --query "Reservations[].Instances[].PrivateIpAddress" --output=text`

#IP2=`curl -X GET https://username:password@nonprod-aws.jenkins.com/jobs/view/nginx-CD/job/dev-nginx-cp/config.xml|grep -i siteName|cut -d"@" -f2|cut -d":" -f1`
#IP3=`curl -X GET https://username:password@nonprod-aws.jenkins.com/jobs/view/nginx-CD/job/dev-nginx-cp1/config.xml|grep -i siteName|cut -d"@" -f2|cut -d":" -f1`
IP2=`curl -X GET https://username:password@nonprod-aws.jenkins.com/jobs/view/nginx-CD/job/test/config.xml|grep -i siteName|cut -d"@" -f2|cut -d":" -f1`
IP3=`curl -X GET https://username:password@nonprod-aws.jenkins.com/jobs/view/nginx-CD/job/test1/config.xml|grep -i siteName|cut -d"@" -f2|cut -d":" -f1`

if  [ $IP1 == $IP2 ]
then 
    echo -e "IP1:$IP1 is same as IP2:$IP2"
    echo -e "running $cdjob1"
	curl -X POST $cdjob1/build --user jenkins:hashpassword
elif [ $IP1 == $IP3 ]
then
	echo -e "IP1:$IP1 is same as IP3:$IP3"
	echo -e "running $cdjob2"
	curl -X POST $cdjob2/build --user jenkins:hashpassword
else
echo -e "Please check instance in the Target Group $TGARN"
fi


#Run the jobs one by one
curl -X POST $1/build --user jenkins:hashpassword

sleep 10

        while (true)
        do
                curl  $1/lastBuild/api/json --user jenkins:hashpassword | grep -i "\"result\"\:\"SUCCESS\""
                #curl  https://nonprod-aws.jenkins.verifonecp.com/jobs/job/test/lastBuild/api/json --user jenkins:hashpassword | grep -i "\"result\"\:\"SUCCESS\""
                if [ $? -eq 0 ]; then
                echo -e "nginx job 1 completed"
                break
                fi
        done

#Register the target back

aws elbv2 register-targets --region=$region --target-group-arn $TGARN --targets Id=$i

        while (true)
        do
                status=`aws elbv2 describe-target-health --region=$region --target-group-arn $TGARN --targets Id=$i --query 'TargetHealthDescriptions[*].[Target.[Id],TargetHealth.[State]]' --output=text|xargs -n1 |grep -i "healthy"`
				printstatus=`aws elbv2 describe-target-health --region=$region --target-group-arn $TGARN --targets Id=$i --query 'TargetHealthDescriptions[*].[Target.[Id],TargetHealth.[State]]' --output=text|xargs -n1|tail -1`
                
                echo -e "Status of $i: $printstatus"
                sleep 15
                if [ "$status" == "healthy" ]
                then
                echo "$i is registered"
                break
                elif [ "$status" == "unhealthy" ]
                then
                echo "$i status is unhealthy please check manually"
                break
                fi
                
        done
        
if [ "$status" == "unhealthy" ]
then
break
fi

#shift

done

}

fun
