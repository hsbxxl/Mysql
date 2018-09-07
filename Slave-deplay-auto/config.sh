# The master vars
master_hostname=$1
master_user=$2
master_password=$3
master_port=3306
master_db=`echo $rds_hostname | cut -d . -f 1`


slave_hostname=$4
slave_user=$5
slave_password=$6
slave_port=3306

#The dump store path
temp_dir=/tmp/slave_dump_temp


#vars for replication
repluser=repluser
repluserpassword=Abcd1234!

#The path vars
base_dir=/data1
data_dir=$base_dir/mysql/data
binlog_dir=$base_dir/mysql-binlog
slowlog_dir=$base_dir/mysql-slowlog
relay_log=$base_dir/mysql/mysql-binlog

### version 5.7 my.cnf setting

# Change the below value as your env request
my57_character_set_server=utf8
my57_lower_case_table_names=1
my57_innodb_buffer_pool_size=2G
my57_max_connections=2000
#If you don't sure the below parameter, please keep the default value.
my57_transaction_isolation=READ-COMMITTED
my57_innodb_flush_log_at_trx_commit=0 
my57_innodb_log_file_size=200m 
my57_binlog_format=row 
my57_expire_logs_days=14
my57_max_binlog_size=100m
my57_binlog_cache_size=4m
my57_max_binlog_cache_size=512m
my57_slow_query_log=1
my57_sql_mode=(STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION)
my57_server_id=102
read_only=1
log_slave_updates=1 
sync_binlog=0