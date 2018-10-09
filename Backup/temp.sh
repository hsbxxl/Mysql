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