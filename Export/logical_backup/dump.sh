# check the format of the input
if [ "$#" != "3" ]; then
  echo 'invalid parameters'
  echo 'usage: rds_mysql_dump.sh rds_instance username password'
  echo 'example: rds_mysql_dump.sh mysqlm-test.cw1zsttpjvrr.rds.cn-north-1.amazonaws.com.cn envision password'
  return
fi

# The vars
rds_hostname=$1
rds_user=$2
rds_password=$3
rds_port=3306
rdsdb=`echo $rds_hostname | cut -d . -f 1`


# check the mysql connectivity 
dbstat=`mysqladmin -u$rds_user -p$rds_password -h$rds_hostname -P$rds_port ping |grep alive|wc -l`
if [ $dbstat -eq 1 ]
    then 
    echo "Connect the DB $rds_hostname successfully"

# estimate the dump of time
rds_db_size=`/usr/bin/mysql -u$rds_user -p$rds_password -h$rds_hostname -N <<EOF
select  (concat(truncate(sum(data_length)/1024/1024,2),' MB') + concat(truncate(sum(index_length)/1024/1024,2),'MB')) as db_size
from information_schema.tables;
EOF`
echo "The database size is $rds_db_size M"



# get the database name list
dump_name=${rds_hostname}_$(date +%F-%H-%M).sql
db_name=`/usr/bin/mysql -u$rds_user -p$rds_password -h$rds_hostname -N  <<EOF
select TABLE_SCHEMA
from information_schema.tables
where TABLE_SCHEMA NOT IN ('PERFORMANCE_SCHEMA','INFORMATION_SCHEMA','SYS')
group by TABLE_SCHEMA;
EOF`
echo "The databases $db_name will be exported ......"
# record the timestamp
first_stamp=`date +%s`
#echo `date "+%Y_%m_%d_%H_%M_%S"`

# export the databases
mysqldump -u$rds_user -p$rds_password -h$rds_hostname \
--port=3306 \
--single-transaction \
--routines \
--triggers \
--compress  \
--databases $db_name > /mysql/mysqldump/$dump_name

#echo `date "+%Y_%m_%d_%H_%M_%S"`


#ZIP the output
echo "=====Starting Zip the dump file======="
cd /mysql/mysqldump/
tar -zcf $dump_name.tar.gz $dump_name  --remove &> /dev/null

# record the timestamp
today_stamp=`date +%s`                           
let day_stamp=($today_stamp - $first_stamp)      
let min=($day_stamp/60)                       
echo "The DB $$rds_hostname dump done!! It took $min Minutes"
    else
    echo "connect failed"
fi