token=`curl -v -X GET -u $USERNAME:$PASSWORD "https://dockerauth.wso2.com/auth?scope=repository:wso2ei-integrator:pull&service=WSO2+Docker+registry"|grep -i token |cut -d"\"" -f4`

curl -v -X GET --header "Authorization: Bearer $token" "http://docker.wso2.com/v2/wso2ei-integrator/tags/list" | jq .tags
