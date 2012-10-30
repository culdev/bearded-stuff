#!/bin/sh

# Settings
BASETARGET="/path/to/backup"
TARGETDIR=$BASETARGET"/Hostname"

DATE=`date '+%Y%m%d'`

# Mount $BASETARGET if necessary
# This should be disabled if $BASETARGET is always mounted
if ! grep -q $BASETARGET /proc/mounts ; then
    if ! mount $BASETARGET ; then
        echo "Failed to mount "$BASETARGET". Exiting."
        exit 1
    fi
fi

# Remove old files
find $TARGETDIR/*etc* -mtime +15 -exec rm {} \;

# /etc
tar cvfz $TARGETDIR/etc.$DATE.tar.gz -C / etc
