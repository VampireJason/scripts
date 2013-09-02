#!/bin/bash

DATE=$(date +%y%m%d)
SQL_FILE=/tmp/"$DATE.sql"
MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump
MYSQL_CREDS=/home/ncadmin/.mysql_creds
MYSQL_AND_CREDS="$MYSQL --defaults-extra-file=$MYSQL_CREDS"
MYSQLDUMP_AND_CREDS="$MYSQLDUMP --defaults-extra-file=$MYSQL_CREDS"
ERROR_LOG=/tmp/auto_repl_error.log
CHECK_LOG=/tmp/auto_repl.log

check_func(){

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

restore_func(){

$MYSQL_AND_CREDS < $SQL_FILE
        if [ $? = 0 ]
        then echo "restore finished" ; echo "restore finished" >> $CHECK_LOG
        else echo "restore error" ; echo "restore error" >> $ERROR_LOG
        fi

}

repl_func(){

MYSQL_BINLOG=$(grep "CHANGE MASTER" $SQL_FILE | awk -F "=" '{print $2}' | awk -F "'" '{print $2}')
MYSQL_POS=$(grep "CHANGE MASTER" $SQL_FILE | awk -F "=" '{print $3}' | awk -F ";" '{print $1}')
	echo -e "What is Master ip?"
        read MASTER_IP
        echo -e "What is repl pass?"
        read REPL_PASS
	REPL_SQL="CHANGE MASTER TO MASTER_HOST='$MASTER_IP', MASTER_USER='repl', MASTER_PASSWORD='$REPL_PASS',MASTER_LOG_FILE='$MYSQL_BINLOG',MASTER_LOG_POS=$MYSQL_POS;
		start slave;"
        $MYSQL_AND_CREDS -e "$REPL_SQL" 2>> $ERROR_LOG
                if [ $? = 0 ]
                then echo "slave created" ; echo "slave created" >> $CHECK_LOG
                else echo "slave create failed" ; echo "slave create failed" >> $ERROR_LOG
                fi
}


check_func
restore_func
repl_func
