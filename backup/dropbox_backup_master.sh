#!/bin/sh

# This script should be executed once a week (or whatever rate you have set at the full backups)
# Settings
PASSPHRASE=""
ARCHIVES="/var/archives"
DROPBOX="/home/dropbox/Dropbox/_Backups"

DATE=`date '+%Y%m%d'`

MYSQLLOCAL=$ARCHIVES"/Hostname-mysql"
MYSQLDROPBOX=$DROPBOX"/mysql/Hostname-mysql"

# Remove previous backups
find $DROPBOX/mysql/*mysql* -exec rm {} \;

# Copy todays backups
openssl des3 -salt -k $PASSPHRASE -in $MYSQLLOCAL.$DATE.master.tar.gz -out $MYSQLDROPBOX.$DATE.master.tar.gz.encrypted
