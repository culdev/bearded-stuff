#!/bin/sh

DATE=`date '+%Y%m%d'`

# Remove old files
find /path/to/backup/*etc* -mtime +15 -exec rm {} \;

# /etc
tar cvf /path/to/backup/etc.$DATE.tar /etc