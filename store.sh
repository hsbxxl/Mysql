
function create_dir() {
  if [ "$#" != "3" ]; then
    echo 'invalid parameters'
    echo 'usage: create_mysql_dir username dir permission'
    echo 'example: create_mysql_dir mysql /user/mysql 755'
    return
  fi
  username=$1
  dir=$2
  permission=$3
  mkdir -p $dir;chown -R $username:$username $dir; chmod $permission $dir;ls -d $dir
  }

  
  
function kill_current_session_script(){
   install_PID=$$
   kill -9 $install_PID
}


function exit_commond(){
echo $?
if [[ $? -eq 0 ]];then
exit 1
fi
}