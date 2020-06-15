#!/bin/bash
HOSTNAME=`hostname`
DATA=`date +%y%m%d`
DATA_TIME=`date +"%y-%m-%d %H:%M:%S"`
CURL=/bin/curl
LOGFILE=/tmp/bk.log
dd_alert() {
    DD_ALERT_URL="https://oapi.dingtalk.com/robot/send?access_token=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    HTTPHEADER='Content-Type: application/json'
    MESSAGE=$1
    $CURL $DD_ALERT_URL -H "$HTTPHEADER" -d '{"msgtype": "text","text": {"content": " '"${MESSAGE}"' " }}'
    return $?
}

mysql_bk() {
    find /data/mysql_jira_db/ -name '*.sql' -type f -mtime +90 |xargs rm -rf
    mysqldump -h 127.0.0.1 -uroot -pbVFWY9y6uFeUHLrP jira > /data/mysql_jira_db/jira_$DATA.sql
    rsync -ravzP --progress --delete --iconv=UTF-8,GBK /data/mysql_jira_db/ /tmp/ossfs/jira/mysql_jira_db/ > /dev/null 2>&1

    retval=$?
    if [ $retval -eq 0 ]
    then 
        echo "date +'%y-%m-%d %H:%M:%S' Mysql data backup success" >> $LOGFILE
    else
        echo "$DATA_TIME Mysql backup failed,Please check it" >> $LOGFILE
        dd_alert "$DATA_TIME $HOSTNAME Mysql backup failed,Please check it"
    fi
}    

jira_file_bk() {
    mkdir -p /tmp/ossfs/jira/$DATA
    rsync -ravzP --progress --iconv=UTF-8,GBK /data/atlassian/application-data/jira/ /tmp/ossfs/jira/$DATA/
    retval=$?
    if [ $retval -eq 0 ]
    then 
        echo "$DATA_TIME Jira data backup success " >> $LOGFILE
    else
        echo "$DATA_TIME Jira data backup failed,Please check it" >> $LOGFILE
        dd_alert "$DATA_TIME $HOSTNAME Jira data backup failed,Please check it"
    fi
   
}

echo_test() {
    echo "message test"
}

mysql_bk
jira_file_bk
