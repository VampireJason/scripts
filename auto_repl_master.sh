#!/bin/bash

# define global vars

DEST_SERVER=$1
MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump
MYSQL_CREDS=/home/ncadmin/.mysql_creds
MYSQL_AND_CREDS="$MYSQL --defaults-extra-file=$MYSQL_CREDS"
MYSQLDUMP_AND_CREDS="$MYSQLDUMP --defaults-extra-file=$MYSQL_CREDS"
ERROR_LOG=/tmp/auto_repl_error.log
CHECK_LOG=/tmp/auto_repl.log
DATE=$(date +%y%m%d)

# check vars
check_file(){

	if [ -z $DEST_SERVER ]
	then echo " please enter hostname or ip "
	exit 1
	fi
	if [ ! -e $MYSQL ] || [ ! -x $MYSQL ]
	then echo " mysql binary does't exist" ; echo " mysql binary does't exist" >> $ERROR_LOG
	exit 1
	fi
	if [ ! -e $MYSQL_CREDS ]
	then echo "what is the mysql pass?"
	read MYSQL_ROOT_PASS
	echo "create mysql_creds..."
	echo "
[mysqldump]
user=root
pass=$MYSQL_ROOT_PASS
host=localhost
socket=/var/lib/mysql/mysql.sock

[mysqladmin]
user=root
pass=$MYSQL_ROOT_PASS
host=localhost
socket=/var/lib/mysql/mysql.sock

[mysql]
user=root
pass=$MYSQL_ROOT_PASS
host=localhost
socket=/var/lib/mysql//mysql.sock" > $MYSQL_CREDS
	fi
}

# check and create user

check_repl(){

REPL_USER=repl

	CHECK_USER_SQL="SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$REPL_USER')"
	RETURN_CODE=$($MYSQL_AND_CREDS -e "$CHECK_USER_SQL" | tail -1)
	if [ $RETURN_CODE == 0 ]
	then echo "user does't exist" ; echo "user does't exist" >> $CHECK_LOG
	echo "create repl user" ; echo "create repl user" >> $CHECK_LOG
	echo -e "What is repl pass?"
	read REPL_PASS
	CREATE_USER_SQL="GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO repl@'%' IDENTIFIED BY '$REPL_PASS';
			flush privileges;"
	$MYSQL_AND_CREDS -e "$CREATE_USER_SQL"
		if [ $? = 0 ]
		then echo "user created" ; echo "user created" >> $CHECK_LOG
		else echo "user create failed" ; echo "user create failed" >> $ERROR_LOG
		fi
	else echo "user exist" >> $CHECK_LOG
	fi
}

# dump all database

dump_func(){

$MYSQLDUMP_AND_CREDS --single-transaction --all-databases --master-data=2 > /tmp/$DATE.sql 2>> $ERROR_LOG
        if [ $? = 0 ]
        then echo "dump finished" ; echo "dump finished" >> $CHECK_LOG
        else echo "dump error" ; echo "dump error" >> $ERROR_LOG
        fi

}

transfer_func(){

SCP=/usr/bin/scp
SSH=/usr/bin/ssh
SSH_COMMAND="$SSH ncadmin@$DEST_SERVER"
REMOTE_FOLDER="/tmp/"
SQL_FILE=/tmp/"$DATE.sql"
MD5=/usr/bin/md5sum
LOCAL_MD5=$($MD5 $SQL_FILE | awk '{print $1}')
        echo "transfer start"
        # create remote folder
#        $SSH_COMMAND "mkdir -p $REMOTE_FOLDER"
        # transfer data
        $SCP $SQL_FILE ncadmin@$DEST_SERVER:$REMOTE_FOLDER
        # MD5 check
REMOTE_MD5=$($SSH_COMMAND "$MD5 $REMOTE_FOLDER/"$DATE.sql"" | awk '{print $1}')
        if [ "$LOCAL_MD5" != "$REMOTE_MD5" ]
        then echo "TRANSFER FAILED -- remote MD5 differs from local MD5" >&2
        else echo "TRANSFER OK -- remote and local MD5 are equal"
        fi


}



check_file
check_repl
dump_func
transfer_func
