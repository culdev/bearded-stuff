DATE=`date '+%Y%m%d'`

# Remove old files
find /path/to/backup/*freenas* -mtime +15 -exec rm {} \;

# freenas data
tar cfz /path/to/backup/freenas.$DATE.tar.gz /data/freenas-v1.db
