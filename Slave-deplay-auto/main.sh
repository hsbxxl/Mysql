#!/bin/bash
# Deploy the Mysql slave automatically? 
#Call the functions and vars
source ./config.sh

function check_parameter_format() {
# check the format of the input
if [ "$#" != "6" ]; then
  echo 'invalid parameters'
  echo 'usage: master_mysql_dump.sh master_instance username password slave_host username password'
  echo 'example: local_mysql_master_slave.sh 192.168.0.1 root password localhost root password'
  return
fi
}

function dump_database_from_master() {
first_stamp=`date +%s`
echo `date "+%Y_%m_%d_%H_%M_%S"`
data_stamp=`date "+%Y%m%d%H%M"`
# export the databases
mysqldump -u$master_user -p$master_password -h$master_hostname  2>/dev/null \
--port=3306 \
--single-transaction \
--master-data=2 \
--routines \
--triggers \
--compress  \
--databases $db_name > $temp_dir/mysqldump_$rdsdb_$data_stamp.sql
echo `date "+%Y_%m_%d_%H_%M_%S"`

today_stamp=`date +%s`                           
let day_stamp=($today_stamp - $first_stamp)      
let min=($day_stamp/60)                       

echo "RDS DB $db_name dump done!! It took $min Minutes"
}



function get_master_position() {
binlog_number=`grep 'CHANGE MASTER TO MASTER_LOG_FILE' $temp_dir/mysqldump_$rdsdb_$data_stamp.sql | awk -F"MASTER_LOG_FILE=" '{ print $2}'|  awk '{ print $1}'|sed "s/'//g" |sed "s/,//"`
position=`grep 'CHANGE MASTER TO MASTER_LOG_FILE' $temp_dir/mysqldump_$rdsdb_$data_stamp.sql | awk -F"MASTER_LOG_POS=" '{ print $2}'|sed "s/;//"`

echo The master binglog number $binlog_number
echo The master binglog position $position
}

function Check_master_connectivity() {
# check the mysql connectivity 
dbstat=`mysqladmin -u$master_user -p$master_password -h$master_hostname -P$master_port ping |grep alive|wc -l`
if [ $dbstat -eq 1 ]
    then 
    echo "Connect the RDS DB successfully"
#create replication user
master_db_size=`/usr/bin/mysql -u$master_user -p$master_password -h$master_hostname -N --connect-expired-password <<EOF
grant replication slave,replication client on *.* to $repluser@'%' identified by '$repluserpassword';
EOF`
    else
    echo "connect failed"
    return
fi
}

function get_database_list() {
# get the database name list, the databases 'MYSQL','PERFORMANCE_SCHEMA','INFORMATION_SCHEMA','SYS' will not export/import.
db_name=`/usr/bin/mysql -u$master_user -p$master_password -h$master_hostname -N --connect-expired-password <<EOF
select TABLE_SCHEMA
from information_schema.tables
where TABLE_SCHEMA NOT IN ('MYSQL','PERFORMANCE_SCHEMA','INFORMATION_SCHEMA','SYS')
group by TABLE_SCHEMA;
EOF`
echo "The databases $db_name will be exported ......"
function estimate_dump_time() {
}


function estimate_dump_time() {
# Calculate the database size, and estimate the dump of time from the master.
master_db_size=`/usr/bin/mysql -u$master_user -p$master_password -h$master_hostname -N --connect-expired-password <<EOF
select  (concat(truncate(sum(data_length)/1024/1024,2),' MB') + concat(truncate(sum(index_length)/1024/1024,2),'MB')) as db_size
from information_schema.tables;
EOF`
echo "The database size is $master_db_size M"

master_db_size2=`echo ${master_db_size%.*}`
echo $master_db_size2

if   [ $master_db_size2 -le "5000" ]
   then echo "The export will consume 10 minutes .... "
   
elif [ $master_db_size2 -le "50000" ]
then
echo "The export will consume 20 minutes .... "

elif [ $master_db_size2 -le "100000" ]
then
echo "The export will consume 40 minutes .... "

else
echo "The export will consume 60 minutes .... "
fi
}


function import_data_to_slave() {
echo "start import data into slave"
######### import data into slave #########
# check the slave mysql connectivity 
dbstat_slave=`mysqladmin -u$slave_user -p$slave_password -h$slave_hostname -P$slave_port ping |grep alive|wc -l`
if [ $dbstat_slave -eq 1 ]
    then 
    echo "Connect the RDS DB successfully"

# confirm for the import
echo "Action! you will import the file /tmp/mysqldump_$rdsdb_$data_stamp.sql to the mysql instance $slave_hostname!!!"
read -p " Press yes or no ... " val1        
echo "Your inputs: $val1"
   
if  [ "$val1" == "yes" ]
    then  
# import the database
echo "Start to import the date to slave ......"
/usr/bin/mysql -u$slave_user -p$slave_password -h$slave_hostname 2>/dev/null < /tmp/mysqldump_$rdsdb_$data_stamp.sql

# set the slave
echo "Start to set the master-slave ......"

/usr/bin/mysql -u$slave_user -p$slave_password -h$slave_hostname 2>/dev/null <<EOF
CHANGE MASTER TO
MASTER_HOST='$master_hostname',
MASTER_USER='$repluser',
MASTER_PASSWORD='$repluserpassword',
MASTER_LOG_FILE='$binlog_number',
MASTER_LOG_POS=$position;
start slave;
EOF


echo "/usr/bin/mysql -u$slave_user -p$slave_password -h$slave_hostname 2>/dev/null <<EOF
CHANGE MASTER TO
MASTER_HOST='$master_hostname',
MASTER_USER='$repluser',
MASTER_PASSWORD='$repluserpassword',
MASTER_LOG_FILE='$binlog_number2',
MASTER_LOG_POS=$position2;
EOF"
echo "done to set db"
else 
  echo "The import is terminated!!"
fi
else
  echo "The import is terminated!!"
fi
}



function mysql57_slave_my_cnf() {
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
innodb_log_file_size=$innodb_log_file_size
innodb_buffer_pool_size=$innodb_buffer_mem
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

relay_log=$relay_log
read_only=1
log_slave_updates=1 
sync_binlog=0
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

function change_mysql_uuid(){
###mv auto.cnf for the UUID###
# IF the host and Mysql clone from the template, the UUID will same, we have to remove it, and recreate with restart the mysql
mv $data_dir/auto.cnf $data_dir/auto.cnf.bak
}

function restart_mysql() {
os_version6=`cat /etc/redhat-release|grep -o "6\."|cut -c -1`
if [ "$os_version6" == "6" ]
then
osversion=6
service mysqld restart
fi
os_version7=`cat /etc/redhat-release|grep -o "7\."|cut -c -1`
if [ "$os_version7" == "7" ]
then
osversion=7
systemctl restart mysqld.service
fi
}


function check_slave_status(){
#check the status of the slave sync
/usr/bin/mysql -u$slave_user -p$slave_password -h$slave_hostname 2>/dev/null -e "show slave status\G"|egrep "Seconds_Behind_Master|Slave_IO_State|Slave_IO_Running|Slave_SQL_Running|Master_Host"
}