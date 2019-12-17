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
#get all classic ELB names
classicELBName=`aws elb describe-load-balancers --region=$region --query 'LoadBalancerDescriptions[*].[LoadBalancerName]' --output=text`

echo -e  "\nList of Classic ELB:\n$classicELBNames\n\n"
echo "------------------------------------------"

#get all ELB DNS Names
classELBdns=`aws elb describe-load-balancers --region=$region --query 'LoadBalancerDescriptions[*].[DNSName]' --output=text`

echo -e "ELB DNS Names:\n$classELBdns\n\n"
echo "------------------------------------------"

#Function to which takes both classELBdns and classicELBName at the sametime to create CloudFormation Stack
fun()
{
set $classELBdns

for i in $classicELBName
do
 echo -e "\ncreating CloudFormation Stack for $i\n"
 echo "$i" "$1"
/usr/local/bin/aws cloudformation create-stack --region=$region --stack-name CloudWatchClassicELB-$i --template-body file://cloudwatch_classicELB_cloudformation.json \
--parameters ParameterKey=criticalsnsarn,ParameterValue=$SNS \
ParameterKey=LoadBalancerName,ParameterValue=$i \
ParameterKey=classELBdns,ParameterValue=$1 \
ParameterKey=account,ParameterValue=$account \
ParameterKey=warningsnsarn,ParameterValue=$SNS
shift
done
}

#Call the fucntion
fun
