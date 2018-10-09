#!/bin/bash
#The mysql backup scripts

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