#!/bin/sh

# This script should executed every day except when the master backup is executed
# Settings
PASSPHRASE=""
ARCHIVES="/var/archives"
DROPBOX="/home/dropbox/Dropbox/_Backups"

DATE=`date '+%Y%m%d'`

MYSQLLOCAL=$ARCHIVES"/Hostname-mysql"
MYSQLDROPBOX=$DROPBOX"/mysql/Hostname-mysql"

# Copy todays backups
openssl des3 -salt -k $PASSPHRASE -in $MYSQLLOCAL.$DATE.tar.gz -out $MYSQLDROPBOX.$DATE.tar.gz.encrypted
openssl des3 -salt -k $PASSPHRASE -in $MYSQLLOCAL.incremental.bin -out $MYSQLDROPBOX.incremental.bin.encrypted
