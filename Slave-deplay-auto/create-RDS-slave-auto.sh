# check the format of the input
if [ "$#" != "6" ]; then
  echo 'invalid parameters'
  echo 'usage: rds_mysql_dump.sh rds_instance username password slave_host username password'
  echo 'example: rds_mysql_dump.sh mysqlm-test.cw1zsttpjvrr.rds.cn-north-1.amazonaws.com.cn envision password localhost root password'
  return
fi

# The master vars
rds_hostname=$1
rds_user=$2
rds_password=$3
rds_port=3306
rdsdb=`echo $rds_hostname | cut -d . -f 1`

slave_hostname=$4
slave_user=$5
slave_password=$6
slave_port=3306

#vars for replication
repluser=repluser
repluserpassword=Abcd1234!

######### Execute on master #########
# check the mysql connectivity 
dbstat=`mysqladmin -u$rds_user -p$rds_password -h$rds_hostname -P$rds_port ping |grep alive|wc -l`
if [ $dbstat -eq 1 ]
    then 
    echo "Connect the RDS DB successfully"
#create replication user
rds_db_size=`/usr/bin/mysql -u$rds_user -p$rds_password -h$rds_hostname -N --connect-expired-password <<EOF
grant replication slave,replication client on *.* to $repluser@'%' identified by '$repluserpassword';
EOF`
 
echo master_position
# master_position
master_position=`/usr/bin/mysql -u$rds_user -p$rds_password -h$rds_hostname <<EOF
show  master status\G
EOF`
echo  "$master_position" > /tmp/mysqlmaster.id
binlog_number=`echo  "$master_position" |awk -F"File: " '{ print $2}'`
position=`echo  "$master_position"|awk -F"Position:" '{ print $2}'`

echo $binlog_number
echo $position

binlog_number2=`echo $binlog_number| awk '{gsub(/ /,"")}1'`
position2=`echo $position | awk '{gsub(/ /,"")}1'`


# estimate the dump of time
rds_db_size=`/usr/bin/mysql -u$rds_user -p$rds_password -h$rds_hostname -N --connect-expired-password <<EOF
select  (concat(truncate(sum(data_length)/1024/1024,2),' MB') + concat(truncate(sum(index_length)/1024/1024,2),'MB')) as db_size
from information_schema.tables;
EOF`
echo "The database size is $rds_db_size M"

rds_db_size2=`echo ${rds_db_size%.*}`
echo $rds_db_size2

if [ $rds_db_size2 -le "5000" ]
   then echo "The export will consume 10 minutes .... "
elif [ $rds_db_size2 -le "50000" ]
then
echo "The export will consume 20 minutes .... "

elif [ $rds_db_size2 -le "100000" ]
then
echo "The export will consume 40 minutes .... "

else
echo "The export will consume 60 minutes .... "
fi

# get the database name list
db_name=`/usr/bin/mysql -u$rds_user -p$rds_password -h$rds_hostname -N --connect-expired-password <<EOF
select TABLE_SCHEMA
from information_schema.tables
where TABLE_SCHEMA NOT IN ('MYSQL','PERFORMANCE_SCHEMA','INFORMATION_SCHEMA','SYS')
group by TABLE_SCHEMA;
EOF`
echo "The databases $db_name will be exported ......"

first_stamp=`date +%s`
echo `date "+%Y_%m_%d_%H_%M_%S"`
data_stamp=`date "+%Y%m%d%H%M"`
# export the databases
mysqldump -u$rds_user -p$rds_password -h$rds_hostname \
--port=3306 \
--single-transaction \
--routines \
--triggers \
--compress  \
--databases $db_name > /tmp/mysqldump_$rdsdb_$data_stamp.sql
echo `date "+%Y_%m_%d_%H_%M_%S"`

today_stamp=`date +%s`                           
let day_stamp=($today_stamp - $first_stamp)      
let min=($day_stamp/60)                       

echo "RDS DB $db_name dump done!! It took $min Minutes"

    else
    echo "connect failed"
fi


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
/usr/bin/mysql -u$slave_user -p$slave_password -h$slave_hostname 2>/dev/null < /tmp/mysqldump_$rdsdb_$data_stamp.sql

# set the slave

/usr/bin/mysql -u$slave_user -p$slave_password -h$slave_hostname 2>/dev/null <<EOF
CHANGE MASTER TO
MASTER_HOST='$rds_hostname',
MASTER_USER='$repluser',
MASTER_PASSWORD='$repluserpassword',
MASTER_LOG_FILE='$binlog_number2',
MASTER_LOG_POS=$position2;
   #<<<<<<需要先改slave的my.cnf replay_log位置 server_id=102 replicate-wild-ignore-table=mysql.*
   重启mysql
start slave;
EOF

echo "/usr/bin/mysql -u$slave_user -p$slave_password -h$slave_hostname 2>/dev/null <<EOF
CHANGE MASTER TO
MASTER_HOST='$rds_hostname',
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
