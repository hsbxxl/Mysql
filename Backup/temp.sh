cat host_ip.txt 
172.18.14.123 root 123456
172.18.254.54 root 123456 


ip=`echo $line | cut -d " " -f1`             # 提取文件中的ip
user_name=`echo $line | cut -d " " -f2`      # 提取文件中的用户名
pass_word=`echo $line | cut -d " " -f3`      # 提取文件中的密码 
		
		


ssh omd@192.168.1.100  # 利用远程机的用户登录
ssh omd@192.168.1.100  -o stricthostkeychecking=no # 首次登陆免输yes登录
ssh omd@192.168.1.100 "ls /home/omd"  # 当前服务器A远程登录服务器B后执行某个命令
ssh omd@192.168.1.100 -t "sh /home/omd/ftl.sh"  # 当前服务器A远程登录服务器B后执行某个脚本



ssh root@client_host 'sh backup_script.sh >/dev/null 2>&1 &'


以下本脚本实现了：先从本地复制脚本到远程主机，再用ssh连上远程主机，执行之前复制的脚本（由于脚本需要执行很长时间，故放到后台执行），此脚本仅用于备忘，如有不足敬请指点！

#!/bin/bash
 
cd /tmp
i=1
#ip.txt保存主机列表，第三列为IP，第二列为主机名，第一列为主机所在地址
cat ip.txt|while read line
do
    IP=`echo $line|awk '{print $3}'`
    addr=`echo $line|awk '{print $1}'`
    echo "i=$i  $addr  IP = $IP"
    scp -o "StrictHostKeyChecking no" /root/tt/greplog.sh root@"$IP":/tmp/
    ssh root@${IP}<<EOF   #脸上主机，执行多条命令，前提是要配置好密钥登录
        chmod a+x /tmp/greplog.sh
        nohup /tmp/greplog.sh > myout.file 2>&1 &   #放到后台执行
        exit
EOF
    i=` expr $i + 1 `
done
exit 0


备份+压缩,经过测试,更省时间

ssh root@c6701 "echo 'innobackupex --defaults-file=/etc/my.cnf --user=root --password="root" --password="root" --stream=tar  /mysql/bk | gzip > /mysql/bk`date +%F_%H-%M-%S`.tar.gz' >> /mysql/bk/test.sh"
ssh root@c6701 'sh /mysql/bk/test.sh >/dev/null 2>&1 &' 

ssh root@c6701 'innobackupex --defaults-file=/etc/my.cnf --user=root --password="root" --password="root" --stream=tar  /mysql/bk | gzip > /mysql/bk`date +%F_%H-%M-%S`.tar.gz >/dev/null 2>&1 &' 

ssh root@c6701 'innobackupex --defaults-file=/etc/my.cnf --user=root --password="root" --password="root"  /mysql/bk >/dev/null 2>&1 &' 

innobackupex --defaults-file=/etc/my.cnf --user=root --password="root" /mysql/bk





 scp -l 1000 源地址 目标地址 （-l是限制传送速率，1000为100k/s）

 

tip：“scp -r 源地址 目标地址”可以用来传送文件夹。






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



sed '/c3/'d host.list

host_name=c1
sed -i '/'"$host_name"'/d' xx




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






    #!/bin/bash
     
ssh_host="root@c6701"
file="/mysql/output.log"
 
if ssh $ssh_host test -e $file;
    then echo $file exists
    else echo $file does not exist
fi














