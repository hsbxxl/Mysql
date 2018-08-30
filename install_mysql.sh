#!/bin/bash
# How to install the Mysql automatically? 
# Call all the function from main.sh.
#
#1. Call the functions and vars
source ./main.sh
source ./config.sh

#2. Check the mysql,
check_mysql_rpm

#3. create the mysql path
create_mysql_dir

#4. Claculate the innodb buffer size
calc_innodb_buffer

#5. check the OS version
check_os_version

#6. Install the mysql 
select_version_and_install_mysql 

#7. Set mysql /etc/my.cnf
if [ "$msqlversion" == "56" ]
then
    echo "Set mysql 5.6 /etc/my.cnf"
    change_mysql56_my_cnf_file

elif [ "$msqlversion" == "57" ]
then
   echo "Set mysql 5.7 /etc/my.cnf."
   change_mysql57_my_cnf_file 
fi
cat /etc/my.cnf

# disable selinux
setenforce 0

#8. Start mysql
if [ "$osversion" == "6" ]
then
    echo "Starting Mysql . . ."
    start_mysql_centos6

elif [ "$osversion" == "7" ]
then
   echo "Starting Mysql . . ."
   start_mysql_centos7 
fi


#9. Add the user and reset the user's password
if [ "$msqlversion" == "56" ]
then
    echo "Setting"
    set_password_mysql56

elif [ "$msqlversion" == "57" ]
then
   echo "Setting"
   set_password_mysql57 
fi

echo "The mysql install successfull!!"
