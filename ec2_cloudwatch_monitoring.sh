#!/bin/bash
#To read line by line by for loop
IFS=$'\n'

#SNS TOPIC
#export SNS="arn:aws:sns:ap-south-1:161764708719:test"

#Region
#export region="ap-south-1"
#export region="eu-central-1"
#export AWS_ACCESS_KEY_ID=###
#export AWS_SECRET_ACCESS_KEY=###
#
#get all instance ID's
instanceID=`aws ec2 describe-instances --region=$region  --query 'Reservations[].Instances[].[InstanceId]' --output text`
#/usr/local/bin/aws ec2 describe-instances --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value[]]' --output text > /tmp/InstanceName

echo -e  "\nList of Ec2 Instances:\n$instanceID\n\n"
echo "------------------------------------------"

#get all instance Names
InstanceName=`/usr/local/bin/aws ec2 describe-instances --region=$region --query 'Reservations[].Instances[].[Tags[?Key==\`Name\`].Value[]]' --output text`

echo -e "Instance Names of above Instances:\n$InstanceName\n\n"
echo "------------------------------------------"

#Function to which takes both InstanceID and InstanceName at the sametime to create CloudFormation Stack
fun()
{
set $InstanceName

for i in $instanceID
do
 echo -e "\ncreating CloudFormation Stack for $i\n"
 echo "$i" "$1"
/usr/local/bin/aws cloudformation create-stack --region=$region --stack-name CloudWatchEC2-$i --template-body file://cloudwatch_ec2_cloudformation.json \
--parameters ParameterKey=criticalsnsarn,ParameterValue=$SNS \
ParameterKey=instanceid,ParameterValue=$i \
ParameterKey=instancename,ParameterValue=$1 \
ParameterKey=warningsnsarn,ParameterValue=$SNS
shift
done
}

#Call the fucntion
fun
