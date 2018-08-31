#The path vars
base_dir=/data1
data_dir=$base_dir/mysql/data
binlog_dir=$base_dir/mysql-binlog
slowlog_dir=$base_dir/mysql-slowlog


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
my57_server_id=101


### version 5.6 my.cnf setting

# Change the below value as your env request
my56_character_set_server=utf8
my56_lower_case_table_names=1
my56_innodb_buffer_pool_size=2G
my56_max_connections=2000
#If you don't sure the below parameter, please keep the default value.
my56_transaction_isolation=READ-COMMITTED
my56_innodb_flush_log_at_trx_commit=0 
my56_innodb_log_file_size=200m 
my56_binlog_format=row 
my56_expire_logs_days=14
my56_max_binlog_size=100m
my56_binlog_cache_size=4m
my56_max_binlog_cache_size=512m
my56_slow_query_log=1
my56_server_id=101


## Mysql root and new user password
# The vars will be used in the function set_password_mysql56 && set_password_mysql57
# The format example is rootpassword='yourpassword'
rootpassword='xx$%FC!\@'
newuser='liang'
newuserpassword='Liang123!'
