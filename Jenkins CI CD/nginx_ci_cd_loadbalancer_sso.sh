LB_NAME="STGSSO-NGINX"
cdjob1=http://localhost/jobs/job/test
#cdjob1=http://localhost/jobs/job/stg-nginx-sso/lastBuild/api/json
cdjob2=http://localhost/jobs/job/test1
#cdjob2=http://localhost/jobs/job/stg-nginx-sso1/lastBuild/api/json
region="eu-central-1"

echo -e "jobs are: $cdjob1 $cdjob2"

#aws s3 ls
aws elb describe-instance-health --region=$region --load-balancer-name $LB_NAME

fun ()
{

set -- $cdjob1 $cdjob2

echo -e "jobs are: $cdjob1 $cdjob2"

echo -e "Array jobs $1 and $2"

if [ `aws elb describe-instance-health --region=$region --load-balancer-name $LB_NAME --query 'InstanceStates[*].[InstanceId]' --output=text | wc -l` -eq 2 ]
then
        echo -e "There are two instances for $LB_NAME"
        echo -e "Checking instance health..."
        for i in `aws elb describe-instance-health --region=$region --load-balancer-name $LB_NAME --query 'InstanceStates[*].[State]' --output=text`
        do
                if [ "$i" == "InService" ]
                then
                        echo -e " $i instance status is InService"
                else
                        echo -e "$i instance is out of service. First check the status of all instances!!!"
                        exit 1
                fi
        done


        for i in `aws elb describe-instance-health --region=$region --load-balancer-name $LB_NAME --query 'InstanceStates[*].[InstanceId]' --output=text`
        do
                #Deregister instance $i from CLB
                echo -e "Deregistering $i from $LB_NAME"
                aws elb deregister-instances-from-load-balancer --region=$region --load-balancer-name $LB_NAME --instances $i

                IP1=`aws ec2 describe-instances --region=$region --instance-ids $i --query "Reservations[].Instances[].PrivateIpAddress" --output=text`

                #IP2=`curl -X GET https://username:password@localhost/jobs/view/nginx-CD/job/dev-nginx-sso/config.xml|grep -i siteName|cut -d"@" -f2|cut -d":" -f1`
                #IP3=`curl -X GET https://username:password@localhost/jobs/view/nginx-CD/job/dev-nginx-sso1/config.xml|grep -i siteName|cut -d"@" -f2|cut -d":" -f1`
                #IP2=`curl -X GET https://username:password@localhost/jobs/view/nginx-CD/job/test/config.xml|grep -i siteName|cut -d"@" -f2|cut -d":" -f1`
                #IP3=`curl -X GET https://username:password@localhost/jobs/view/nginx-CD/job/test1/config.xml|grep -i siteName|cut -d"@" -f2|cut -d":" -f1`
				IP2="10.178.96.161"
				IP3="10.178.96.139"
                echo -e "The IP address of $i is IP1=$IP1 \n IP address of from cd dev-nginx-sso is IP2=$IP2 \n IP address from cd job dev-nginx-sso1 is IP=$IP3"

                if  [ "$IP1" == "$IP2" ]
                then
                        echo -e "IP1:$IP1 is same as IP2:$IP2"
                        echo -e "Running $cdjob1"
                        curl -X POST $cdjob1/build --user jenkins:hashpassword
                        
                        while (true)
                        do
                          echo -e "checking job $cdjob1 status...."
                          curl  $cdjob1/lastBuild/api/json --user jenkins:hashpassword | grep -i "\"result\"\:\"SUCCESS\""
                          if [ $? -eq 0 ]
                          then
                          echo -e "nginx $cdjob1 job completed"
                          break
                          else
                          sleep 2
                          echo -e "$cdjob1 job still running"
                          fi                          
                        done
        
                elif [ "$IP1" == "$IP3" ]
                then
                        echo -e "IP1:$IP1 is same as IP3:$IP3"
                        echo -e "running $cdjob2"
                        curl -X POST $cdjob2/build --user jenkins:hashpassword
                        while (true)
                        do
                          echo -e "checking job $cdjob2 status...."
                          curl  $cdjob2/lastBuild/api/json --user jenkins:hashpassword | grep -i "\"result\"\:\"SUCCESS\""
                          if [ $? -eq 0 ]
                          then
                          echo -e "nginx $cdjob2 job completed"
                          break
                          else
                          sleep 2
                          echo -e "$cdjob2 job still running"
                          fi                          
                        done                        
                else
                echo -e "Please check instance in the LoadBalancer!"
                fi

        #Run the jobs one by one.
        #echo -e " From array first job is Running $1 job:"
        #curl -X POST $1/build --user jenkins:hashpassword        

        #Register instane to CLB
        echo -e "Registering $i instance back to $LB_NAME"
        aws elb register-instances-with-load-balancer --region=$region --load-balancer-name $LB_NAME --instances $i


            while (true)
            do
                status=`aws elb describe-instance-health --region=$region --load-balancer-name $LB_NAME --instances=$i --query 'InstanceStates[*].[State]' --output=text`

                echo -e "Status of $i: $status"
                sleep 25
                if [ `aws elb describe-instance-health --region=$region --load-balancer-name $LB_NAME --instances=$i --query 'InstanceStates[*].[State]' --output=text` == "InService" ]
                then
                status=`aws elb describe-instance-health --region=$region --load-balancer-name $LB_NAME --instances=$i --query 'InstanceStates[*].[State]' --output=text`
				echo -e "Status of $i: $status"
                echo "$i is registered successfully to $LB_NAME"
                break
                elif [ `aws elb describe-instance-health --region=$region --load-balancer-name $LB_NAME --instances=$i --query 'InstanceStates[*].[State]' --output=text` == "OutOfService" ]
                then
                status=`aws elb describe-instance-health --region=$region --load-balancer-name $LB_NAME --instances=$i --query 'InstanceStates[*].[State]' --output=text`
				echo -e "Status of $i: $status"
                echo "$i status is still unhealth...wating to become InService"
                fi

           done
#shift

    done


else
   echo "There are no two instances for this load balancer. Mininum instances per Nginx load-balancer is 2"
   exit 1
fi


}

fun
