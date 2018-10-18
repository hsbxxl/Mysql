#!/bin/bash
#The mysql backup scripts
../config.sh

# Prepare the related path for the backup
function prepare_server_env {
if [ ! -d "$server_backup_base" ];then
mkdir -p {$server_backup_base,$server_backupset_dir,$server_backup_script,$server_backup_script_temp,$server_backup_log}
touch $server_backup_script/host_list
else
echo "The folders are exist!"
fi
}

function physical_backup_mysql() {
# Create the path on the client to backup
cat <<EOF > $server_backup_script_temp/create_path_script.sh
if [ ! -d "$client_backup_base" ];then
mkdir -p {$client_backup_base,$client_backupset_temp,$client_backupset_dir,$client_backup_log_temp,$client_backup_log}
fi
EOF

scp -o "StrictHostKeyChecking no" $server_backup_script_temp/create_path_script.sh ${client_user}@"${host_name}":/tmp

ssh ${client_user}@${host_name} "sh /tmp/create_path_script.sh; rm /tmp/create_path_script.sh" 


cat $server_backup_script/host_list | while read line
do
    echo $line
    host_name=$line
	echo $host_name

#generate the backupset name, that is only valid in this function
backupset_name=${host_name}_$(date +%F-%H-%M).tar.gz

cat <<EOF > $server_backup_script_temp/backup_script.sh
innobackupex --defaults-file=$mycnf --user=$db_user --password="$db_password" --parallel=4  --stream=tar $client_backupset_dir 2>$client_backup_log_temp/${host_name}_$(date +%F-%H-%M)_output.log| gzip > $client_backupset_temp/$backupset_name
#generate status log
tail -1 $client_backup_log_temp/${host_name}_$(date +%F-%H-%M)_output.log| awk '{print \$3}' > $client_backup_log_temp/status.log
EOF
scp -o "StrictHostKeyChecking no" $server_backup_script_temp/backup_script.sh ${client_user}@"${host_name}":$client_backup_log_temp/
ssh ${client_user}@${host_name} 'sh $client_backup_log_temp/backup_script.sh >/dev/null 2>&1 &' 
sleep 5
ssh ${client_user}@${host_name} 'rm $client_backup_log_temp/backup_script.sh' 

done
}


function scp_mysql_backupset() {
#SCP 归集备份文件
#先检查是否备份完成读入host.list列表,并循环检查/mysql/output.log的结果,如果成功,scp归集,并mv /mysql/output.log重命名,然后将这个host名字写入 successful_host_list文件
#如果/mysql/output.log检查失败 not_complete_host_list文件
#过半小时,再次轮训not_complete_host_list文件, 成功的话,写入successful_host_list文件,失败的话,写入not_complete_host_list文件
#再过半小时,继续轮训上一步

echo > $server_backup_log/ok.list
echo > $server_backup_log/fail.list

#scp_list is generated in the function physical_backup_mysql

db_count=`cat $server_backup_script_temp/scp_list|wc -l`
echo "There are $db_count DBs will be scp!!"

cat $server_backup_script_temp/scp_list | while read line
do
    echo $line
    host_name=$line
	echo $host_name

	
#需要增加判断,host都是能正常访问的,如果不能访问,退出备份


	# get the backup status
backup_stat=`ssh ${client_user}@${host_name} "cat $client_backup_log_temp/status.log"`

   if [ "$backup_stat" = "completed" ] && [ -n "$backup_stat" ]
   then
      echo "#############Scp Start $(date +%F~%H-%M-%S)###################"
      remote_backupset_size=`ssh ${client_user}@${host_name} "du -sm $client_backupset_temp/${host_name}_$(date +%F-)*.tar.gz"`
	  echo $remote_backupset_size
    
	  scp ${client_user}@${host_name}:$client_backupset_temp/${host_name}_$(date +%F-)*.tar.gz  $server_backupset_dir/$host_name/
	  #mv the backup from temp path to dir
	   ssh ${client_user}@${host_name} "mv $client_backupset_temp/${host_name}_$(date +%F-)*.tar.gz $client_backupset_dir"
         #临时调试         
		  echo $client_backupset_temp/${host_name}_$(date +%F-)*.tar.gz
          echo $server_backupset_dir/$host_name/ 
	  
	  local_backupset_size=`du -sm $server_backupset_dir/$host_name/${host_name}_$(date +%F-)*.tar.gz`
	  #If the size diff , print the info
	  if [ "$remote_backupset_size" != "$local_backupset_size"];then 
	  echo "The file size is diff between remote($remote_backupset_size) and local($local_backupset_size)."
	  fi
	  
      echo "#############Scp End $(date +%F~%H-%M-%S)###################"
      echo "The backup completed!!"
	  
	  echo ${host_name} >> $server_backup_log/ok.list
	  sed -i '/'"$host_name"'/d' $server_backup_script_temp/scp_list
	  #rename the output log,
	   ssh ${client_user}@${host_name} "mv $client_backup_log_temp/${host_name}_$(date +%F)*_output.log $client_backup_log"
	   # clear the info for status.log
	   ssh ${client_user}@${host_name} "echo > $client_backup_log_temp/status.log"
	   #临时调试
	   ssh ${client_user}@${host_name} "ls $client_backup_log_temp/${host_name}_$(date +%F)*_output.log"
   else
      echo "The scp not completed!! The fail host is ${host_name}"
      echo ${host_name} >> $server_backup_log/fail.list
    fi

done
}


function query_mysql_dbsize() {

cat $server_backup_script/host_list | while read line
do
    echo $line
    host_name=$line
	echo $host_name

rds_db_size=`/usr/bin/mysql -u$db_user -p"$db_password" -h$host_name -N --connect-expired-password <<EOF
select  (concat(truncate(sum(data_length)/1024/1024,2),' MB') + concat(truncate(sum(index_length)/1024/1024,2),'MB')) as db_size
from information_schema.tables;
EOF`

/usr/bin/mysql -u$db_user -p"$db_password" -h$host_name -N --connect-expired-password -e "show variables like '%bin%'"
echo "The database size is $rds_db_size M"
done
}
