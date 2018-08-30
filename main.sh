#!/bin/bash
# How to install the Mysql automatically? 
# This file includes all the function for the installation. We will call them in the install.sh.
#
#
#Import the vars
source ./config.sh

function check_mysql_rpm() {
rpm_name=mysql
x=`rpm -qa | grep $rpm_name`
if [ `rpm -qa | grep $rpm_name |wc -l` -ne 0 ];then
echo -e "yes, The mysql was installed ! the packet_list: \n$x"
exit 1
else
echo "Not Installed, Installing the mysql"
fi
}

function create_mysql_dir() {
# create the mysql path
arr_path=("$base_dir" "$data_dir" "$binlog_dir" "$slowlog_dir")

echo ${arr_path[@]}
echo ""

for file in ${arr_path[@]}; do
  if [ -e $file ]
  then
     echo "The file/Path $file is exist, Nothing to do! Please check the data in the path. Then change the install path, or backup and drop the path."
     exit 1
  else
     echo "The file/Path $file is not exist. Create it"
     mkdir -p $file
     chown  -R mysql:mysql $file
     chmod 755 $file
  fi
  done
}

function set_password_mysql57() {
   #change the default password  for the mysql version 5.7
   defaultmysqlpwd=`grep 'A temporary password' /var/log/mysqld.log | awk -F"root@localhost: " '{ print $2}' `

   # check the mysql connectivity 
   dbstat=`mysqladmin -uroot -p${defaultmysqlpwd} -P3306 ping |grep alive|wc -l`
   if [ $dbstat -eq 1 ]
      then 
      echo "Connect the Mysql successfully! Setting the password......"
   mysql -uroot -p${defaultmysqlpwd} --connect-expired-password <<EOF
SET PASSWORD = PASSWORD('Envisi0n1324!');
GRANT ALL PRIVILEGES ON *.* TO 'envision'@'%' IDENTIFIED BY  'Envisi0n4321!' WITH GRANT OPTION;
EOF
   else 
      echo "Connect the Mysql fail! Don't Set the password"
      return 1
   fi
}

function set_password_mysql56() {
#change the default password for the mysql version 5.6
/usr/bin/mysql -uroot --connect-expired-password <<EOF
SET PASSWORD = PASSWORD('Envisi0n1324!');
GRANT ALL PRIVILEGES ON *.* TO 'envision'@'%' IDENTIFIED BY  'Envisi0n4321!' WITH GRANT OPTION;
EOF
}

function calc_innodb_buffer(){
#Claculate the innodb buffer size
mem=`cat /proc/meminfo | sed -n '1p'| awk '{print $2}'`
os_mem=$[$mem/1024]M
echo "The OS memory is $os_mem"
innodb_buffer_mem=$[($mem/1024)*6/10]M
echo "The innodb_buffer_mem will be set $innodb_buffer_mem"
}

function change_mysql57_my_cnf_file() {
# Change the mysql 5.7 /etc/my.cnf 
# The part will read the vars from the config.sh
# action! innodb_log_file_size is the 60% os memory, It is set dynamic. The function calc_innodb_buffer is called.
cat <<EOF > /etc/my.cnf
[mysqld]
socket=/var/lib/mysql/mysql.sock
datadir=$data_dir
character_set_server=$my57_character_set_server
lower_case_table_names=$my57_lower_case_table_names
transaction_isolation=$my57_transaction_isolation
innodb_flush_log_at_trx_commit=$my57_innodb_flush_log_at_trx_commit
query_cache_type=1
query_cache_size=10383360  
max_connections=$my57_max_connections
innodb_log_file_size=$innodb_buffer_mem
innodb_buffer_pool_size=$my57_innodb_buffer_pool_size
binlog_format=$my57_binlog_format
expire_logs_days=$my57_expire_logs_days
max_binlog_size=$my57_max_binlog_size
binlog_cache_size=$my57_binlog_cache_size
max_binlog_cache_size=$my57_max_binlog_cache_size
slow_query_log=$my57_slow_query_log
slow_query_log_file=$slowlog_dir/slow.log
log_bin=$binlog_dir/mysql-bin
sql_mode=$my57_sql_mode
server_id=$my57_server_id
symbolic-links=0
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
EOF
}

function change_mysql56_my_cnf_file() {
# Change the mysql 5.6 /etc/my.cnf 
# The part will read the vars from the config.sh
# action! innodb_log_file_size is the 60% os memory, It is set dynamic. The function calc_innodb_buffer is called.
cat <<EOF > /etc/my.cnf
[mysqld]
socket=/var/lib/mysql/mysql.sock
datadir=$data_dir
character_set_server=$my57_character_set_server
lower_case_table_names=$my57_lower_case_table_names
transaction_isolation=$my56_transaction_isolation
innodb_flush_log_at_trx_commit=$my56_innodb_flush_log_at_trx_commit
query_cache_type=1
query_cache_size=10383360  
max_connections=$my56_max_connections
innodb_log_file_size=$my56_innodb_log_file_size
innodb_buffer_pool_size=$innodb_buffer_mem
binlog_format=$my56_binlog_format
expire_logs_days=$my56_expire_logs_days
max_binlog_size=$my56_max_binlog_size
binlog_cache_size=$my56_binlog_cache_size
max_binlog_cache_size=$my56_max_binlog_cache_size
slow_query_log=$my56_slow_query_log
slow_query_log_file=$slowlog_dir/slow.log
log_bin=$binlog_dir/mysql-bin
server_id=$my56_server_id
symbolic-links=0
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
EOF
}

