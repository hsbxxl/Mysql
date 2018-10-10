#!/bin/bash
#The mysql backup scripts
../conf/config.sh

BF_time=$(date +%F) 
ltime=$(date +%F~%H-%M-%S)

function mysqldump_bk() {
aa
}

function innobackupex_local_bk() {
#This function run in the client side
echo "#########Start backup at $(date +%F~%H-%M-%S)###############"
/usr/bin/innobackupex --defaults-file=/etc/my.cnf --user=$db_user --password="${db_password}" $backupset_path/$BF_time/
sleep 10

echo "#############Tar $(date +%F~%H-%M-%S)###################"
cd $backupset_path
/usr/bin/tar zcf $BF_time.BK.tar.gz $BF_time --remove &> /dev/null

echo "#########End backup at $(date +%F~%H-%M-%S)###############"
}

function scp_backupset_to_backupserver() {
#This function run in the server side
echo "#############Scp Start $(date +%F~%H-%M-%S)###################"
cd $backupset_path
du -sm $BF_time.BK.tar.gz
/usr/bin/scp root@$host_name:$backupset_path/$BF_time.BK.tar.gz  $server_backupset_path/$host_name/$BF_time/
echo "#############Scp End $(date +%F~%H-%M-%S)###################"
}


function backup_mysql() {
 
cat <<EOF > /mysql/backup_script.sh
innobackupex --defaults-file=/etc/my.cnf --user=root --password="root" --password="root" --parallel=4  --stream=tar /mysql/bk 2>/mysql/output.log| gzip > /mysql/bk`date +%F_%H-%M-%S`.tar.gz
#generate status log
tail -1 /mysql/output.log| awk '{print \$3}' > /mysql/status.log
EOF
scp -o "StrictHostKeyChecking no" /mysql/backup_script.sh root@"c6701":/mysql/
ssh root@c6701 'sh /mysql/backup_script.sh >/dev/null 2>&1 &' 
sleep 5
ssh root@c6701 'rm /mysql/backup_script.sh' 
}


function scp_mysql() {
#SCP 归集备份文件
#先检查是否备份完成读入host.list列表,并循环检查/mysql/output.log的结果,如果成功,scp归集,并mv /mysql/output.log重命名,然后将这个host名字写入 successful_host_list文件
#如果/mysql/output.log检查失败 not_complete_host_list文件
#过半小时,再次轮训not_complete_host_list文件, 成功的话,写入successful_host_list文件,失败的话,写入not_complete_host_list文件
#再过半小时,继续轮训上一步

echo > /mysql/ok.list
echo > /mysql/fail.list
#scp_list 需要在上一个备份的脚本中就产生出来, cat host.list > scp_list
cat scp_list | while read line
do
    echo $line
    host_name=$line
	echo $host_name
if [ -f "/mysql/${host_name}_output.log" ] 
then 

backup_stat=`tail -1 /mysql/${host_name}_output.log| awk '{print $3}'`
   if [ "$backup_stat" = "completed" ] && [ -n "$backup_stat" ]
   then
      echo "The backup completed!!"
	  echo ${host_name} >> /mysql/ok.list
	  sed -i '/'"$host_name"'/d' /mysql/scp_list
	  mv /mysql/${host_name}_output.log /mysql/${host_name}_output.log.bk.$(date +%F~%H-%M-%S)
   else
      echo "The backup not completed!!"
      echo ${host_name} >> /mysql/fail.list
    fi
else
   echo "The output file is not exist. The backup not completed!!"

fi
done

}







function scp_backupset_to_backupserver() {
cd /tmp
i=1
#ip.txt保存主机列表，第三列为IP，第二列为主机名，第一列为主机所在地址
cat ../conf/host.list|while read line
do
    host_name=`echo $line`
    echo "i=$i  $addr  host_name = $host_name"
    ssh -o "StrictHostKeyChecking no" "hostname"
    ssh root@${host_name}<<EOF   #连上主机，执行多条命令，前提是要配置好密钥登录
        nohup /usr/bin/innobackupex --defaults-file=/etc/my.cnf --user=$db_user --password="${db_password}" $backupset_path/$BF_time/ 2>&1 &
        sleep 10
        echo "#############Tar $(date +%F~%H-%M-%S)###################"
        cd $backupset_path
        nohup /usr/bin/tar zcf $BF_time.BK.tar.gz $BF_time --remove &> /dev/null 2>&1 &
        echo "#########End backup at $(date +%F~%H-%M-%S)###############"
        exit
EOF
    i=` expr $i + 1 `
done
exit 0
}