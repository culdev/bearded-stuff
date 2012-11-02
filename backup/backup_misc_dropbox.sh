#!/bin/sh

# This script should executed every day except when the master backup is executed
# Settings
PASSPHRASE=""
BASEARCHIVES="/var/archives"
ARCHIVES=$BASEARCHIVES"/Hostname"
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

# Mount $BASEARCHIVES if necessary
# This should be disabled if $BASEARCHIVES is always mounted
if ! grep -q $BASEARCHIVES /proc/mounts ; then
    if ! mount $BASEARCHIVES ; then
        echo "Failed to mount "$BASEARCHIVES". Exiting."
        exit 1
    fi
fi

# Copy todays backups
openssl des3 -salt -k $PASSPHRASE -in $MYSQLLOCAL.$DATE.tar.gz -out $MYSQLDROPBOX.$DATE.tar.gz.encrypted
openssl des3 -salt -k $PASSPHRASE -in $MYSQLLOCAL.incremental.bin -out $MYSQLDROPBOX.incremental.bin.encrypted