function start_mysql_centos7() {
systemctl start  mysqld.service
systemctl enable mysqld.service
systemctl status mysqld.service
}

function start_mysql_centos6() {
service mysqld start
chkconfig mysqld on
service mysqld status
}

function exit_commond(){
# If some function run fail, we will call this function to exit the session
echo $?
if [[ $? -eq 0 ]];then
exit 1
fi
}


################The mysql download URL####################
function yum_centos6_myysql56() {
#Yum Centos6 mysql5.6 download and install
rpm -ivh http://repo.mysql.com/mysql-community-release-el6-5.noarch.rpm
yum install mysql-community-server -y
}

function tar_centos6_myysql56() {
#Tar Centos6 mysql5.6 download and install
mkdir /tmp/mysql_install_temp
cd /tmp/mysql_install_temp
wget https://dev.mysql.com/get/Downloads/MySQL-5.6/MySQL-5.6.41-1.el6.x86_64.rpm-bundle.tar
tar -xvf MySQL-5.6.41-1.el6.x86_64.rpm-bundle.tar
rm -rf /tmp/mysql_install_temp
}

function yum_centos6_myysql57() {
#Centos6 mysql5.7 download and install
rpm -ivh  http://repo.mysql.com//mysql57-community-release-el6-8.noarch.rpm
yum install mysql-community-server -y
}

function tar_centos6_myysql57() {
#Tar Centos6 mysql5.7 download and install
mkdir /tmp/mysql_install_temp
cd /tmp/mysql_install_temp
wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.23-1.el6.x86_64.rpm-bundle.tar
tar -xvf mysql-5.7.23-1.el6.x86_64.rpm-bundle.tar
rm -rf /tmp/mysql_install_temp
}

function yum_centos7_myysql57() {
#Centos7 mysql5.7 download and install
##yum repo
rpm -ivh http://repo.mysql.com/mysql57-community-release-el7-11.noarch.rpm
yum repolist enabled| grep mysql
yum-config-manager --disable mysql56-community
yum-config-manager --enable mysql57-community
yum install mysql-community-server -y
}

function tar_centos7_myysql57() {
#Tar Centos7 mysql5.7 download and install
mkdir /tmp/mysql_install_temp
cd /tmp/mysql_install_temp
wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.23-1.el7.x86_64.rpm-bundle.tar
tar -xvf mysql-5.7.23-1.el7.x86_64.rpm-bundle.tar
rm -rf /tmp/mysql_install_temp
}

function yum_centos7_myysql56() {
#Centos7 mysql5.6 download and install
rpm -ivh http://repo.mysql.com/mysql57-community-release-el7-11.noarch.rpm
yum repolist enabled| grep mysql
yum-config-manager --disable mysql56-community
yum-config-manager --enable mysql57-community
yum install mysql-community-server -y
}

function tar_centos7_myysql56() {
#Tar Centos7 mysql5.6 download and install
mkdir /tmp/mysql_install_temp
cd /tmp/mysql_install_temp
wget https://dev.mysql.com/get/Downloads/MySQL-5.6/MySQL-5.6.41-1.el7.x86_64.rpm-bundle.tar
tar -xvf MySQL-5.6.41-1.el7.x86_64.rpm-bundle.tar
rm -rf /tmp/mysql_install_temp
}


function check_os_version() {
os_version6=`cat /etc/redhat-release|grep -o "6\."|cut -c -1`
if [ "$os_version6" == "6" ]
then
osversion=6
fi
os_version7=`cat /etc/redhat-release|grep -o "7\."|cut -c -1`
if [ "$os_version7" == "7" ]
then
osversion=7
fi
}

function select_version_and_install_mysql() {
#Notice!! This function is dependent with check_os_version and 
#tar_centos7_myysql56,tar_centos7_myysql57,yum_centos7_myysql56 and so on
# This function need behind those function in the script. 

# 

echo "If want to install Mysql 5.6, please enter 56 ."
echo "If want to install Mysql 5.7, please enter 57 ."
echo -n "Select the Mysql version:"   
read msqlversion

if [ "$osversion" == "6" ]&& [ "$msqlversion" == "56" ]
then
    echo "The mysql 5.6 will be install."
    yum_centos6_myysql56 
    #tar_centos6_myysql56
    
elif [ "$osversion" == "7" ]&& [ "$msqlversion" == "56" ]
then
   echo "The mysql 5.6 will be install."
   yum_centos7_myysql56 
   #tar_centos7_myysql56

elif [ "$osversion" == "6" ]&& [ "$msqlversion" == "57" ]
then
   echo "The mysql 5.7 will be install."
    yum_centos6_myysql57 
    #tar_centos6_myysql57   
   
elif [ "$osversion" == "7" ]&& [ "$msqlversion" == "57" ]
then
   echo "The mysql 5.7 will be install."
   yum_centos7_myysql57 
   #tar_centos7_myysql57
 
else
   echo "The script only support the version 5.6 and 5.7, please do not select the other version/value"
   exit 1
fi

echo "The mysql $msqlversion was installed."
}
