function check_os_version() {
os_version6=`cat /etc/redhat-release|grep -o "6\."|cut -c -1`
if [ "$os_version6" == "6" ]
then
echo $os_version6
fi
os_version7=`cat /etc/redhat-release|grep -o "7\."|cut -c -1`
if [ "$os_version7" == "7" ]
then
echo $os_version7
fi
}



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

