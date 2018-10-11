#The variables 


# Vars for mysql
db_user=root
db_password=root
db_port=
mycnf=/etc/my.cnf


#===============================#
#Vars for client
client_user=root

client_backup_base=/mysql
# store the backup set in the client temporary
client_backupset_temp=$client_backup_base/temp_backupset/

# store the backup set, when the backupset copied to server
client_backupset_dir=$client_backup_base/backupset/

# store the temp output
client_backup_log_temp=$client_backup_base/temp/

# store the log
client_backup_log=$client_backup_base/log/


#host_name=     ##get the host name from the host.list

#===============================#
#backup server vars
backup_server=
server_backup_base=/mysql
# store the backup set in the server
server_backupset_dir=$server_backup_base/backupset/

# store all the backup script
server_backup_script=$server_backup_base/script/


# store the temp script
server_backup_script_temp=$server_backup_base/temp_script/

# store the log
server_backup_log=$server_backup_base/log/


