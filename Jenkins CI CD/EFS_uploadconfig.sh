wso2ei_dir="/tmp/efs/cg/wso2ei"
wso2ei_backup_dir="/tmp/efs/cg/wso2ei_backup/"
sops_path="/var/lib/jenkins/go/bin"
tmp="/tmp/efs"
efs="nonprddev.efs.com"
env="dev"

#creating temp efs folder to mount efs filesystem

if [ ! -d ${tmp} ]; then
	echo -e "Creating ${tmp} folder"
	mkdir -p ${tmp}
fi

echo -e "checking file system already mounted"
#checking file system already mounted

if grep -i ${tmp} /proc/mounts
then 
    echo -e "Umounting filesystem if already mounted"
	sudo umount -l ${tmp}

	echo -e "mounting $efs to ${tmp}"
	sudo mount ${efs}:/ ${tmp}
	sudo df -h |grep -i ${tmp}
else 
	echo -e "mounting nonprddev.efs.com to ${tmp}"
	sudo mount ${efs}:/ ${tmp}
	sudo df -h |grep -i "${tmp}"
fi 


echo -e "\n Starting wso2ei cg efs jobs...which will replace new jar files like artifacts, carapps keystore and configs \n"


cd ${wso2ei_backup_dir}
sudo zip -r wso2ei_${BUILD_ID}.zip ${wso2ei_dir} -x ${wso2ei_dir}/logs\* -x ${wso2ei_dir}/splunk\*

echo -e "Existing backup is taken. wso2ei_${BUILD_ID}.zip file is created under /tmp/efs/cg. Please clean up in case not required."

echo -e "\n syncing files from s3 to EFS\n"

sudo aws s3 sync s3://eu-verifone-wso2-cg-ei/${env}/artifacts/dropins ${wso2ei_dir}/artifacts/dropins
sudo chmod -R 755 ${wso2ei_dir}/artifacts/dropins
sudo aws s3 sync s3://eu-verifone-wso2-cg-ei/${env}/artifacts/lib ${wso2ei_dir}/artifacts/lib
sudo chmod -R 755 ${wso2ei_dir}/artifacts/lib
sudo aws s3 sync s3://eu-verifone-wso2-cg-ei/${env}/carapps ${wso2ei_dir}/carapps
sudo chmod -R 777 ${wso2ei_dir}/carapps/*.car
$sops_path/sops -i -d ${wso2ei_dir}/carapps/*.car
if [ $? -ne 0 ]
then
	echo -e "Decription failed: check if the file is encrypted while uploading to s3"
	exit 1
fi	

for i in `ls ${wso2ei_dir}/carapps/*.car`
do

echo -e "Checking $i file is unencrypted..."
file $i
file $i | grep -i "Zip archive data" 
if [ $? -ne 0 ]
then
	echo -e "$i file is still unencrypted make sure file is not encrypted more than once"
	exit 1
fi	
done
sudo chmod -R 755 ${wso2ei_dir}/carapps/*.car
sudo aws s3 sync s3://eu-verifone-wso2-cg-ei/${env}/configs ${wso2ei_dir}/configs
sudo chmod -R 755 ${wso2ei_dir}/configs
sudo aws s3 sync s3://eu-verifone-wso2-cg-ei/${env}/keystore ${wso2ei_dir}/keystore
sudo chmod -R 755 ${wso2ei_dir}/keystore

echo -e "umounting /tmp/efs file system."
sudo umount -l /tmp/efs

echo -e "All files successfully synced from AWS s3 to EFS"
