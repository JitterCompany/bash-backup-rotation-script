#!/bin/bash

# Configuration Filename
CONF="backup.conf"

# Script Filename
SCRIPT="backup_rotation.sh"

# Do not edit below this line
CONF=${PWD}/$CONF
SCRIPT=${PWD}/$SCRIPT

DATETIME=`date '+%Y%m%d'`
umask 066
exec < $CONF

while read line
do
        if [ -n "$line" ]
        then
                if  [ ${line:0:1} != '#' ]
                then
                        TYPE=`echo $line | awk '{print $1}'`
                        HOSTNAME=`echo $line | awk '{print $2}'`
                        EMAIL=`echo $line | awk '{print $3}'`
                        COMPRESSION=`echo $line | awk '{print $4}'`
                        SQLFR=`echo $line | awk '{print $5}'`
                        HOST=`echo $line | awk '{print $6}'`
                        DATABASE=`echo $line | awk '{print $7}'`
                        USER=`echo $line | awk '{print $8}'`
                        PASSWORD=`echo $line | awk '{print $9}'`
                        FILES_FR=`echo $line | awk '{print $10}'`
                        DIRECTORY=`echo $line | awk '{print $11}'`
                        DEST_DIR=`echo $line | awk '{print $12}'`
                        RETENTION_DAY=`echo $line | awk '{print $13}'`
                        RETENTION_WEEK=`echo $line | awk '{print $14}'`
                        RETENTION_MONTH=`echo $line | awk '{print $15}'`

                        if [ ! -e "$DIRECTORY" ]; then
                                mkdir "$DIRECTORY"
                        fi

                        if  [ "$TYPE" == 'local' ]; then
                          if [ ! -e "$DEST_DIR" ]; then
                                mkdir "$DEST_DIR"
                          fi
                          $SCRIPT --hostname $HOSTNAME --email $EMAIL --compression $COMPRESSION --sql "$SQLFR" $HOST $USER $PASSWORD $DATABASE --backupdir "$FILES_FR" $DIRECTORY --targetdir "$DEST_DIR" --retention $RETENTION_DAY $RETENTION_WEEK $RETENTION_MONTH
                        fi

                        if  [ "$TYPE" == 'ftp' ]; then
                          FTP_HOST=`echo $line | awk '{print $16}'`
                          FTP_PORT=`echo $line | awk '{print $17}'`
                          FTP_USER=`echo $line | awk '{print $18}'`
                          FTP_PASSWORD=`echo $line | awk '{print $19}'`
                          $SCRIPT --hostname $HOSTNAME --email $EMAIL --compression $COMPRESSION --sql "$SQLFR" $HOST $USER $PASSWORD $DATABASE --backupdir "$FILES_FR" $DIRECTORY --ftp "$FTP_HOST" "$FTP_PORT" "$FTP_USER" "$FTP_PASSWORD" "$DEST_DIR" --retention $RETENTION_DAY $RETENTION_WEEK $RETENTION_MONTH
                        fi

                fi
        fi
done