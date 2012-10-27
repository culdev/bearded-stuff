#!/bin/sh

# This script should be executed once a week (or whatever rate you have set at the full backups)
# Settings
PASSPHRASE=""
ARCHIVES="/var/archives"
BASEDROPBOX="/home/dropbox/Dropbox"
DROPBOX=$BASEDROPBOX"/_Backups"

DATE=`date '+%Y%m%d'`

MYSQLLOCAL=$ARCHIVES"/Hostname-mysql"
MYSQLDROPBOX=$DROPBOX"/mysql/Hostname-mysql"

# Mount $BASEDROPBOX if necessary
# This should be disabled if $BASEDROPBOX is always mounted
if ! grep -q $BASEDROPBOX /proc/mounts ; then
    if ! mount $BASEDROPBOX ; then
        echo "Failed to mount "$BASEDROPBOX". Exiting."
        exit 1
    fi
fi

# Remove previous backups
find $DROPBOX/mysql/*mysql* -exec rm {} \;

# Copy todays backups
openssl des3 -salt -k $PASSPHRASE -in $MYSQLLOCAL.$DATE.master.tar.gz -out $MYSQLDROPBOX.$DATE.master.tar.gz.encrypted
