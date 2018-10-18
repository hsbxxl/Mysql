function dump_mysql() {
cat mysql_dump_list | while read line
do
    echo $line
    host_name=$line
    echo_name=`echo $host_name | awk '{print $1}'`
    echo "=======================The database  $echo_name dumping ====================================="
    sh dump.sh $host_name 
    echo "=======================The database  $echo_name finished ====================================="
    sleep 5
done
}
dump_mysql