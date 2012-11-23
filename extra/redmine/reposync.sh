#!/bin/bash

# settings
LOCKFILE="/dev/shm/redminelock"
GITREPO="/home/redmine/reposgit"
MERCURIALREPO="/home/redmine/repos"
REDMINEKEY="somekey"

# if LOCKFILE exists, exit
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    echo "already running"
    exit
fi

# make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

# Sync mercurial repos
for hg in $MERCURIALREPO/*; do
   if [ -d $hg ]; then
      cd $hg
      hg pull
   fi
done

# Sync git repos
for git in $GITREPO/*; do
   if [ -d $git ]; then
      cd $git
      git fetch --all
   fi
done

# Update redmine database
wget http://localhost:3000/sys/fetch_changesets?key=$REDMINEKEY -O /dev/null

rm -f ${LOCKFILE}
